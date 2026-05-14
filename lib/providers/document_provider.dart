import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/document_model.dart';
import '../models/bookmark_model.dart';
import '../models/reading_stats.dart';
import '../core/utils/database_helper.dart';
import '../core/constants/app_constants.dart';

class DocumentProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  List<DocumentModel> _documents = [];
  List<DocumentModel> _recentDocuments = [];
  List<DocumentModel> _favoriteDocuments = [];
  List<BookmarkModel> _bookmarks = [];
  DocumentModel? _currentDocument;
  ReadingStats _readingStats = const ReadingStats();
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // Getters
  List<DocumentModel> get documents => _documents;
  List<DocumentModel> get recentDocuments => _recentDocuments;
  List<DocumentModel> get favoriteDocuments => _favoriteDocuments;
  List<BookmarkModel> get bookmarks => _bookmarks;
  DocumentModel? get currentDocument => _currentDocument;
  ReadingStats get readingStats => _readingStats;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<DocumentModel> get filteredDocuments {
    var docs = _documents;
    if (_searchQuery.isNotEmpty) {
      docs = docs
          .where((d) =>
              d.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (d.author?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
          .toList();
    }
    if (_selectedCategory != 'All') {
      final type = _getCategoryType(_selectedCategory);
      if (type != null) {
        docs = docs.where((d) => d.type == type).toList();
      }
    }
    return docs;
  }

  List<DocumentModel> get currentlyReading =>
      _documents.where((d) => d.status == ReadingStatus.reading).toList();

  DocumentType? _getCategoryType(String category) {
    switch (category.toLowerCase()) {
      case 'pdf':
        return DocumentType.pdf;
      case 'text':
        return DocumentType.txt;
      case 'epub':
        return DocumentType.epub;
      case 'html':
        return DocumentType.html;
      default:
        return null;
    }
  }

  // Initialize
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _documents = await _dbHelper.getAllDocuments();
      _recentDocuments = await _dbHelper.getRecentDocuments();
      _favoriteDocuments = await _dbHelper.getFavoriteDocuments();
      _bookmarks = await _dbHelper.getAllBookmarks();
      await _loadReadingStats();
    } catch (e) {
      debugPrint('Error initializing: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadReadingStats() async {
    final stats = await _dbHelper.getReadingStats();
    _readingStats = ReadingStats(
      totalDocuments: stats['totalDocuments'] as int,
      completedDocuments: stats['completedDocuments'] as int,
      currentlyReading: stats['currentlyReading'] as int,
      totalPagesRead: stats['totalPagesRead'] as int,
    );
  }

  // Search
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // File picking & adding documents
  Future<DocumentModel?> pickAndAddDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.supportedFileTypes,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path == null) return null;

        final docType = _getDocumentType(file.extension ?? '');
        final colors = [
          '#6C63FF', '#FF6B6B', '#2EC4B6', '#FFD93D',
          '#845EC2', '#FF6F91', '#00C9A7', '#FFC75F',
        ];

        final doc = DocumentModel(
          id: _uuid.v4(),
          title: file.name.replaceAll('.${file.extension}', ''),
          filePath: file.path!,
          type: docType,
          fileSize: file.size,
          addedDate: DateTime.now(),
          lastOpenedDate: DateTime.now(),
          coverColor: colors[Random().nextInt(colors.length)],
          status: ReadingStatus.unread,
        );

        await _dbHelper.insertDocument(doc);
        await initialize();
        return doc;
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
    return null;
  }

  DocumentType _getDocumentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return DocumentType.pdf;
      case 'txt':
        return DocumentType.txt;
      case 'epub':
        return DocumentType.epub;
      case 'html':
      case 'htm':
        return DocumentType.html;
      case 'md':
        return DocumentType.md;
      default:
        return DocumentType.unknown;
    }
  }

  // Open document
  Future<void> openDocument(DocumentModel doc) async {
    _currentDocument = doc.copyWith(
      lastOpenedDate: DateTime.now(),
      status: ReadingStatus.reading,
    );
    await _dbHelper.updateDocument(_currentDocument!);
    notifyListeners();
  }

  // Update reading progress
  Future<void> updateReadingProgress(String docId, int currentPage, int totalPages) async {
    final doc = _documents.firstWhere((d) => d.id == docId);
    final progress = totalPages > 0 ? currentPage / totalPages : 0.0;
    final status = progress >= 1.0 ? ReadingStatus.completed : ReadingStatus.reading;

    final updatedDoc = doc.copyWith(
      currentPage: currentPage,
      totalPages: totalPages,
      readingProgress: progress,
      status: status,
      lastOpenedDate: DateTime.now(),
    );

    await _dbHelper.updateDocument(updatedDoc);
    _currentDocument = updatedDoc;
    await initialize();
  }

  // Toggle favorite
  Future<void> toggleFavorite(String docId) async {
    final index = _documents.indexWhere((d) => d.id == docId);
    if (index != -1) {
      final doc = _documents[index];
      final updatedDoc = doc.copyWith(isFavorite: !doc.isFavorite);
      await _dbHelper.updateDocument(updatedDoc);
      await initialize();
    }
  }

  // Delete document
  Future<void> deleteDocument(String docId) async {
    await _dbHelper.deleteDocument(docId);
    await initialize();
  }

  // Bookmarks
  Future<void> addBookmark(String documentId, int pageNumber,
      {String? title, String? note}) async {
    final bookmark = BookmarkModel(
      id: _uuid.v4(),
      documentId: documentId,
      pageNumber: pageNumber,
      title: title ?? 'Page $pageNumber',
      note: note,
      createdDate: DateTime.now(),
    );
    await _dbHelper.insertBookmark(bookmark);
    _bookmarks = await _dbHelper.getAllBookmarks();
    notifyListeners();
  }

  Future<void> deleteBookmark(String bookmarkId) async {
    await _dbHelper.deleteBookmark(bookmarkId);
    _bookmarks = await _dbHelper.getAllBookmarks();
    notifyListeners();
  }

  Future<List<BookmarkModel>> getBookmarksForDocument(String documentId) async {
    return await _dbHelper.getBookmarksForDocument(documentId);
  }
}
