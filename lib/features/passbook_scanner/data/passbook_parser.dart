import '../domain/models/bank_details.dart';

/// Parses raw OCR text and extracts bank passbook details.
///
/// The parser performs four extraction steps:
/// 1. IFSC code extraction and bank name derivation.
/// 2. Account number extraction with label-first strategy.
/// 3. Account holder name heuristic extraction.
/// 4. Account number masking.
class PassbookParser {
  PassbookParser._();

  // ── Pre-compiled regular expressions ────────────────────────────

  /// IFSC code pattern: 4 uppercase letters + "0" + 6 alphanumeric chars.
  /// (Tolerates 'O' instead of '0' for the fifth character due to OCR)
  static final RegExp _ifscPattern = RegExp(r'\b[A-Z]{4}[0O][A-Z0-9]{6}\b', caseSensitive: false);

  /// Label-based account number keywords.
  static final RegExp _accountLabelPattern = RegExp(
    r'(?:^|\W)(?:A/C|A\\C|A\s+C|AC\b|ACT\b|ACC(?:T|NT)?\b|AC?COUNT)\.?\s*(?:NO|NUMBER|NUM|N0)?\.?(?:\s|[:\-\.]|$)[\s:\-\.]*(.*)',
    caseSensitive: false,
  );

  /// Keywords that indicate a number on the same/next line is NOT an account number
  static final RegExp _ignoreLabelsForAccount = RegExp(
    r'\b(?:CIF|PAN|AADHAAR|MOBILE|PHONE|CUSTOMER\s*ID|CUST\s*ID|CRN|UAN|NAME|BRANCH|IFSC)\b',
    caseSensitive: false,
  );

  /// Digit sequences of length 9–18, using lookaround to prevent partial matches
  /// on massive barcode/OCR artifacts (e.g., won't extract 18 digits from a 22 digit string).
  static final RegExp _digitSequence = RegExp(r'(?<!\d)\d{9,18}(?!\d)');

  /// 10-digit phone number starting with 6–9 (Indian mobile).
  static final RegExp _phonePattern = RegExp(r'^[6-9]\d{9}$');

  /// Lines that are entirely upper-case letters and spaces.
  static final RegExp _allCapsLine = RegExp(r'^[A-Z][A-Z ]{2,}$');

  /// Name label keywords.
  static final RegExp _nameLabelPattern = RegExp(
    r'(?:^|\s)(?:NAME|ACCOUNT\s*HOLDER|CUSTOMER\s*NAME|HOLDER\s*NAME)\s*[:\-]?\s*(.*)',
    caseSensitive: false,
  );

  /// Keywords to exclude from name candidates.
  static const List<String> _nameExcludeKeywords = [
    'BRANCH', 'BANK', 'PASSBOOK', 'SAVINGS', 'CURRENT',
    'ACCOUNT', 'STATEMENT', 'DATE', 'BALANCE', 'INDIA',
    'LIMITED', 'NATIONAL', 'STATE', 'RESERVE', 'BRANCH',
    'MOBILE', 'PHONE', 'CIF', 'PAN', 'AADHAAR', 'CODE', 'NUMBER',
    'ADDRESS', 'DETAILS', 'IFSC', 'CUSTOMER', 'OPENED',
    'DISTRICT', 'DIST', 'PIN', 'PINCODE', 'TALUKA', 'TEHSIL',
    'NAGAR', 'ROAD', 'STREET', 'MARG', 'VILLAGE', 'POST', 'PO',
    'CITY', 'STATE', 'COMPLEX', 'BUILDING', 'FLOOR', 'TOWER',
    'OPP', 'NEAR', 'BEHIND', 'BESIDE', 'LTD', 'PVT',
    'OCCUPATION', 'PROFESSION', 'NOMINEE', 'FATHER', 'MOTHER',
    'HUSBAND', 'WIFE', 'SPOUSE', 'DOB', 'AGE', 'GENDER', 'SEX',
    'EMAIL', 'UID', 'CUSTID', 'MALE', 'FEMALE', 'SINGLE', 'JOINT',
    'MINOR', 'MAJOR', 'INDIAN', 'SIGNATURE', 'AUTHORISED', 'SIGNATORY',
    'VALID', 'MANAGER', 'ASST', 'OFFICER', 'MICR', 'ROUTING',
    'AMOUNT', 'PLEASE', 'DRAW', 'LINE', 'SPACE', 'LEFT', 'CHEQUE',
    'FORMS', 'SHOULD', 'BE', 'USED', 'ONLY', 'BOOK', 'ATM', 'CARD',
    'DEBIT', 'CREDIT', 'PASSWORD', 'NEVER', 'SHARE', 'WARNING',
    'CAUTION', 'NOTE', 'IMPORTANT', 'USE', 'KEEP', 'SAFE', 'PROVIDED',
    'ISSUED', 'CASH', 'WITHDRAWAL', 'DEPOSIT', 'TRANSACTION', 'ONLINE',
    'INTERNET', 'BANKING', 'TERMS', 'CONDITIONS', 'SUBJECT', 'TOWARDS',
    'NAME', 'HOLDER', 'HOLDERS', 'APPLICANT', 'APPLICANTS', 'USER',
    'BENEFICIARY', 'PAYEE', 'DRAWER', 'CUST', 'AUTH',
  ];

