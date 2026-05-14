import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A styled pair of action buttons for Camera and Gallery capture.
///
/// Both buttons follow the same layout but invoke different callbacks.
class CameraCaptureButton extends StatelessWidget {
  /// Label displayed on the button.
  final String label;

  /// Icon displayed on the button.
  final IconData icon;

  /// Callback invoked when the button is tapped.
  final VoidCallback onPressed;

  /// Whether this is the primary (filled) or secondary (outlined) variant.
  final bool isPrimary;

  /// Creates a [CameraCaptureButton].
  const CameraCaptureButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return Expanded(
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          side: const BorderSide(color: AppTheme.primaryColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
