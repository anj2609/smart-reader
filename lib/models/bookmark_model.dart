class BookmarkModel {
  final String id;
  final String documentId;
  final int pageNumber;
  final String? title;
  final String? note;
  final DateTime createdDate;
  final String? highlightColor; // Hex color

  const BookmarkModel({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    this.title,
    this.note,
    required this.createdDate,
    this.highlightColor,
  });

  BookmarkModel copyWith({
    String? id,
    String? documentId,
    int? pageNumber,
    String? title,
    String? note,
    DateTime? createdDate,
    String? highlightColor,
  }) {
    return BookmarkModel(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      title: title ?? this.title,
      note: note ?? this.note,
      createdDate: createdDate ?? this.createdDate,
      highlightColor: highlightColor ?? this.highlightColor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documentId': documentId,
      'pageNumber': pageNumber,
      'title': title,
      'note': note,
      'createdDate': createdDate.toIso8601String(),
      'highlightColor': highlightColor,
    };
  }

  factory BookmarkModel.fromMap(Map<String, dynamic> map) {
    return BookmarkModel(
      id: map['id'] as String,
      documentId: map['documentId'] as String,
      pageNumber: map['pageNumber'] as int,
      title: map['title'] as String?,
      note: map['note'] as String?,
      createdDate: DateTime.parse(map['createdDate'] as String),
      highlightColor: map['highlightColor'] as String?,
    );
  }
}
