import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/ocr_cleaner.dart';
import '../../../shared/services/ocr_service.dart';
import '../data/card_parser.dart';
import '../domain/models/card_details.dart';

/// Possible states the card scanner can be in.
enum ScanStatus { idle, loading, success, error }

/// Immutable state for the card scanner feature.
class CardScannerState {
  /// Current scan lifecycle status.
  final ScanStatus status;

  /// Parsed card details (available only when [status] is [ScanStatus.success]).
  final CardDetails? result;

  /// Error message (available only when [status] is [ScanStatus.error]).
  final String? errorMessage;

  /// Path to the captured/selected image.
  final String? imagePath;

  /// Creates a [CardScannerState].
  const CardScannerState({
    this.status = ScanStatus.idle,
    this.result,
    this.errorMessage,
    this.imagePath,
  });

  /// Creates a copy with the given fields replaced.
  CardScannerState copyWith({
    ScanStatus? status,
    CardDetails? result,
    String? errorMessage,
    String? imagePath,
  }) {
    return CardScannerState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

/// Manages the card scanner workflow: capture → OCR → parse → result.
class CardScannerNotifier extends StateNotifier<CardScannerState> {
  /// Creates a [CardScannerNotifier] starting in idle state.
  CardScannerNotifier() : super(const CardScannerState());

  final ImagePicker _picker = ImagePicker();

  /// Scans a card image captured from the device camera.
  Future<void> scanFromCamera() async {
    final permitted = await _requestCameraPermission();
    if (!permitted) {
      state = const CardScannerState(
        status: ScanStatus.error,
        errorMessage: AppStrings.cameraPermissionDenied,
      );
      return;
    }

    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (image == null) return; // User cancelled.

    await _processImage(image.path);
  }

  /// Scans a card image picked from the device gallery.
  Future<void> scanFromGallery() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (image == null) return; // User cancelled.

    await _processImage(image.path);
  }

  /// Resets the scanner to its initial idle state.
  void reset() {
    state = const CardScannerState();
  }

  /// Runs OCR and parsing on the image at [path].
  Future<void> _processImage(String path) async {
    state = CardScannerState(status: ScanStatus.loading, imagePath: path);

    try {
      final rawText = await OcrService.extractText(path);

      // Check for too-short output (blurry image).
      if (rawText.trim().length < AppStrings.minOcrCharacters) {
        state = CardScannerState(
          status: ScanStatus.error,
          imagePath: path,
          errorMessage: AppStrings.imageQualityTooLow,
        );
        return;
      }

      final cleaned = OcrCleaner.cleanForCard(rawText);
      final details = CardParser.parseCard(cleaned);

      // If nothing at all was found, report an error.
      if (details.cardNumber == null &&
          details.expiryDate == null &&
          details.cardHolderName == null) {
        state = CardScannerState(
          status: ScanStatus.error,
          imagePath: path,
          errorMessage: AppStrings.couldNotDetectCard,
        );
        return;
      }

      state = CardScannerState(
        status: ScanStatus.success,
        imagePath: path,
        result: details,
      );
    } on OcrException {
      state = CardScannerState(
        status: ScanStatus.error,
        imagePath: path,
        errorMessage: AppStrings.noTextFound,
      );
    } catch (_) {
      state = CardScannerState(
        status: ScanStatus.error,
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

/// Riverpod provider for the card scanner notifier.
final cardScannerProvider =
    StateNotifierProvider<CardScannerNotifier, CardScannerState>(
  (ref) => CardScannerNotifier(),
);