  /// Maps known IFSC prefixes (first 4 letters) to bank names.
  static const Map<String, String> _ifscBankMap = {
    'SBIN': 'State Bank of India',
    'HDFC': 'HDFC Bank',
    'ICIC': 'ICICI Bank',
    'PUNB': 'Punjab National Bank',
    'BARB': 'Bank of Baroda',
    'UBIN': 'Union Bank of India',
    'KKBK': 'Kotak Mahindra Bank',
    'AXIS': 'Axis Bank',
    'UTIB': 'Axis Bank',
    'IOBA': 'Indian Overseas Bank',
    'CNRB': 'Canara Bank',
    'BKID': 'Bank of India',
    'IDIB': 'Indian Bank',
    'CBIN': 'Central Bank of India',
    'YESB': 'Yes Bank',
    'INDB': 'IndusInd Bank',
    'FDRL': 'Federal Bank',
    'MAHB': 'Bank of Maharashtra',
    'UCBA': 'UCO Bank',
    'PSIB': 'Punjab & Sind Bank',
  };

  // ── Public API ──────────────────────────────────────────────────

  /// Parses [rawText] and returns a [BankDetails] instance.
  ///
  /// Returns a [BankDetails] with nullable fields set to `null`
  /// when parsing fails for a particular field.
  static BankDetails parsePassbook(String rawText) {
    print('\n[PassbookParser] Starting extraction...');
    final ifsc = _extractIfsc(rawText);
    print('[PassbookParser] Extracted IFSC: $ifsc');
    
    final bankName = _deriveBankName(ifsc);
    print('[PassbookParser] Derived Bank Name: $bankName');
    
    final accountNumber = _extractAccountNumber(rawText, ifsc);
    print('[PassbookParser] Extracted Account: $accountNumber');
    
    final name = _extractName(rawText);
    print('[PassbookParser] Extracted Name: $name');
    
    final masked =
        accountNumber != null ? _maskAccountNumber(accountNumber) : null;

    return BankDetails(
      accountHolderName: name,
      accountNumber: accountNumber,
      maskedAccount: masked,
      ifscCode: ifsc,
      bankName: bankName,
    );
  }

  // ── Step 2 – IFSC extraction ────────────────────────────────────

