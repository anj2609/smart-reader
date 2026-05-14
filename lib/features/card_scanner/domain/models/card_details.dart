/// Immutable data model representing parsed credit/debit card details.
///
/// This model holds all extracted fields from OCR text including the
/// card number, expiry date, cardholder name, detected network, and
/// Luhn validation result.
class CardDetails {
  /// Raw card number digits only, e.g. "4111111111111111".
  final String? cardNumber;

  /// Masked display format, e.g. "XXXX XXXX XXXX 1111".
  final String maskedNumber;

  /// Expiry date normalized to "MM/YY" format.
  final String? expiryDate;

  /// Cardholder name as found on the card.
  final String? cardHolderName;

  /// Detected card network: "Visa", "Mastercard", "RuPay", "Amex",
  /// "Discover", or "Unknown".
  final String? cardNetwork;

  /// Whether the card number passes the Luhn check.
  final bool isValid;

  /// Creates a [CardDetails] instance with the given fields.
  const CardDetails({
    this.cardNumber,
    this.maskedNumber = '',
    this.expiryDate,
    this.cardHolderName,
    this.cardNetwork,
    this.isValid = false,
  });

  /// Creates a copy of this object with the given fields replaced.
  CardDetails copyWith({
    String? cardNumber,
    String? maskedNumber,
    String? expiryDate,
    String? cardHolderName,
    String? cardNetwork,
    bool? isValid,
  }) {
    return CardDetails(
      cardNumber: cardNumber ?? this.cardNumber,
      maskedNumber: maskedNumber ?? this.maskedNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      cardNetwork: cardNetwork ?? this.cardNetwork,
      isValid: isValid ?? this.isValid,
    );
  }

  /// Converts this object to a Map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'cardNumber': cardNumber,
      'maskedNumber': maskedNumber,
      'expiryDate': expiryDate,
      'cardHolderName': cardHolderName,
      'cardNetwork': cardNetwork,
      'isValid': isValid,
    };
  }

  @override
  String toString() {
    return 'CardDetails('
        'cardNumber: $cardNumber, '
        'maskedNumber: $maskedNumber, '
        'expiryDate: $expiryDate, '
        'cardHolderName: $cardHolderName, '
        'cardNetwork: $cardNetwork, '
        'isValid: $isValid)';
  }
}
