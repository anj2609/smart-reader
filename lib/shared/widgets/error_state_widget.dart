import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Reusable error state widget with icon, message, and retry button.
///
/// Displayed when OCR processing fails or no data is found.
class ErrorStateWidget extends StatelessWidget {
  /// The error icon to display.
  final IconData icon;

  /// The error message to show.
  final String message;

  /// Callback invoked when the user taps "Try Again".
  final VoidCallback onRetry;

  /// Creates an [ErrorStateWidget].
  const ErrorStateWidget({
    super.key,
    this.icon = Icons.error_outline_rounded,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorColor.withAlpha(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppTheme.errorColor),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              side: const BorderSide(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
