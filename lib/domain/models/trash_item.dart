import 'package:filevault/domain/models/file_category.dart';

/// A file parked in the app-managed trash folder. The original location is
/// remembered so it can be restored.
class TrashItem {
  const TrashItem({
    required this.id,
    required this.originalPath,
    required this.trashPath,
    required this.name,
    required this.size,
    required this.isDirectory,
    required this.deletedAt,
    required this.category,
  });

  final int id;
  final String originalPath;
  final String trashPath;
  final String name;
  final int size;
  final bool isDirectory;
  final DateTime deletedAt;
  final FileCategory category;

  /// Days until automatic purge, or null when auto-clean is disabled.
  int? daysLeft(int autoCleanDays, {DateTime? now}) {
    if (autoCleanDays <= 0) return null;
    final DateTime expires = deletedAt.add(Duration(days: autoCleanDays));
    final int left = expires.difference(now ?? DateTime.now()).inDays;
    return left < 0 ? 0 : left;
  }

  bool isExpired(int autoCleanDays, {DateTime? now}) {
    if (autoCleanDays <= 0) return false;
    return (now ?? DateTime.now())
        .isAfter(deletedAt.add(Duration(days: autoCleanDays)));
  }

  Map<String, Object?> toRow() => <String, Object?>{
        'original_path': originalPath,
        'trash_path': trashPath,
        'name': name,
        'size': size,
        'is_directory': isDirectory ? 1 : 0,
        'deleted_at': deletedAt.millisecondsSinceEpoch,
        'category': category.name,
      };

  static TrashItem fromRow(Map<String, Object?> row) => TrashItem(
        id: (row['id'] as num).toInt(),
        originalPath: row['original_path']! as String,
        trashPath: row['trash_path']! as String,
        name: row['name']! as String,
        size: (row['size'] as num?)?.toInt() ?? 0,
        isDirectory: (row['is_directory'] as num?) == 1,
        deletedAt: DateTime.fromMillisecondsSinceEpoch(
            (row['deleted_at'] as num).toInt()),
        category: FileCategory.fromName(row['category'] as String?),
      );
}
