import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/document_provider.dart';
import '../../models/document_model.dart';
import '../../widgets/document_card.dart';
import '../../widgets/common_widgets.dart';
import '../reader/reader_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isGridView = true;
  final List<String> _categories = [
    'All',
    'PDF',
    'Text',
    'EPUB',
    'HTML',
    'Favorites',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final docProvider = context.watch<DocumentProvider>();

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'My Library',
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                // View toggle
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  ),
                  child: Row(
                    children: [
                      _ViewToggle(
                        icon: Icons.grid_view_rounded,
                        isActive: _isGridView,
                        onTap: () => setState(() => _isGridView = true),
                      ),
                      _ViewToggle(
                        icon: Icons.view_list_rounded,
                        isActive: !_isGridView,
                        onTap: () => setState(() => _isGridView = false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          // Category chips
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected =
                      docProvider.selectedCategory == category;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => docProvider.setCategory(category),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkCard
                                  : AppColors.lightCard),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.primary.withAlpha(isDark ? 40 : 25),
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.textOnDark
                                    : AppColors.textDark),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

          // Documents count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_getFilteredDocs(docProvider).length} documents',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),

          // Document grid/list
          Expanded(
            child: _getFilteredDocs(docProvider).isEmpty
                ? EmptyStateWidget(
                    icon: Icons.folder_open_rounded,
                    title: 'No documents found',
                    subtitle: _getEmptyMessage(docProvider.selectedCategory),
                  )
                : _isGridView
                    ? _buildGridView(docProvider)
                    : _buildListView(docProvider),
          ),
        ],
      ),
    );
  }

  List<DocumentModel> _getFilteredDocs(DocumentProvider provider) {
    if (provider.selectedCategory == 'Favorites') {
      return provider.favoriteDocuments;
    }
    return provider.filteredDocuments;
  }

  String _getEmptyMessage(String category) {
    if (category == 'Favorites') {
      return 'No favorite documents yet. Long press a document to add it to favorites.';
    }
    return 'No $category documents found. Add some to get started!';
  }

  Widget _buildGridView(DocumentProvider docProvider) {
    final docs = _getFilteredDocs(docProvider);
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return DocumentCard(
          document: doc,
          isGrid: true,
          onTap: () => _openDocument(doc),
          onLongPress: () => _showOptions(doc),
        )
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: 100 + (index * 60)),
              duration: 400.ms,
            )
            .scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1.0, 1.0),
              duration: 400.ms,
            );
      },
    );
  }

  Widget _buildListView(DocumentProvider docProvider) {
    final docs = _getFilteredDocs(docProvider);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return DocumentCard(
          document: doc,
          isGrid: false,
          onTap: () => _openDocument(doc),
          onLongPress: () => _showOptions(doc),
        )
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: 100 + (index * 60)),
              duration: 400.ms,
            )
            .slideX(begin: 0.05, end: 0);
      },
    );
  }

  void _openDocument(DocumentModel doc) {
    context.read<DocumentProvider>().openDocument(doc);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReaderScreen(document: doc)),
    );
  }

  void _showOptions(DocumentModel doc) {
    final docProvider = context.read<DocumentProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevated : AppColors.lightCard,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                doc.isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                color: AppColors.secondary,
              ),
              title: Text(doc.isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
              onTap: () {
                docProvider.toggleFavorite(doc.id);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              title: const Text('Delete'),
              onTap: () {
                docProvider.deleteDocument(doc.id);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewToggle({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isActive ? AppColors.primary : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? Colors.white : AppColors.textLight,
        ),
      ),
    );
  }
}
