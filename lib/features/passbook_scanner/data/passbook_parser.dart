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
        final afterLabelRaw = match.group(1)!.trim();
        
        // Skip false-positive section headers and unrelated fields
        if (RegExp(r'^(?:OPENED|DETAILS|TYPE|HOLDER|STATUS|BALANCE|STATEMENT|SUMMARY)\b', caseSensitive: false).hasMatch(afterLabelRaw)) {
            continue;
        }

        print('[PassbookParser] Found Account Label on line: "$line"');
        // Strip spaces to allow finding space-separated accounts (e.g. "1234 5678 9012")
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

        // Try the next non-empty lines (look ahead up to 10 lines to bypass interleaved text/labels).
        for (int j = i + 1; j < lines.length && j <= i + 10; j++) {
          final nextLineOrig = lines[j];
          if (nextLineOrig.trim().isEmpty) continue;

          // If this line explicitly belongs to another field (like CIF), completely SKIP the line
          // so we don't extract its number, but CONTINUE looking ahead for the Account Number!
          if (_ignoreLabelsForAccount.hasMatch(nextLineOrig)) continue;

          final nextLine = nextLineOrig.replaceAll(RegExp(r'[\s\-]'), '');
          final nextDigits = _digitSequence.firstMatch(nextLine);
          if (nextDigits != null) {
              final digits = nextDigits.group(0)!;
              if (ifsc != null && ifsc.startsWith('SBIN') && digits.length == 11 && RegExp(r'^[789]').hasMatch(digits)) {
                  print('[PassbookParser] Skipping next-line $digits as it looks like an SBI CIF number.');
                  continue;
              }
              print('[PassbookParser] Extracted account from next line: $digits');
              return digits;
          }
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
        // Use group(1) to get everything AFTER the label, ignoring prefixes
        final afterLabel = match.group(1)!.trim();
        // Remove non-letters to clean up random symbols
        final cleaned = afterLabel.replaceAll(RegExp(r'[^A-Za-z ]'), '').trim();
        
        if (cleaned.isNotEmpty && cleaned.length > 2) {
          return _cleanNamePrefixes(cleaned).toUpperCase();
        }

        // Try the next line.
        for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
          final nextLine = lines[j].trim();
          if (nextLine.isEmpty || relationPattern.hasMatch(nextLine)) continue;
          
          final cleanedNext = nextLine.replaceAll(RegExp(r'[^A-Za-z ]'), '').trim();
          if (cleanedNext.isNotEmpty && cleanedNext.length > 2) {
            return _cleanNamePrefixes(cleanedNext).toUpperCase();
          }
          break;
        }
      }
    }

    // Strategy 2: ALL-CAPS heuristic.
    for (final line in lines) {
      final trimmed = line.trim();
      if (!_allCapsLine.hasMatch(trimmed)) continue;
      if (relationPattern.hasMatch(trimmed)) continue;

      final words = trimmed.split(RegExp(r'\s+'));
      if (words.length < 2 || words.length > 4) continue;

      final hasExcluded = words.any((w) {
        final cleanWord = w.replaceAll(RegExp(r'[^A-Za-z]'), '').toUpperCase();
        return _nameExcludeKeywords.contains(cleanWord);
      });
      if (hasExcluded) continue;

      return trimmed;
    }

    return null;
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