  /// Finds the first valid IFSC code in [text].
  static String? _extractIfsc(String text) {
    // 1. Try matching on the original text with word boundaries
    final matches = _ifscPattern.allMatches(text);
    for (final match in matches) {
      final code = _normalizeIfsc(match.group(0)!);
      if (_isValidIfsc(code)) return code;
    }
    
    // 2. Try looking for the "IFSC" label specifically
    final RegExp labelPattern = RegExp(r'IFSC\s*[:\-]?\s*([A-Z0-9\s]{11,15})', caseSensitive: false);
    final labelMatch = labelPattern.firstMatch(text);
    if (labelMatch != null) {
        final cleanLabelled = labelMatch.group(1)!.replaceAll(RegExp(r'[\s\-]'), '');
        // Without word boundaries for the cleaned string
        final RegExp loosePattern = RegExp(r'^[A-Z]{4}[0O][A-Z0-9]{6}$', caseSensitive: false);
        if (loosePattern.hasMatch(cleanLabelled)) {
            final code = _normalizeIfsc(cleanLabelled);
            if (_isValidIfsc(code)) return code;
        }
    }

    // 3. Fallback: strip spaces but enforce strict validation
    final cleanText = text.replaceAll(RegExp(r'[\s\-]'), '');
    final RegExp loosePattern = RegExp(r'[A-Z]{4}[0O][A-Z0-9]{6}', caseSensitive: false);
    final fallbackMatches = loosePattern.allMatches(cleanText);
    for (final match in fallbackMatches) {
        final code = _normalizeIfsc(match.group(0)!);
        // Only accept fallback if the prefix is in our known bank map OR the last 6 chars have multiple digits
        if (_ifscBankMap.containsKey(code.substring(0, 4)) || code.substring(5).replaceAll(RegExp(r'[^\d]'), '').length >= 3) {
            return code;
        }
    }

    return null;
  }

  /// Helper to validate IFSC (must have digits in the last 6 chars to avoid plain words)
  static bool _isValidIfsc(String code) {
      if (code.length != 11) return false;
      final last6 = code.substring(5);
      // Ensure there is at least one digit in the last 6 characters to avoid English words
      return last6.contains(RegExp(r'\d'));
  }

  /// Ensures the 5th character is '0', returns uppercase, and fixes common OCR errors
  static String _normalizeIfsc(String raw) {
    var upper = raw.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
    if (upper.length >= 5 && upper[4] == 'O') {
      upper = upper.replaceRange(4, 5, '0');
    }
    // Auto-correct common OCR misreads for popular bank prefixes
    if (upper.startsWith('EBIN') || upper.startsWith('S8IN') || upper.startsWith('5BIN')) {
        upper = 'SBIN' + upper.substring(4);
    } else if (upper.startsWith('HDFO')) {
        upper = 'HDFC' + upper.substring(4);
    } else if (upper.startsWith('IC1C')) {
        upper = 'ICIC' + upper.substring(4);
    }
    return upper;
  }

  /// Derives the bank name from the first 4 characters of [ifsc].
  static String? _deriveBankName(String? ifsc) {
    if (ifsc == null || ifsc.length < 4) return null;
    final prefix = ifsc.substring(0, 4).toUpperCase();
    return _ifscBankMap[prefix];
  }

  // ── Step 3 – Account number extraction ──────────────────────────

  /// Extracts the account number using a label-first strategy.
  static String? _extractAccountNumber(String text, String? ifsc) {
    final labelled = _extractLabelledAccount(text, ifsc);
    if (labelled != null) return labelled;
    return _extractUnlabelledAccount(text, ifsc);
  }

