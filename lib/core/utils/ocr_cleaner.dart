/// Pre-processing utilities for raw OCR text.
///
/// OCR engines frequently misread characters — for example confusing the
/// letter "O" with the digit "0".  This class provides context-aware
/// cleaning methods for card and passbook scanning.
class OcrCleaner {
  OcrCleaner._();

  /// Characters that OCR commonly confuses with digits, and the digit
  /// they most likely represent.
  static const Map<String, String> _digitSubstitutions = {
    'O': '0',
    'o': '0',
    'l': '1',
    'I': '1',
    'S': '5',
    'B': '8',
  };

  // Pre-compiled patterns — used by both cleaners.
  static final RegExp _multipleSpaces = RegExp(r' {2,}');
  static final RegExp _formFeed = RegExp(r'[\f\v]');
  static final RegExp _nonAsciiLine = RegExp(r'[^\x00-\x7F]');

  /// Regex matching a "digit-heavy token" — a sequence where at least
  /// half the characters are digits, with the rest being common OCR
  /// substitution candidates or separators.
  static final RegExp _digitHeavyToken =
      RegExp(r'(?:\d[\dOolISB \-\.]*){3,}');

  // ────────────────────────────────────────────────────────────────
  // Public API
  // ────────────────────────────────────────────────────────────────

  /// Cleans raw OCR text for **card** scanning.
  ///
  /// * Applies digit substitutions only inside digit-heavy tokens.
  /// * Normalises whitespace.
  /// * Trims each line.
  static String cleanForCard(String raw) {
    final lines = raw.split('\n');
    final buffer = StringBuffer();

    for (final line in lines) {
      final cleaned = _substituteDigitsInHeavyTokens(line.trim());
      buffer.writeln(cleaned.replaceAll(_multipleSpaces, ' '));
    }

    return buffer.toString().trim();
  }

  /// Cleans raw OCR text for **passbook** scanning.
  ///
  /// Performs the same digit-substitutions as [cleanForCard] plus:
  /// * Removes form-feed / vertical-tab characters.
  /// * Normalises dashes and dots inside numbers.
  /// * Drops lines that contain non-ASCII characters (e.g. Devanagari).
  static String cleanForPassbook(String raw) {
    final stripped = raw.replaceAll(_formFeed, '\n');
    final lines = stripped.split('\n');
    final buffer = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();

      // Skip lines with non-ASCII (mixed-script) characters.
      if (_nonAsciiLine.hasMatch(trimmed)) continue;

      final cleaned = _substituteDigitsInHeavyTokens(trimmed);
      buffer.writeln(cleaned.replaceAll(_multipleSpaces, ' '));
    }

    return buffer.toString().trim();
  }

  // ────────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────────

  /// Walks through [text], finds digit-heavy tokens, and replaces
  /// common OCR misreads within those tokens only.
  static String _substituteDigitsInHeavyTokens(String text) {
    return text.replaceAllMapped(_digitHeavyToken, (match) {
      final token = match.group(0)!;
      final sb = StringBuffer();
      for (int i = 0; i < token.length; i++) {
        final char = token[i];
        sb.write(_digitSubstitutions[char] ?? char);
      }
      return sb.toString();
    });
  }
}
