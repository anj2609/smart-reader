import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/ocr_cleaner.dart';
import '../../../shared/services/ocr_service.dart';
import '../data/passbook_parser.dart';
import '../domain/models/bank_details.dart';

/// Possible states the passbook scanner can be in.
enum PassbookScanStatus { idle, loading, success, error }

/// Immutable state for the passbook scanner feature.
class PassbookScannerState {
  /// Current scan lifecycle status.
  final PassbookScanStatus status;

  /// Parsed bank details (available when [status] is success).
  final BankDetails? result;

  /// Error message (available when [status] is error).
  final String? errorMessage;

  /// Path to the captured/selected image.
  final String? imagePath;

  /// Creates a [PassbookScannerState].
  const PassbookScannerState({
    this.status = PassbookScanStatus.idle,
    this.result,
    this.errorMessage,
    this.imagePath,
  });

  /// Creates a copy with the given fields replaced.
  PassbookScannerState copyWith({
    PassbookScanStatus? status,
    BankDetails? result,
    String? errorMessage,
    String? imagePath,
  }) {
    return PassbookScannerState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

/// Manages the passbook scanner workflow: capture → OCR → parse → result.
class PassbookScannerNotifier extends StateNotifier<PassbookScannerState> {
  /// Creates a [PassbookScannerNotifier] starting in idle state.
  PassbookScannerNotifier() : super(const PassbookScannerState());

  final ImagePicker _picker = ImagePicker();

  /// Scans a passbook image captured from the device camera.
  Future<void> scanFromCamera() async {
    final permitted = await _requestCameraPermission();
    if (!permitted) {
      state = const PassbookScannerState(
        status: PassbookScanStatus.error,
        errorMessage: AppStrings.cameraPermissionDenied,
      );
      return;
    }

    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (image == null) return;

    await _processImage(image.path);
  }

  /// Scans a passbook image picked from the device gallery.
  Future<void> scanFromGallery() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (image == null) return;

    await _processImage(image.path);
  }

  /// Resets the scanner to its initial idle state.
  void reset() {
    state = const PassbookScannerState();
  }

  /// Runs OCR and parsing on the image at [path].
  Future<void> _processImage(String path) async {
    state = PassbookScannerState(
      status: PassbookScanStatus.loading,
      imagePath: path,
    );

    try {
      final rawText = await OcrService.extractText(path);

      if (rawText.trim().length < AppStrings.minOcrCharacters) {
        state = PassbookScannerState(
          status: PassbookScanStatus.error,
          imagePath: path,
          errorMessage: AppStrings.imageQualityTooLow,
        );
        return;
      }

      final cleaned = OcrCleaner.cleanForPassbook(rawText);
      final details = PassbookParser.parsePassbook(cleaned);

      if (details.accountNumber == null &&
          details.ifscCode == null &&
          details.accountHolderName == null) {
        state = PassbookScannerState(
          status: PassbookScanStatus.error,
          imagePath: path,
          errorMessage: AppStrings.couldNotDetectPassbook,
        );
        return;
      }

      state = PassbookScannerState(
        status: PassbookScanStatus.success,
        imagePath: path,
        result: details,
      );
    } on OcrException {
      state = PassbookScannerState(
        status: PassbookScanStatus.error,
        imagePath: path,
        errorMessage: AppStrings.noTextFound,
      );
    } catch (_) {
      state = PassbookScannerState(
        status: PassbookScanStatus.error,
        imagePath: path,
        errorMessage: AppStrings.unknownError,
      );
    }
  }

  /// Requests camera permission and returns whether it was granted.
  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
}

/// Riverpod provider for the passbook scanner notifier.
final passbookScannerProvider =
    StateNotifierProvider<PassbookScannerNotifier, PassbookScannerState>(
  (ref) => PassbookScannerNotifier(),
);
