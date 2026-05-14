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
  static final RegExp _ifscPattern = RegExp(r'[A-Z]{4}0[A-Z0-9]{6}');

  /// Label-based account number keywords.
  static final RegExp _accountLabelPattern = RegExp(
    r'(?:Account\s*(?:No|Number)|A\s*/\s*[Cc]\s*(?:No)?|Acc\s*No)',
    caseSensitive: false,
  );

  /// Digit sequences of length 9–18.
  static final RegExp _digitSequence = RegExp(r'\d{9,18}');

  /// 10-digit phone number starting with 6–9 (Indian mobile).
  static final RegExp _phonePattern = RegExp(r'^[6-9]\d{9}$');

  /// Lines that are entirely upper-case letters and spaces.
  static final RegExp _allCapsLine = RegExp(r'^[A-Z][A-Z ]{2,}$');

  /// Name label keywords.
  static final RegExp _nameLabelPattern = RegExp(
    r'(?:^|\s)(?:Name|Account\s*Holder|Customer\s*Name|Holder\s*Name)\s*[:\-]?\s*',
    caseSensitive: false,
  );

  /// Keywords to exclude from name candidates.
  static const List<String> _nameExcludeKeywords = [
    'BRANCH', 'BANK', 'PASSBOOK', 'SAVINGS', 'CURRENT',
    'ACCOUNT', 'STATEMENT', 'DATE', 'BALANCE', 'INDIA',
    'LIMITED', 'NATIONAL', 'STATE', 'RESERVE', 'BRANCH',
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
    final ifsc = _extractIfsc(rawText);
    final bankName = _deriveBankName(ifsc);
    final accountNumber = _extractAccountNumber(rawText, ifsc);
    final name = _extractName(rawText);
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
    final matches = _ifscPattern.allMatches(text);
    if (matches.isEmpty) return null;
    return matches.first.group(0);
  }

  /// Derives the bank name from the first 4 characters of [ifsc].
  static String? _deriveBankName(String? ifsc) {
    if (ifsc == null || ifsc.length < 4) return null;
    final prefix = ifsc.substring(0, 4).toUpperCase();
    return _ifscBankMap[prefix];
  }

  // ── Step 3 – Account number extraction ──────────────────────────

  /// Extracts the account number using a label-first strategy.
  ///
  /// 1. Looks for labelled account numbers first.
  /// 2. Falls back to unlabelled digit sequences.
  /// 3. Excludes phone numbers and IFSC-adjacent numbers.
  static String? _extractAccountNumber(String text, String? ifsc) {
    // Strategy 1: label-based extraction.
    final labelled = _extractLabelledAccount(text);
    if (labelled != null) return labelled;

    // Strategy 2: unlabelled digit sequences.
    return _extractUnlabelledAccount(text, ifsc);
  }

  /// Searches for account number labels and extracts the following number.
  static String? _extractLabelledAccount(String text) {
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!_accountLabelPattern.hasMatch(line)) continue;

      // Try to find digits on the same line after the label.
      final afterLabel =
          line.replaceFirst(_accountLabelPattern, '').trim();
      final sameLineDigits = _digitSequence.firstMatch(afterLabel);
      if (sameLineDigits != null) return sameLineDigits.group(0);

      // Try the next non-empty line.
      for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
        final nextLine = lines[j].trim();
        if (nextLine.isEmpty) continue;
        final nextDigits = _digitSequence.firstMatch(nextLine);
        if (nextDigits != null) return nextDigits.group(0);
      }
    }

    return null;
  }

  /// Finds digit sequences that are not phone numbers or IFSC-adjacent.
  static String? _extractUnlabelledAccount(String text, String? ifsc) {
    final allDigits = _digitSequence.allMatches(text).toList();
    final candidates = <String>[];

    for (final match in allDigits) {
      final seq = match.group(0)!;

      // Skip if it looks like a phone number.
      if (seq.length == 10 && _phonePattern.hasMatch(seq)) continue;

      // Skip if it is part of the IFSC code.
      if (ifsc != null && ifsc.contains(seq)) continue;

      candidates.add(seq);
    }

    if (candidates.isEmpty) return null;

    // Prefer the longest candidate.
    candidates.sort((a, b) => b.length.compareTo(a.length));
    return candidates.first;
  }

  // ── Step 4 – Name extraction ────────────────────────────────────

  /// Extracts the account holder name using label-first + heuristic.
  static String? _extractName(String text) {
    final lines = text.split('\n');

    // Strategy 1: label-based.
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!_nameLabelPattern.hasMatch(line)) continue;

      // Check for name on the same line after the label.
      final afterLabel =
          line.replaceFirst(_nameLabelPattern, '').trim();
      if (afterLabel.isNotEmpty &&
          RegExp(r'^[A-Za-z ]+$').hasMatch(afterLabel)) {
        return afterLabel.toUpperCase();
      }

      // Try the next non-empty line.
      for (int j = i + 1; j < lines.length && j <= i + 2; j++) {
        final nextLine = lines[j].trim();
        if (nextLine.isEmpty) continue;
        if (RegExp(r'^[A-Za-z ]+$').hasMatch(nextLine)) {
          return nextLine.toUpperCase();
        }
        break;
      }
    }

    // Strategy 2: ALL-CAPS heuristic.
    for (final line in lines) {
      final trimmed = line.trim();
      if (!_allCapsLine.hasMatch(trimmed)) continue;

      final words = trimmed.split(RegExp(r'\s+'));
      if (words.length < 2 || words.length > 4) continue;

      final hasExcluded = words.any(
        (w) => _nameExcludeKeywords.contains(w.toUpperCase()),
      );
      if (hasExcluded) continue;

      return trimmed;
    }

    return null;
  }

  // ── Step 5 – Masking ────────────────────────────────────────────

  /// Masks the account number showing only the last 4 digits.
  ///
  /// Example: "12345678901" → "XXXXXXX8901".
  static String _maskAccountNumber(String number) {
    if (number.length <= 4) return number;
    final visible = number.substring(number.length - 4);
    final masked = 'X' * (number.length - 4);
    return '$masked$visible';
  }
}
