import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/document_provider.dart';
import '../../widgets/document_card.dart';
import '../reader/reader_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final docProvider = context.watch<DocumentProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      docProvider.setSearchQuery('');
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        border: Border.all(color: AppColors.primary.withAlpha(isDark ? 50 : 30)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        onChanged: (value) => docProvider.setSearchQuery(value),
                        style: TextStyle(color: isDark ? AppColors.textOnDark : AppColors.textDark),
                        decoration: InputDecoration(
                          hintText: 'Search documents...',
                          prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary.withAlpha(150)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    docProvider.setSearchQuery('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            // Results
            Expanded(
              child: docProvider.searchQuery.isEmpty
                  ? _buildSuggestions(context, isDark)
                  : docProvider.filteredDocuments.isEmpty
                      ? _buildNoResults(context)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: docProvider.filteredDocuments.length,
                          itemBuilder: (context, index) {
                            final doc = docProvider.filteredDocuments[index];
                            return DocumentCard(
                              document: doc,
                              onTap: () {
                                docProvider.openDocument(doc);
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ReaderScreen(document: doc)));
                              },
                            ).animate().fadeIn(delay: Duration(milliseconds: 50 * index), duration: 300.ms);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 64, color: AppColors.primary.withAlpha(80)),
          const SizedBox(height: 16),
          Text('Search your library', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: isDark ? AppColors.textOnDarkMedium : AppColors.textMedium)),
          const SizedBox(height: 8),
          Text('Find documents by title or author', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textLight)),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildNoResults(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: AppColors.textLight.withAlpha(100)),
          const SizedBox(height: 16),
          Text('No results found', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Try a different search term', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textLight)),
        ],
      ),
    );
  }
}
