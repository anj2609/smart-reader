/// Centralised string literals used across the DocuScan application.
///
/// Keeping all user-facing strings in one place makes localisation
/// and copy changes easy.
class AppStrings {
  AppStrings._();

  // ── App-level ──
  static const String appName = 'DocuScan';
  static const String appTagline = 'Card & Passbook OCR Scanner';

  // ── Home screen ──
  static const String scanCard = 'Scan Credit/Debit Card';
  static const String scanPassbook = 'Scan Bank Passbook';
  static const String scanCardSubtitle = 'Extract card number, expiry & name';
  static const String scanPassbookSubtitle = 'Extract account details & IFSC';

  // ── Scanner screens ──
  static const String cardScannerTitle = 'Card Scanner';
  static const String passbookScannerTitle = 'Passbook Scanner';
  static const String camera = 'Camera';
  static const String gallery = 'Gallery';
  static const String scanning = 'Scanning...';
  static const String tryAgain = 'Try Again';

  // ── Result labels ──
  static const String cardNumber = 'Card Number';
  static const String expiryDate = 'Expiry Date';
  static const String cardHolder = 'Card Holder';
  static const String cardNetwork = 'Card Network';
  static const String validCard = 'Valid Card';
  static const String invalidCard = 'Invalid Card';
  static const String accountHolder = 'Account Holder';
  static const String accountNumber = 'Account Number';
  static const String ifscCode = 'IFSC Code';
  static const String bankName = 'Bank Name';
  static const String notDetected = 'Not detected';

  // ── Errors ──
  static const String noTextFound = 'No text found in image';
  static const String couldNotDetectCard = 'Could not detect card details';
  static const String couldNotDetectPassbook =
      'Could not detect passbook details';
  static const String cameraPermissionDenied =
      'Camera permission denied. Please grant access in Settings.';
  static const String imageQualityTooLow =
      'Image quality too low. Please try a clearer photo.';
  static const String unknownError = 'Something went wrong. Please try again.';

  // ── Image placeholder ──
  static const String tapToCapture =
      'Tap Camera or Gallery to scan a document';

  /// Minimum number of characters the OCR output must contain to be
  /// considered a valid (non-blurry) scan.
  static const int minOcrCharacters = 10;
}
