import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:smart_reader/core/constants/app_constants.dart';
import 'package:smart_reader/models/document_model.dart';
import 'package:smart_reader/models/bookmark_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT,
        filePath TEXT NOT NULL,
        type INTEGER NOT NULL,
        totalPages INTEGER DEFAULT 0,
        currentPage INTEGER DEFAULT 0,
        status INTEGER DEFAULT 0,
        addedDate TEXT NOT NULL,
        lastOpenedDate TEXT NOT NULL,
        fileSize INTEGER DEFAULT 0,
        coverColor TEXT,
        description TEXT,
        readingProgress REAL DEFAULT 0.0,
        isFavorite INTEGER DEFAULT 0,
        tags TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE bookmarks (
        id TEXT PRIMARY KEY,
        documentId TEXT NOT NULL,
        pageNumber INTEGER NOT NULL,
        title TEXT,
        note TEXT,
        createdDate TEXT NOT NULL,
        highlightColor TEXT,
        FOREIGN KEY (documentId) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE reading_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        documentId TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT,
        pagesRead INTEGER DEFAULT 0,
        FOREIGN KEY (documentId) REFERENCES documents(id) ON DELETE CASCADE
      )
    ''');
  }

  // Document CRUD
  Future<int> insertDocument(DocumentModel doc) async {
    final db = await database;
    return await db.insert('documents', doc.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<DocumentModel>> getAllDocuments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('documents', orderBy: 'lastOpenedDate DESC');
    return maps.map((map) => DocumentModel.fromMap(map)).toList();
  }

  Future<List<DocumentModel>> getRecentDocuments({int limit = 5}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'documents',
      orderBy: 'lastOpenedDate DESC',
      limit: limit,
    );
    return maps.map((map) => DocumentModel.fromMap(map)).toList();
  }

  Future<List<DocumentModel>> getFavoriteDocuments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'documents',
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'lastOpenedDate DESC',
    );
    return maps.map((map) => DocumentModel.fromMap(map)).toList();
  }

  Future<List<DocumentModel>> searchDocuments(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'documents',
      where: 'title LIKE ? OR author LIKE ? OR tags LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'lastOpenedDate DESC',
    );
    return maps.map((map) => DocumentModel.fromMap(map)).toList();
  }

  Future<int> updateDocument(DocumentModel doc) async {
    final db = await database;
    return await db.update(
      'documents',
      doc.toMap(),
      where: 'id = ?',
      whereArgs: [doc.id],
    );
  }

  Future<int> deleteDocument(String id) async {
    final db = await database;
    return await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  // Bookmark CRUD
  Future<int> insertBookmark(BookmarkModel bookmark) async {
    final db = await database;
    return await db.insert('bookmarks', bookmark.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<BookmarkModel>> getBookmarksForDocument(String documentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookmarks',
      where: 'documentId = ?',
      whereArgs: [documentId],
      orderBy: 'pageNumber ASC',
    );
    return maps.map((map) => BookmarkModel.fromMap(map)).toList();
  }

  Future<List<BookmarkModel>> getAllBookmarks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('bookmarks', orderBy: 'createdDate DESC');
    return maps.map((map) => BookmarkModel.fromMap(map)).toList();
  }

  Future<int> deleteBookmark(String id) async {
    final db = await database;
    return await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  // Reading sessions
  Future<int> startReadingSession(String documentId) async {
    final db = await database;
    return await db.insert('reading_sessions', {
      'documentId': documentId,
      'startTime': DateTime.now().toIso8601String(),
      'pagesRead': 0,
    });
  }

  Future<void> endReadingSession(int sessionId, int pagesRead) async {
    final db = await database;
    await db.update(
      'reading_sessions',
      {
        'endTime': DateTime.now().toIso8601String(),
        'pagesRead': pagesRead,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  // Stats
  Future<Map<String, dynamic>> getReadingStats() async {
    final db = await database;

    final totalDocs = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM documents'));
    final completedDocs = Sqflite.firstIntValue(await db
        .rawQuery('SELECT COUNT(*) FROM documents WHERE status = 2'));
    final currentlyReading = Sqflite.firstIntValue(await db
        .rawQuery('SELECT COUNT(*) FROM documents WHERE status = 1'));
    final totalPages = Sqflite.firstIntValue(await db
        .rawQuery('SELECT SUM(currentPage) FROM documents'));

    return {
      'totalDocuments': totalDocs ?? 0,
      'completedDocuments': completedDocs ?? 0,
      'currentlyReading': currentlyReading ?? 0,
      'totalPagesRead': totalPages ?? 0,
    };
  }
}
