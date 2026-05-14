/// Validates credit/debit card numbers using the Luhn algorithm.
///
/// The Luhn algorithm (also known as the "modulus 10" algorithm) is a
/// checksum formula used to validate identification numbers such as
/// card numbers, IMEI numbers, and others.
class LuhnValidator {
  LuhnValidator._();

  /// Minimum number of digits a card number can have.
  static const int minCardDigits = 13;

  /// Maximum number of digits a card number can have.
  static const int maxCardDigits = 19;

  /// Returns `true` if [cardNumber] is a valid card number per the
  /// Luhn algorithm.
  ///
  /// The method:
  /// 1. Strips all non-digit characters.
  /// 2. Returns `false` if length is outside [minCardDigits]..[maxCardDigits].
  /// 3. Starting from the second-to-last digit, doubles every second digit.
  /// 4. If the doubled value exceeds 9, subtracts 9.
  /// 5. Sums all resulting digits.
  /// 6. Returns `true` when the total modulo 10 equals 0.
  static bool isValidCard(String cardNumber) {
    // Step 1 — Strip all non-digit characters.
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');

    // Step 2 — Length check.
    if (digits.length < minCardDigits || digits.length > maxCardDigits) {
      return false;
    }

    int sum = 0;
    final int length = digits.length;
    // `parity` tracks whether the current position (from the right)
    // should be doubled.  The rightmost digit is position 0 (not doubled).
    final int parity = length % 2;

    for (int i = 0; i < length; i++) {
      int digit = int.parse(digits[i]);

      // Step 3 — Double every second digit from the right.
      if (i % 2 == parity) {
        digit *= 2;

        // Step 4 — Subtract 9 if result > 9.
        if (digit > 9) {
          digit -= 9;
        }
      }

      // Step 5 — Accumulate.
      sum += digit;
    }

    // Step 6 — Valid when divisible by 10.
    return sum % 10 == 0;
  }
}