  /// Searches for account number labels and extracts the following number.
  static String? _extractLabelledAccount(String text, String? ifsc) {
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      final match = _accountLabelPattern.firstMatch(line);
      if (match != null) {
        // Labels shouldn't be full paragraphs/sentences. 
        if (line.length > 60) continue;

        // Skip false-positive section headers and unrelated sentences anywhere in the line
        if (RegExp(r'\b(?:OPENED|DETAILS|TYPE|HOLDER|STATUS|BALANCE|STATEMENT|SUMMARY|DATE|INFORMATION|ABOUT|VALID|SUBJECT|TOWARDS)\b', caseSensitive: false).hasMatch(line)) {
            // But if the matched label explicitly includes "NO" or "NUMBER", it's probably legitimate, so we don't skip it.
            if (!RegExp(r'\b(?:NO|NUMBER|NUM|N0)\b', caseSensitive: false).hasMatch(match.group(0)!)) {
                continue;
            }
        }

        print('[PassbookParser] Found Account Label on line: "$line"');
        // Strip spaces to allow finding space-separated accounts (e.g. "1234 5678 9012")
        final afterLabelRaw = match.group(1)!.trim();
        final afterLabel = afterLabelRaw.replaceAll(RegExp(r'[\s\-]'), '');
        final sameLineDigits = _digitSequence.firstMatch(afterLabel);
        if (sameLineDigits != null) {
            final digits = sameLineDigits.group(0)!;
            if (ifsc != null && ifsc.startsWith('SBIN') && digits.length == 11 && RegExp(r'^[789]').hasMatch(digits)) {
                print('[PassbookParser] Skipping same-line $digits as it looks like an SBI CIF number.');
            } else {
                print('[PassbookParser] Extracted account from same line: $digits');
                return digits;
            }
        }

        List<String> lookaheadCandidates = [];
        // Try the next non-empty lines (look ahead up to 6 lines to bypass interleaved text/labels).
        for (int j = i + 1; j < lines.length && j <= i + 6; j++) {
          final nextLineOrig = lines[j];
          if (nextLineOrig.trim().isEmpty) continue;

          // If this line explicitly belongs to another field (like CIF), completely SKIP the line
          if (_ignoreLabelsForAccount.hasMatch(nextLineOrig)) continue;

          final nextLine = nextLineOrig.replaceAll(RegExp(r'[\s\-]'), '');
          final nextDigits = _digitSequence.firstMatch(nextLine);
          if (nextDigits != null) {
              final digits = nextDigits.group(0)!;
              if (ifsc != null && ifsc.startsWith('SBIN') && digits.length == 11 && RegExp(r'^[789]').hasMatch(digits)) {
                  print('[PassbookParser] Skipping next-line $digits as it looks like an SBI CIF number.');
                  continue;
              }
              lookaheadCandidates.add(digits);
          }
        }

        if (lookaheadCandidates.isNotEmpty) {
            // Sort by length descending, so longest account numbers (usually the true one vs CIF) win.
            lookaheadCandidates.sort((a, b) {
                int lenCmp = b.length.compareTo(a.length);
                if (lenCmp != 0) return lenCmp;
                // If lengths are equal, prefer numbers starting with 1-6 over 7-9 (common for CIFs)
                bool aIsAcct = RegExp(r'^[1-6]').hasMatch(a);
                bool bIsAcct = RegExp(r'^[1-6]').hasMatch(b);
                if (aIsAcct && !bIsAcct) return -1;
                if (!aIsAcct && bIsAcct) return 1;
                return 0;
            });
            print('[PassbookParser] Extracted account from lookahead: ${lookaheadCandidates.first}');
            return lookaheadCandidates.first;
        }
      }
    }

