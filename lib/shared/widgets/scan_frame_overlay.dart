import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Animated scan frame overlay with corner brackets and a moving scan line.
///
/// Used as a visual guide when the camera is active.
class ScanFrameOverlay extends StatefulWidget {
  /// Creates a [ScanFrameOverlay].
  const ScanFrameOverlay({super.key});

  @override
  State<ScanFrameOverlay> createState() => _ScanFrameOverlayState();
}

class _ScanFrameOverlayState extends State<ScanFrameOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scanLineAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ScanFramePainter(
            scanLinePosition: _scanLineAnimation.value,
          ),
        );
      },
    );
  }
}

/// Custom painter that draws corner brackets and a horizontal scan line.
class _ScanFramePainter extends CustomPainter {
  /// Vertical position of the scan line (0.0 = top, 1.0 = bottom).
  final double scanLinePosition;

  /// Length of each corner bracket arm.
  static const double _cornerLength = 30;

  /// Stroke width for the corner brackets.
  static const double _strokeWidth = 3;

  /// Creates a [_ScanFramePainter].
  _ScanFramePainter({required this.scanLinePosition});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * 0.1,
      size.height * 0.1,
      size.width * 0.8,
      size.height * 0.8,
    );

    final cornerPaint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw four corner brackets.
    _drawCorner(canvas, rect.topLeft, 1, 1, cornerPaint);
    _drawCorner(canvas, rect.topRight, -1, 1, cornerPaint);
    _drawCorner(canvas, rect.bottomLeft, 1, -1, cornerPaint);
    _drawCorner(canvas, rect.bottomRight, -1, -1, cornerPaint);

    // Draw the animated scan line.
    final scanY = rect.top + rect.height * scanLinePosition;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.primaryColor.withAlpha(0),
          AppTheme.primaryColor.withAlpha(180),
          AppTheme.primaryColor.withAlpha(0),
        ],
      ).createShader(Rect.fromLTWH(rect.left, scanY, rect.width, 2));

    canvas.drawLine(
      Offset(rect.left, scanY),
      Offset(rect.right, scanY),
      scanPaint..strokeWidth = 2,
    );
  }

  /// Draws a single corner bracket at [origin].
  void _drawCorner(
    Canvas canvas,
    Offset origin,
    int xDir,
    int yDir,
    Paint paint,
  ) {
    canvas.drawLine(
      origin,
      Offset(origin.dx + _cornerLength * xDir, origin.dy),
      paint,
    );
    canvas.drawLine(
      origin,
      Offset(origin.dx, origin.dy + _cornerLength * yDir),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ScanFramePainter oldDelegate) {
    return oldDelegate.scanLinePosition != scanLinePosition;
  }
}
