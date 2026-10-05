import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/data/database/app_database.dart';
import 'package:filevault/domain/models/collection_items.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/models/file_operation.dart';
import 'package:filevault/domain/repositories/collections_repository.dart';
import 'package:sqflite/sqflite.dart';

class CollectionsRepositoryImpl implements CollectionsRepository {
  const CollectionsRepositoryImpl(this._db);

  final AppDatabase _db;

  Database get _sql => _db.db;

  // ------------------------------------------------------------ favorites

  @override
  Future<List<FavoriteItem>> favorites() async {
    final List<Map<String, Object?>> rows =
        await _sql.query('favorites', orderBy: 'added_at DESC');
    return rows.map(FavoriteItem.fromRow).toList(growable: false);
  }

  @override
  Future<bool> isFavorite(String path) async {
    final List<Map<String, Object?>> rows = await _sql.query(
      'favorites',
      columns: <String>['id'],
      where: 'path = ?',
      whereArgs: <Object?>[path],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  @override
  Future<void> addFavorite(FileEntry entry) async {
    await _sql.insert(
      'favorites',
      <String, Object?>{
        'path': entry.path,
        'name': entry.name,
        'is_directory': entry.isDirectory ? 1 : 0,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> removeFavorite(String path) async {
    await _sql.delete('favorites', where: 'path = ?', whereArgs: <Object?>[path]);
  }

  // -------------------------------------------------------------- recents

  @override
  Future<List<RecentItem>> recents({int limit = AppConstants.maxRecentFiles}) async {
    final List<Map<String, Object?>> rows =
        await _sql.query('recent_files', orderBy: 'opened_at DESC', limit: limit);
    return rows.map(RecentItem.fromRow).toList(growable: false);
  }

  @override
  Future<void> recordOpened(FileEntry entry) async {
    await _sql.insert(
      'recent_files',
      <String, Object?>{
        'path': entry.path,
        'name': entry.name,
        'mime_type': entry.mimeType,
        'category': entry.category.name,
        'size': entry.size,
        'opened_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Keep the table small.
    await _sql.rawDelete(
      'DELETE FROM recent_files WHERE id NOT IN '
      '(SELECT id FROM recent_files ORDER BY opened_at DESC LIMIT ?)',
      <Object?>[AppConstants.maxRecentFiles * 2],
    );
  }

  @override
  Future<void> clearRecents() => _sql.delete('recent_files');

  // ----------------------------------------------------------------- tags

  @override
  Future<List<Tag>> tags() async {
    final List<Map<String, Object?>> rows = await _sql.query('tags', orderBy: 'name ASC');
    return rows.map(Tag.fromRow).toList(growable: false);
  }

  @override
  Future<Tag> createTag(String name, int colorArgb) async {
    final int id = await _sql.insert(
      'tags',
      <String, Object?>{'name': name.trim(), 'color': colorArgb},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return Tag(id: id, name: name.trim(), colorArgb: colorArgb);
  }

  @override
  Future<void> updateTag(Tag tag) async {
    await _sql.update(
      'tags',
      <String, Object?>{'name': tag.name, 'color': tag.colorArgb},
      where: 'id = ?',
      whereArgs: <Object?>[tag.id],
    );
  }

  @override
  Future<void> deleteTag(int tagId) async {
    await _sql.delete('tags', where: 'id = ?', whereArgs: <Object?>[tagId]);
  }

  @override
  Future<List<Tag>> tagsFor(String path) async {
    final List<Map<String, Object?>> rows = await _sql.rawQuery(
      'SELECT t.id, t.name, t.color FROM tags t '
      'JOIN file_tags ft ON ft.tag_id = t.id WHERE ft.file_path = ? ORDER BY t.name',
      <Object?>[path],
    );
    return rows.map(Tag.fromRow).toList(growable: false);
  }

  @override
  Future<void> setTagsFor(String path, List<int> tagIds) async {
    await _sql.transaction((Transaction txn) async {
      await txn.delete('file_tags', where: 'file_path = ?', whereArgs: <Object?>[path]);
      for (final int id in tagIds) {
        await txn.insert(
          'file_tags',
          <String, Object?>{'file_path': path, 'tag_id': id},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }

  @override
  Future<List<String>> pathsWithTag(int tagId) async {
    final List<Map<String, Object?>> rows = await _sql.query(
      'file_tags',
      columns: <String>['file_path'],
      where: 'tag_id = ?',
      whereArgs: <Object?>[tagId],
    );
    return rows.map((Map<String, Object?> r) => r['file_path']! as String).toList();
  }

  @override
  Future<Map<int, int>> tagCounts() async {
    final List<Map<String, Object?>> rows = await _sql.rawQuery(
        'SELECT tag_id, COUNT(*) AS n FROM file_tags GROUP BY tag_id');
    return <int, int>{
      for (final Map<String, Object?> r in rows)
        (r['tag_id'] as num).toInt(): (r['n'] as num).toInt(),
    };
  }

  // ------------------------------------------------------------- history

  @override
  Future<List<OperationRecord>> operationHistory({int limit = 100}) async {
    final List<Map<String, Object?>> rows =
        await _sql.query('operation_history', orderBy: 'created_at DESC', limit: limit);
    return rows.map(OperationRecord.fromRow).toList(growable: false);
  }

  @override
  Future<void> recordOperation(FileOperation operation) async {
    await _sql.insert('operation_history', <String, Object?>{
      'type': operation.type.name,
      'source': operation.sources.isEmpty ? '' : operation.sources.first,
      'destination': operation.destination,
      'status': operation.status.name,
      'file_count': operation.totalFiles,
      'total_bytes': operation.totalBytes,
      'created_at': operation.createdAt.millisecondsSinceEpoch,
      'finished_at': operation.finishedAt?.millisecondsSinceEpoch,
      'error_message': operation.errorMessage,
    });
    await _sql.rawDelete(
      'DELETE FROM operation_history WHERE id NOT IN '
      '(SELECT id FROM operation_history ORDER BY created_at DESC LIMIT 200)',
    );
  }

  @override
  Future<void> clearOperationHistory() => _sql.delete('operation_history');

  // ---------------------------------------------------------- bookkeeping

  /// Escapes `%` and `_` so a literal file name is not read as a pattern.
  static String _likeEscape(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');

  @override
  Future<void> pathMoved(String oldPath, String newPath) async {
    final String prefix = '$oldPath/';
    // SQLite's substr() counts characters, not UTF-16 code units, so the
    // offset must be computed from runes for paths with astral characters.
    final int substrOffset = prefix.runes.length + 1;
    final String likePrefix = '${_likeEscape(oldPath)}/%';
    await _sql.transaction((Transaction txn) async {
      for (final String table in <String>['favorites', 'recent_files']) {
        await txn.update(table, <String, Object?>{'path': newPath},
            where: 'path = ?', whereArgs: <Object?>[oldPath]);
        await txn.rawUpdate(
          "UPDATE OR IGNORE $table SET path = ? || substr(path, ?) "
          "WHERE path LIKE ? ESCAPE '\\'",
          <Object?>['$newPath/', substrOffset, likePrefix],
        );
      }
      await txn.update('file_tags', <String, Object?>{'file_path': newPath},
          where: 'file_path = ?', whereArgs: <Object?>[oldPath]);
      await txn.rawUpdate(
        "UPDATE OR IGNORE file_tags SET file_path = ? || substr(file_path, ?) "
        "WHERE file_path LIKE ? ESCAPE '\\'",
        <Object?>['$newPath/', substrOffset, likePrefix],
      );
    });
  }

  @override
  Future<void> pathDeleted(String path) async {
    final String prefix = '${_likeEscape(path)}/%';
    await _sql.transaction((Transaction txn) async {
      for (final String table in <String>['favorites', 'recent_files']) {
        await txn.delete(table,
            where: "path = ? OR path LIKE ? ESCAPE '\\'",
            whereArgs: <Object?>[path, prefix]);
      }
      await txn.delete('file_tags',
          where: "file_path = ? OR file_path LIKE ? ESCAPE '\\'",
          whereArgs: <Object?>[path, prefix]);
    });
  }
}
