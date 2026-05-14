import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_reader/core/theme/app_theme.dart';
import 'package:smart_reader/core/constants/app_strings.dart';

/// Displays a preview of the captured/selected passbook image, or
/// a placeholder when no image has been chosen.
class PassbookPreviewWidget extends StatelessWidget {
  /// File path to the image, or `null` for the placeholder.
  final String? imagePath;

  /// Creates a [PassbookPreviewWidget].
  const PassbookPreviewWidget({super.key, this.imagePath});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: imagePath != null
            ? Image.file(File(imagePath!), fit: BoxFit.cover)
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_rounded, size: 48,
                        color: AppTheme.textSecondary.withAlpha(120)),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.tapToCapture,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
