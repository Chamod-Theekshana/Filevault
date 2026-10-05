import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// SQLite schema for FileVault. The file system is always the source of
/// truth – every table here is either an index/cache or user metadata
/// (favorites, tags, trash records, vault records).
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const int schemaVersion = 1;
  static AppDatabase? _instance;

  static Future<AppDatabase> open() async {
    final AppDatabase? existing = _instance;
    if (existing != null) return existing;
    final String dir = await getDatabasesPath();
    final Database db = await openDatabase(
      p.join(dir, 'filevault.db'),
      version: schemaVersion,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createSchema,
      onUpgrade: _upgradeSchema,
    );
    final AppDatabase created = AppDatabase._(db);
    _instance = created;
    return created;
  }

  static Future<void> _createSchema(Database db, int version) async {
    final Batch batch = db.batch();
    batch.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        is_directory INTEGER NOT NULL DEFAULT 0,
        added_at INTEGER NOT NULL
      )''');
    batch.execute('''
      CREATE TABLE recent_files (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        mime_type TEXT,
        category TEXT,
        size INTEGER NOT NULL DEFAULT 0,
        opened_at INTEGER NOT NULL
      )''');
    batch.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color INTEGER NOT NULL
      )''');
    batch.execute('''
      CREATE TABLE file_tags (
        file_path TEXT NOT NULL,
        tag_id INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
        PRIMARY KEY (file_path, tag_id)
      )''');
    batch.execute('''
      CREATE TABLE trash_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        original_path TEXT NOT NULL,
        trash_path TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        size INTEGER NOT NULL DEFAULT 0,
        is_directory INTEGER NOT NULL DEFAULT 0,
        deleted_at INTEGER NOT NULL,
        category TEXT
      )''');
    batch.execute('''
      CREATE TABLE file_index (
        path TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        name_lower TEXT NOT NULL,
        parent_path TEXT NOT NULL,
        size INTEGER NOT NULL DEFAULT 0,
        modified INTEGER NOT NULL DEFAULT 0,
        is_directory INTEGER NOT NULL DEFAULT 0,
        is_hidden INTEGER NOT NULL DEFAULT 0,
        mime_type TEXT,
        extension TEXT,
        category TEXT
      )''');
    batch.execute('CREATE INDEX idx_file_index_name ON file_index(name_lower)');
    batch.execute('CREATE INDEX idx_file_index_parent ON file_index(parent_path)');
    batch.execute('CREATE INDEX idx_file_index_category ON file_index(category)');
    batch.execute('CREATE INDEX idx_file_index_size ON file_index(size)');
    batch.execute('''
      CREATE TABLE hash_cache (
        path TEXT PRIMARY KEY,
        size INTEGER NOT NULL,
        modified INTEGER NOT NULL,
        sha256 TEXT NOT NULL
      )''');
    batch.execute('''
      CREATE TABLE operation_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        source TEXT NOT NULL,
        destination TEXT,
        status TEXT NOT NULL,
        file_count INTEGER NOT NULL DEFAULT 0,
        total_bytes INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        finished_at INTEGER,
        error_message TEXT
      )''');
    batch.execute('''
      CREATE TABLE vault_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        original_path TEXT NOT NULL,
        stored_name TEXT NOT NULL UNIQUE,
        size INTEGER NOT NULL DEFAULT 0,
        mime_type TEXT,
        category TEXT,
        added_at INTEGER NOT NULL
      )''');
    batch.execute('''
      CREATE TABLE search_history (
        query TEXT PRIMARY KEY,
        searched_at INTEGER NOT NULL
      )''');
    await batch.commit(noResult: true);
  }

  static Future<void> _upgradeSchema(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here, one `if (oldVersion < N)` block per version.
  }

  /// Drops cached data only (never user metadata).
  Future<void> clearCaches() async {
    await db.delete('file_index');
    await db.delete('hash_cache');
  }
}
