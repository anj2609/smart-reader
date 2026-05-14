import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/document_provider.dart';
import '../../widgets/common_widgets.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final docProvider = context.watch<DocumentProvider>();
    final bookmarks = docProvider.bookmarks;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Text(
              'Bookmarks',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ).animate().fadeIn(duration: 400.ms),

          Expanded(
            child: bookmarks.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.bookmark_outline_rounded,
                    title: 'No bookmarks yet',
                    subtitle: 'Bookmark pages while reading to find them easily later.',
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: bookmarks.length,
                    itemBuilder: (context, index) {
                      final bookmark = bookmarks[index];
                      // Find associated document
                      final doc = docProvider.documents.where((d) => d.id == bookmark.documentId).firstOrNull;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                          border: Border.all(color: AppColors.primary.withAlpha(isDark ? 40 : 25)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(isDark ? 30 : 20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.bookmark_rounded, color: AppColors.primary, size: 22),
                          ),
                          title: Text(
                            bookmark.title ?? 'Page ${bookmark.pageNumber}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            doc?.title ?? 'Unknown document',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                            onPressed: () => docProvider.deleteBookmark(bookmark.id),
                          ),
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: 100 + (index * 60)), duration: 400.ms).slideX(begin: 0.05, end: 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
