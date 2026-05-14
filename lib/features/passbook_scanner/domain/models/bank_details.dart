/// Immutable data model representing parsed bank passbook details.
///
/// This model holds all extracted fields from OCR text including the
/// account holder name, account number, IFSC code, and derived bank name.
class BankDetails {
  /// Account holder name as found in the passbook.
  final String? accountHolderName;

  /// Raw account number digits only.
  final String? accountNumber;

  /// Masked account number showing only last 4 digits,
  /// e.g. "XXXXXXXXXXXX1234".
  final String? maskedAccount;

  /// IFSC code, e.g. "SBIN0001234".
  final String? ifscCode;

  /// Bank name derived from the IFSC prefix when possible.
  final String? bankName;

  /// Creates a [BankDetails] instance with the given fields.
  const BankDetails({
    this.accountHolderName,
    this.accountNumber,
    this.maskedAccount,
    this.ifscCode,
    this.bankName,
  });

  /// Creates a copy of this object with the given fields replaced.
  BankDetails copyWith({
    String? accountHolderName,
    String? accountNumber,
    String? maskedAccount,
    String? ifscCode,
    String? bankName,
  }) {
    return BankDetails(
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNumber: accountNumber ?? this.accountNumber,
      maskedAccount: maskedAccount ?? this.maskedAccount,
      ifscCode: ifscCode ?? this.ifscCode,
      bankName: bankName ?? this.bankName,
    );
  }

  /// Converts this object to a Map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'maskedAccount': maskedAccount,
      'ifscCode': ifscCode,
      'bankName': bankName,
    };
  }

  @override
  String toString() {
    return 'BankDetails('
        'accountHolderName: $accountHolderName, '
        'accountNumber: $accountNumber, '
        'maskedAccount: $maskedAccount, '
        'ifscCode: $ifscCode, '
        'bankName: $bankName)';
  }
}
