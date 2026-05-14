import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/camera_capture_button.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/loading_overlay.dart';
import 'passbook_scanner_provider.dart';
import 'widgets/passbook_preview_widget.dart';
import 'widgets/passbook_result_widget.dart';

/// Screen that allows users to scan a bank passbook via camera or gallery.
class PassbookScannerScreen extends ConsumerWidget {
  /// Creates a [PassbookScannerScreen].
  const PassbookScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(passbookScannerProvider);
    final notifier = ref.read(passbookScannerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.passbookScannerTitle),
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
            PassbookPreviewWidget(imagePath: state.imagePath),
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
    PassbookScannerState state,
    PassbookScannerNotifier notifier,
  ) {
    switch (state.status) {
      case PassbookScanStatus.idle:
        return const SizedBox.shrink();
      case PassbookScanStatus.loading:
        return const LoadingOverlay();
      case PassbookScanStatus.success:
        return PassbookResultWidget(details: state.result!);
      case PassbookScanStatus.error:
        return ErrorStateWidget(
          message: state.errorMessage ?? AppStrings.unknownError,
          onRetry: () => notifier.reset(),
        );
    }
  }
}
