import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/camera_capture_button.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/loading_overlay.dart';
import 'card_scanner_provider.dart';
import 'widgets/card_preview_widget.dart';
import 'widgets/card_result_widget.dart';

/// Screen that allows users to scan a credit/debit card via camera or gallery.
class CardScannerScreen extends ConsumerWidget {
  /// Creates a [CardScannerScreen].
  const CardScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cardScannerProvider);
    final notifier = ref.read(cardScannerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.cardScannerTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            notifier.reset();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            // 1. Image preview area.
            CardPreviewWidget(imagePath: state.imagePath),
            const SizedBox(height: 20),

            // 2. Action buttons.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CameraCaptureButton(
                    label: AppStrings.camera,
                    icon: Icons.camera_alt_rounded,
                    onPressed: () => notifier.scanFromCamera(),
                    isPrimary: true,
                  ),
                  const SizedBox(width: 12),
                  CameraCaptureButton(
                    label: AppStrings.gallery,
                    icon: Icons.photo_library_rounded,
                    onPressed: () => notifier.scanFromGallery(),
                    isPrimary: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. State-dependent content.
            _buildStateContent(state, notifier),
          ],
        ),
      ),
    );
  }

  /// Returns the correct widget for the current scan state.
  Widget _buildStateContent(
    CardScannerState state,
    CardScannerNotifier notifier,
  ) {
    switch (state.status) {
      case ScanStatus.idle:
        return const SizedBox.shrink();
      case ScanStatus.loading:
        return const LoadingOverlay();
      case ScanStatus.success:
        return CardResultWidget(details: state.result!);
      case ScanStatus.error:
        return ErrorStateWidget(
          message: state.errorMessage ?? AppStrings.unknownError,
          onRetry: () => notifier.reset(),
        );
    }
  }
}
