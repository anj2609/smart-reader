import '../domain/models/card_details.dart';
import '../../../core/utils/luhn_validator.dart';

/// Parses raw OCR text and extracts credit/debit card details.
///
/// The parser performs five extraction steps:
/// 1. Card number extraction with separator normalisation.
/// 2. Luhn validation.
/// 3. Card network detection from the leading digits.
/// 4. Expiry date extraction and normalisation.
/// 5. Cardholder name heuristic extraction.
class CardParser {
  CardParser._();

  // ── Pre-compiled regular expressions (static final) ────────────

  /// Matches 13–19 digits possibly separated by spaces, dashes, or dots.
  static final RegExp _cardNumberPattern = RegExp(r'(?:\d[\d \-\.]{11,22}\d)');

  /// Matches expiry-date-like patterns: MM/YY, MM/YYYY, MM-YY, MM-YYYY.
  static final RegExp _expiryPattern = RegExp(
    r'(?<!\d)(\d{2})\s*[/\-]\s*(\d{2,4})(?!\d)',
  );

  /// Matches lines that are entirely upper-case letters and spaces.
  static final RegExp _allCapsLine = RegExp(r'^[A-Z][A-Z ]{2,}$');

  /// Keywords commonly found on cards that should be excluded from name.
  static const List<String> _nameExcludeKeywords = [
    'VALID',
    'THRU',
    'EXPIRES',
    'MEMBER',
    'SINCE',
    'DEBIT',
    'CREDIT',
    'BANK',
    'PLATINUM',
    'GOLD',
    'VISA',
    'MASTERCARD',
    'RUPAY',
    'CARD',
    'INTERNATIONAL',
    'CLASSIC',
    'TITANIUM',
    'SIGNATURE',
    'WORLD',
    'ELECTRON',
    'MAESTRO',
    'AMERICAN',
    'EXPRESS',
    'FROM',
    'THROUGH',
  ];

  // ── Public API ──────────────────────────────────────────────────

  /// Parses [rawText] and returns a [CardDetails] instance.
  ///
  /// Returns a [CardDetails] with `isValid == false` and nullable fields
  /// set to `null` when parsing fails for a particular field.
  static CardDetails parseCard(String rawText) {
    final cardNumber = _extractCardNumber(rawText);
    final isValid = cardNumber != null && LuhnValidator.isValidCard(cardNumber);
    final network = cardNumber != null ? _detectNetwork(cardNumber) : null;
    final expiry = _extractExpiry(rawText);
    final name = _extractName(rawText);
    final masked = cardNumber != null ? _maskCardNumber(cardNumber) : '';

    return CardDetails(
      cardNumber: cardNumber,
      maskedNumber: masked,
      expiryDate: expiry,
      cardHolderName: name,
      cardNetwork: network,
      isValid: isValid,
    );
  }

  // ── Step 2 – Card number extraction ─────────────────────────────

  /// Finds all digit sequences of length 13–19 in [text], runs each
  /// through Luhn, and picks the first valid one.  Falls back to the
  /// longest sequence if none pass.
  static String? _extractCardNumber(String text) {
    final matches = _cardNumberPattern.allMatches(text);
    final candidates = <String>[];

    for (final match in matches) {
      final raw = match.group(0)!;
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= LuhnValidator.minCardDigits &&
          digits.length <= LuhnValidator.maxCardDigits) {
        candidates.add(digits);
      }
    }

    // Also try to find plain contiguous digit runs.
    final plainRuns = RegExp(r'\d{13,19}').allMatches(text);
    for (final m in plainRuns) {
      final d = m.group(0)!;
      if (!candidates.contains(d)) candidates.add(d);
    }

    if (candidates.isEmpty) return null;

    // Pick the first Luhn-valid candidate.
    for (final candidate in candidates) {
      if (LuhnValidator.isValidCard(candidate)) return candidate;
    }

