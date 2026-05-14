import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/document_model.dart';

class DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isGrid;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    this.onLongPress,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isGrid) {
      return _buildGridCard(context, isDark);
    }
    return _buildListCard(context, isDark);
  }

  Widget _buildGridCard(BuildContext context, bool isDark) {
    final coverColor = _parseCoverColor();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
          border: Border.all(
            color: AppColors.primary.withAlpha(isDark ? 40 : 25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 40 : 15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      coverColor,
                      coverColor.withAlpha(180),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Pattern overlay
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _BookPatternPainter(
                          color: Colors.white.withAlpha(20),
                        ),
                      ),
                    ),
                    // Icon
                    Center(
                      child: Icon(
                        document.typeIcon,
                        size: 40,
                        color: Colors.white.withAlpha(200),
                      ),
                    ),
                    // File type badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(90),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          document.fileExtension,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Favorite indicator
                    if (document.isFavorite)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 18,
                          color: AppColors.secondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textOnDark
                                : AppColors.textDark,
                          ),
                    ),
                    const Spacer(),
                    if (document.readingProgress > 0) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: document.readingProgress,
                          backgroundColor: isDark
                              ? AppColors.darkElevated
                              : AppColors.lightCard,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            coverColor,
                          ),
                          minHeight: 3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${document.progressPercentage}%',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ] else
                      Text(
                        document.formattedFileSize,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, bool isDark) {
    final coverColor = _parseCoverColor();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
          border: Border.all(
            color: AppColors.primary.withAlpha(isDark ? 40 : 25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Mini cover
            Container(
              width: 56,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [coverColor, coverColor.withAlpha(180)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      document.typeIcon,
                      size: 24,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(80),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        document.fileExtension,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (document.author != null) ...[
                        Icon(
                          Icons.person_outline_rounded,
                          size: 13,
                          color: isDark
                              ? AppColors.textOnDarkMedium
                              : AppColors.textLight,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            document.author!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        document.formattedFileSize,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (document.readingProgress > 0)
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: document.readingProgress,
                              backgroundColor: isDark
                                  ? AppColors.darkElevated
                                  : AppColors.lightCard,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                coverColor,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${document.progressPercentage}%',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: coverColor,
                              ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Favorite
            if (document.isFavorite)
              Icon(
                Icons.favorite_rounded,
                size: 18,
                color: AppColors.secondary,
              ),
          ],
        ),
      ),
    );
  }

  Color _parseCoverColor() {
    if (document.coverColor != null) {
      try {
        return Color(
          int.parse(document.coverColor!.replaceFirst('#', '0xFF')),
        );
      } catch (_) {}
    }
    return AppColors.primary;
  }
}

class _BookPatternPainter extends CustomPainter {
  final Color color;

  _BookPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw subtle lines
    for (double i = 0; i < size.height; i += 12) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i + 20),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