    print('[PassbookParser] Label extraction failed. Falling back to unlabelled.');
    return null;
  }

  /// Finds digit sequences that are not phone numbers or IFSC-adjacent.
  static String? _extractUnlabelledAccount(String text, String? ifsc) {
    final candidates = <String>[];
    
    // Strip spaces per line before extracting digits to handle "1234 5678 9012"
    for (final line in text.split('\n')) {
        // Ignore lines that clearly belong to other IDs
        if (_ignoreLabelsForAccount.hasMatch(line)) continue;

        final cleanLine = line.replaceAll(RegExp(r'[\s\-]'), '');
        final allDigits = _digitSequence.allMatches(cleanLine).toList();

        for (final match in allDigits) {
          final seq = match.group(0)!;
          // Skip if it looks like a phone number.
          if (seq.length == 10 && _phonePattern.hasMatch(seq)) continue;
          // Skip if it is part of the IFSC code.
          if (ifsc != null && ifsc.contains(seq)) continue;
          // Skip SBI CIF numbers
          if (ifsc != null && ifsc.startsWith('SBIN') && seq.length == 11 && RegExp(r'^[789]').hasMatch(seq)) continue;
          
          candidates.add(seq);
        }
    }

    if (candidates.isEmpty) {
        print('[PassbookParser] Unlabelled extraction found 0 candidates.');
        return null;
    }
    
    // Prefer the longest candidate.
    candidates.sort((a, b) => b.length.compareTo(a.length));
    print('[PassbookParser] Unlabelled candidates sorted by length: $candidates');
    return candidates.first;
  }

  // ── Step 4 – Name extraction ────────────────────────────────────

  /// Extracts the account holder name using label-first + heuristic.
  static String? _extractName(String text) {
    final lines = text.split('\n');
    final RegExp relationPattern = RegExp(r'\b[WSDC]/O\b', caseSensitive: false);

    // Strategy 1: label-based.
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Ignore "Wife of", "Son of", "Daughter of" lines
      if (relationPattern.hasMatch(line)) continue;

      final match = _nameLabelPattern.firstMatch(line);
      if (match != null) {
        // If the label line explicitly mentions BRANCH or BANK, it is the branch's name/address header, NOT the customer!
        if (RegExp(r'\b(?:BRANCH|BANK)\b', caseSensitive: false).hasMatch(line)) {
            continue;
        }

        // Use group(1) to get everything AFTER the label, ignoring prefixes
        final afterLabel = match.group(1)!.trim();
        // Remove non-letters to clean up random symbols
        final cleaned = afterLabel.replaceAll(RegExp(r'[^A-Za-z ]'), '').trim();
        
        if (_isValidName(cleaned)) {
          return _cleanNamePrefixes(cleaned).toUpperCase();
        }

        // Try the next line.
        for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j].trim();
          if (nextLine.isEmpty || relationPattern.hasMatch(nextLine)) continue;
          
          final cleanedNext = nextLine.replaceAll(RegExp(r'[^A-Za-z ]'), '').trim();
          if (_isValidName(cleanedNext)) {
            return _cleanNamePrefixes(cleanedNext).toUpperCase();
          }
          break;
        }
      }
    }

    // Strategy 2: Honorific prefix heuristic.
    // Extremely reliable: If a line starts with MR., MRS., MS., SHRI., etc., it's almost certainly the name!
    final RegExp honorificPattern = RegExp(r'^(?:MR\.|MR|MRS\.|MRS|MS\.|MS|MISS|SHRI|SMT\.|SMT|KUMARI)\s+([A-Za-z\s]+)$', caseSensitive: false);
    for (final line in lines) {
      final match = honorificPattern.firstMatch(line.trim());
      if (match != null) {
          final possibleName = match.group(1)!.trim();
          if (_isValidName(possibleName)) {
              return _cleanNamePrefixes(line.trim()).toUpperCase();
          }
      }
    }

    // Strategy 3: ALL-CAPS heuristic.
    for (final line in lines) {
      final trimmed = line.trim();
      if (!_allCapsLine.hasMatch(trimmed)) continue;
      if (relationPattern.hasMatch(trimmed)) continue;

      final words = trimmed.split(RegExp(r'\s+'));
      if (words.length < 1 || words.length > 5) continue;

      if (!_isValidName(trimmed)) continue;

      return trimmed;
    }

    return null;
  }

  /// Helper to validate if a string looks like a real name and doesn't contain excluded keywords
  static bool _isValidName(String name) {
    if (name.isEmpty || name.length <= 2) return false;
    final words = name.split(RegExp(r'\s+'));
    if (words.length > 5) return false;
    
    final hasExcluded = words.any((w) {
      final cleanWord = w.replaceAll(RegExp(r'[^A-Za-z]'), '').toUpperCase();
      if (cleanWord.isEmpty) return false;
      return _nameExcludeKeywords.contains(cleanWord);
    });
    return !hasExcluded;
  }

  /// Removes common honorific prefixes from the extracted name
  static String _cleanNamePrefixes(String name) {
      final RegExp prefixPattern = RegExp(r'^(MR|MRS|MS|SHRI|SMT|DR|KUMARI)\s+', caseSensitive: false);
      return name.replaceFirst(prefixPattern, '').trim();
  }

  // ── Step 5 – Masking ────────────────────────────────────────────

  /// Masks the account number showing only the last 4 digits.
  static String _maskAccountNumber(String number) {
    if (number.length <= 4) return number;
    final visible = number.substring(number.length - 4);
    final masked = 'X' * (number.length - 4);
    return '$masked$visible';
  }
}
