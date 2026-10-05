import 'dart:io';

import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/core/errors/failure.dart';
import 'package:filevault/core/errors/result.dart';
import 'package:filevault/core/utils/file_utils.dart';
import 'package:filevault/data/database/app_database.dart';
import 'package:filevault/data/services/file_system_service.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/models/trash_item.dart';
import 'package:filevault/domain/repositories/trash_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class TrashRepositoryImpl implements TrashRepository {
  TrashRepositoryImpl(this._db, this._fs, {required this.downloadsPath});

  final AppDatabase _db;
  final FileSystemService _fs;
  final String downloadsPath;

  @override
  String trashFolderFor(String path) {
    final List<String> parts = p.split(path);
    String root = AppConstants.primaryStoragePath;
    if (parts.length >= 3 && parts[1] == 'storage') {
      root = parts[2] == 'emulated' && parts.length >= 4
          ? p.joinAll(parts.take(4))
          : p.joinAll(parts.take(3));
    }
    return p.join(root, AppConstants.trashFolderName);
  }

  @override
  Future<List<TrashItem>> items() async {
    final List<Map<String, Object?>> rows =
        await _db.db.query('trash_items', orderBy: 'deleted_at DESC');
    final List<TrashItem> out = <TrashItem>[];
    for (final Map<String, Object?> row in rows) {
      final TrashItem item = TrashItem.fromRow(row);
      // Drop records whose file vanished (e.g. SD card removed / wiped).
      if (_fs.existsSync(item.trashPath)) {
        out.add(item);
      } else {
        await _db.db.delete('trash_items', where: 'id = ?', whereArgs: <Object?>[item.id]);
      }
    }
    return out;
  }

  @override
  Future<int> totalBytes() async {
    final List<Map<String, Object?>> rows =
        await _db.db.rawQuery('SELECT COALESCE(SUM(size), 0) AS total FROM trash_items');
    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<Result<TrashItem>> moveToTrash(String path) {
    return Result.guard(() async {
      final FileEntry entry = await _fs.stat(path);
      final Directory trashDir = Directory(trashFolderFor(path));
      await trashDir.create(recursive: true);
      final File marker = File(p.join(trashDir.path, '.nomedia'));
      if (!await marker.exists()) await marker.create();

      final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
      // uniquePathSync keeps two files trashed in the same millisecond from
      // colliding (the trash_path column is UNIQUE).
      final String target =
          FileUtils.uniquePathSync(p.join(trashDir.path, '$stamp-${entry.name}'));
      int size = entry.size;
      if (entry.isDirectory) {
        size = (await _fs.directoryStats(path)).bytes;
      }
      final bool renamed = await _fs.tryRename(path, target);
      if (!renamed) {
        // Different volume: copy then delete.
        if (entry.isDirectory) {
          await _fs.copyDirectory(path, target);
        } else {
          await _fs.copyFile(path, target);
        }
        await _fs.deleteEntity(path);
      }
      final TrashItem item = TrashItem(
        id: 0,
        originalPath: path,
        trashPath: target,
        name: entry.name,
        size: size,
        isDirectory: entry.isDirectory,
        deletedAt: DateTime.now(),
        category: entry.category,
      );
      final int id = await _db.db.insert(
        'trash_items',
        item.toRow(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return TrashItem(
        id: id,
        originalPath: item.originalPath,
        trashPath: item.trashPath,
        name: item.name,
        size: item.size,
        isDirectory: item.isDirectory,
        deletedAt: item.deletedAt,
        category: item.category,
      );
    });
  }

  @override
  Future<Result<String>> restore(TrashItem item) {
    return Result.guard(() async {
      if (!_fs.existsSync(item.trashPath)) {
        await _db.db.delete('trash_items', where: 'id = ?', whereArgs: <Object?>[item.id]);
        throw NotFoundFailure(path: item.trashPath);
      }
      String targetDir = p.dirname(item.originalPath);
      if (!Directory(targetDir).existsSync()) {
        targetDir = downloadsPath;
        await Directory(targetDir).create(recursive: true);
      }
      final String target = FileUtils.uniquePathSync(p.join(targetDir, item.name));
      final bool renamed = await _fs.tryRename(item.trashPath, target);
      if (!renamed) {
        if (item.isDirectory) {
          await _fs.copyDirectory(item.trashPath, target);
        } else {
          await _fs.copyFile(item.trashPath, target);
        }
        await _fs.deleteEntity(item.trashPath);
      }
      await _db.db.delete('trash_items', where: 'id = ?', whereArgs: <Object?>[item.id]);
      return target;
    });
  }

  @override
  Future<Result<void>> deletePermanently(TrashItem item) {
    return Result.guard(() async {
      await _fs.deleteEntity(item.trashPath);
      await _db.db.delete('trash_items', where: 'id = ?', whereArgs: <Object?>[item.id]);
    });
  }

  @override
  Future<Result<int>> emptyTrash() {
    return Result.guard(() async {
      final List<TrashItem> all = await items();
      int removed = 0;
      for (final TrashItem item in all) {
        try {
          await _fs.deleteEntity(item.trashPath);
          removed++;
        } catch (_) {}
        await _db.db.delete('trash_items', where: 'id = ?', whereArgs: <Object?>[item.id]);
      }
      return removed;
    });
  }

  @override
  Future<int> purgeExpired(int days) async {
    if (days <= 0) return 0;
    final List<TrashItem> all = await items();
    int purged = 0;
    for (final TrashItem item in all) {
      if (!item.isExpired(days)) continue;
      try {
        await _fs.deleteEntity(item.trashPath);
      } catch (_) {}
      await _db.db.delete('trash_items', where: 'id = ?', whereArgs: <Object?>[item.id]);
      purged++;
    }
    return purged;
  }
}
