import 'package:flutter/material.dart';

enum DocumentType { pdf, txt, epub, html, md, unknown }

enum ReadingStatus { unread, reading, completed }

class DocumentModel {
  final String id;
  final String title;
  final String? author;
  final String filePath;
  final DocumentType type;
  final int totalPages;
  final int currentPage;
  final ReadingStatus status;
  final DateTime addedDate;
  final DateTime lastOpenedDate;
  final int fileSize; // in bytes
  final String? coverColor; // Hex color string for generated cover
  final String? description;
  final double readingProgress; // 0.0 to 1.0
  final bool isFavorite;
  final List<String> tags;

  const DocumentModel({
    required this.id,
    required this.title,
    this.author,
    required this.filePath,
    required this.type,
    this.totalPages = 0,
    this.currentPage = 0,
    this.status = ReadingStatus.unread,
    required this.addedDate,
    required this.lastOpenedDate,
    this.fileSize = 0,
    this.coverColor,
    this.description,
    this.readingProgress = 0.0,
    this.isFavorite = false,
    this.tags = const [],
  });

  DocumentModel copyWith({
    String? id,
    String? title,
    String? author,
    String? filePath,
    DocumentType? type,
    int? totalPages,
    int? currentPage,
    ReadingStatus? status,
    DateTime? addedDate,
    DateTime? lastOpenedDate,
    int? fileSize,
    String? coverColor,
    String? description,
    double? readingProgress,
    bool? isFavorite,
    List<String>? tags,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      type: type ?? this.type,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      status: status ?? this.status,
      addedDate: addedDate ?? this.addedDate,
      lastOpenedDate: lastOpenedDate ?? this.lastOpenedDate,
      fileSize: fileSize ?? this.fileSize,
      coverColor: coverColor ?? this.coverColor,
      description: description ?? this.description,
      readingProgress: readingProgress ?? this.readingProgress,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'filePath': filePath,
      'type': type.index,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'status': status.index,
      'addedDate': addedDate.toIso8601String(),
      'lastOpenedDate': lastOpenedDate.toIso8601String(),
      'fileSize': fileSize,
      'coverColor': coverColor,
      'description': description,
      'readingProgress': readingProgress,
      'isFavorite': isFavorite ? 1 : 0,
      'tags': tags.join(','),
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] as String,
      title: map['title'] as String,
      author: map['author'] as String?,
      filePath: map['filePath'] as String,
      type: DocumentType.values[map['type'] as int],
      totalPages: map['totalPages'] as int? ?? 0,
      currentPage: map['currentPage'] as int? ?? 0,
      status: ReadingStatus.values[map['status'] as int? ?? 0],
      addedDate: DateTime.parse(map['addedDate'] as String),
      lastOpenedDate: DateTime.parse(map['lastOpenedDate'] as String),
      fileSize: map['fileSize'] as int? ?? 0,
      coverColor: map['coverColor'] as String?,
      description: map['description'] as String?,
      readingProgress: (map['readingProgress'] as num?)?.toDouble() ?? 0.0,
      isFavorite: (map['isFavorite'] as int?) == 1,
      tags: (map['tags'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? [],
    );
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get fileExtension {
    switch (type) {
      case DocumentType.pdf:
        return 'PDF';
      case DocumentType.txt:
        return 'TXT';
      case DocumentType.epub:
        return 'EPUB';
      case DocumentType.html:
        return 'HTML';
      case DocumentType.md:
        return 'MD';
      case DocumentType.unknown:
        return 'FILE';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case DocumentType.pdf:
        return Icons.picture_as_pdf_rounded;
      case DocumentType.txt:
        return Icons.text_snippet_rounded;
      case DocumentType.epub:
        return Icons.auto_stories_rounded;
      case DocumentType.html:
        return Icons.language_rounded;
      case DocumentType.md:
        return Icons.code_rounded;
      case DocumentType.unknown:
        return Icons.insert_drive_file_rounded;
    }
  }

  int get progressPercentage => (readingProgress * 100).round();
}