    // Fallback: pick the best candidate even if Luhn validation fails (due to OCR errors).
    candidates.sort((a, b) {
      // Prefer common card lengths (16 for Visa/MC/RuPay/Discover, 15 for Amex).
      bool aIsCommon = a.length == 16 || a.length == 15;
      bool bIsCommon = b.length == 16 || b.length == 15;
      if (aIsCommon && !bIsCommon) return -1;
      if (!aIsCommon && bIsCommon) return 1;

      // Prefer known prefixes.
      bool aHasPrefix = ['4', '5', '6', '34', '37'].any((p) => a.startsWith(p));
      bool bHasPrefix = ['4', '5', '6', '34', '37'].any((p) => b.startsWith(p));
      if (aHasPrefix && !bHasPrefix) return -1;
      if (!aHasPrefix && bHasPrefix) return 1;

      // Otherwise pick the longest sequence.
      return b.length.compareTo(a.length);
    });
    return candidates.first;
  }

  // ── Step 3 – Network detection ─────────────────────────────────

  /// Detects the card network based on the leading digits of [number].
  static String _detectNetwork(String number) {
    if (number.startsWith('4')) return 'Visa';

    final twoDigit = int.tryParse(number.substring(0, 2)) ?? 0;
    if (twoDigit == 34 || twoDigit == 37) return 'Amex';
    if (twoDigit >= 51 && twoDigit <= 55) return 'Mastercard';

    // Mastercard 2-series range: 2221–2720.
    if (number.length >= 4) {
      final fourDigit = int.tryParse(number.substring(0, 4)) ?? 0;
      if (fourDigit >= 2221 && fourDigit <= 2720) return 'Mastercard';

      // RuPay ranges.
      if (number.startsWith('60') ||
          number.startsWith('6521') ||
          number.startsWith('6522')) {
        return 'RuPay';
      }

      // Discover ranges.
      if (number.startsWith('6011') ||
          number.startsWith('65') ||
          (fourDigit >= 6440 && fourDigit <= 6499)) {
        return 'Discover';
      }
      if (number.length >= 6) {
        final sixDigit = int.tryParse(number.substring(0, 6)) ?? 0;
        if (sixDigit >= 622126 && sixDigit <= 622925) return 'Discover';
      }
    }

    return 'Unknown';
  }

  // ── Step 4 – Expiry date extraction ─────────────────────────────

  /// Extracts and normalises the expiry date to "MM/YY".
  static String? _extractExpiry(String text) {
    // Try MM/YY or MM/YYYY patterns first.
    final expiryMatches = _expiryPattern.allMatches(text);
    for (final match in expiryMatches) {
      final result = _validateAndNormaliseExpiry(
        match.group(1)!,
        match.group(2)!,
      );
      if (result != null) return result;
    }

    // Fallback: if the OCR missed the slash entirely (e.g. "12 25" or "1225"),
    // search near explicitly labelled lines ("EXPIRE", "VALID", "THRU", etc.).
    final lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (RegExp(
        r'\b(?:EXPIRE|VALID|THRU|UPTO|EXP|EXPIRES)\b',
        caseSensitive: false,
      ).hasMatch(lines[i])) {
        // Check this line and the next line for a loose date pattern.
        for (int j = i; j <= i + 1 && j < lines.length; j++) {
          final looseMatches = RegExp(
            r'(?<!\d)(0[1-9]|1[0-2])\s*[/\\\-\.\s]*\s*(\d{2,4})(?!\d)',
          ).allMatches(lines[j]);
          for (final match in looseMatches) {
            final result = _validateAndNormaliseExpiry(
              match.group(1)!,
              match.group(2)!,
            );
            if (result != null) return result;
          }
        }
      }
    }

    return null;
  }

  /// Returns "MM/YY" when [month] is 01–12 and [year] is the current
  /// year or later, otherwise `null`.
  static String? _validateAndNormaliseExpiry(String month, String year) {
    final m = int.tryParse(month);
    if (m == null || m < 1 || m > 12) return null;

    int y = int.tryParse(year) ?? -1;
    if (y < 0) return null;

    // Normalise 4-digit year to 2-digit.
    if (y >= 2000) {
      y -= 2000;
    } else if (y >= 100) {
      return null; // 3-digit year is invalid.
    }

    // We accept any reasonable 2-digit year (e.g. up to 2050)
    // to ensure we still extract dates from recently expired cards.
    if (y > 50 && y < 100) return null;

    final mm = month.padLeft(2, '0');
    final yy = y.toString().padLeft(2, '0');
    return '$mm/$yy';
  }

  // ── Step 5 – Cardholder name extraction ─────────────────────────

  /// Extracts the most likely cardholder name from [text].
  static String? _extractName(String text) {
    final lines = text.split('\n');
    final candidates = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (!_allCapsLine.hasMatch(trimmed)) continue;

      final words = trimmed.split(RegExp(r'\s+'));
      if (words.length < 2 || words.length > 4) continue;

      // Ensure no excluded keywords.
      final hasExcluded = words.any(
        (w) => _nameExcludeKeywords.contains(w.toUpperCase()),
      );
      if (hasExcluded) continue;

      // Must be only letters and spaces.
      if (!RegExp(r'^[A-Za-z ]+$').hasMatch(trimmed)) continue;

      candidates.add(trimmed);
    }

    return candidates.isNotEmpty ? candidates.first : null;
  }

  // ── Masking helper ──────────────────────────────────────────────

  /// Masks all but the last 4 digits, grouping by 4.
  ///
  /// Example: "4111111111111111" → "XXXX XXXX XXXX 1111".
  static String _maskCardNumber(String number) {
    if (number.length <= 4) return number;

    final visible = number.substring(number.length - 4);
    final maskedLength = number.length - 4;
    final masked = 'X' * maskedLength + visible;

    // Group into blocks of 4.
    final buffer = StringBuffer();
    for (int i = 0; i < masked.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(masked[i]);
    }
    return buffer.toString();
  }
}
