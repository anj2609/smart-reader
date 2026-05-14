import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_reader/core/theme/app_theme.dart';
import 'package:smart_reader/core/constants/app_strings.dart';

/// Displays a preview of the captured/selected image, or a placeholder
/// when no image has been chosen yet.
class CardPreviewWidget extends StatelessWidget {
  /// File path to the image to display, or `null` for the placeholder.
  final String? imagePath;

  /// Creates a [CardPreviewWidget].
  const CardPreviewWidget({super.key, this.imagePath});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.dividerColor,
            style: imagePath == null ? BorderStyle.none : BorderStyle.solid,
          ),
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
            : _buildPlaceholder(context),
      ),
    );
  }

  /// Builds the dashed-border placeholder shown before an image is selected.
  Widget _buildPlaceholder(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.credit_card_rounded,
              size: 48,
              color: AppTheme.textSecondary.withAlpha(120),
            ),
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
    );
  }
}

/// Draws a dashed rounded-rectangle border.
class _DashedBorderPainter extends CustomPainter {
  static const double _dashWidth = 8;
  static const double _dashGap = 4;
  static const double _radius = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.dividerColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(_radius),
      ));

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + _dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(
          metric.extractPath(distance, end),
          paint,
        );
        distance += _dashWidth + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
