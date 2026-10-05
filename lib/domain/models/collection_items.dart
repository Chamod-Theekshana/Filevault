import 'package:filevault/domain/models/file_category.dart';

/// A bookmarked file or folder.
class FavoriteItem {
  const FavoriteItem({
    required this.id,
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.addedAt,
  });

  final int id;
  final String path;
  final String name;
  final bool isDirectory;
  final DateTime addedAt;

  static FavoriteItem fromRow(Map<String, Object?> row) => FavoriteItem(
        id: (row['id'] as num).toInt(),
        path: row['path']! as String,
        name: row['name']! as String,
        isDirectory: (row['is_directory'] as num?) == 1,
        addedAt: DateTime.fromMillisecondsSinceEpoch(
            (row['added_at'] as num).toInt()),
      );
}

/// A file the user opened recently.
class RecentItem {
  const RecentItem({
    required this.id,
    required this.path,
    required this.name,
    required this.openedAt,
    required this.category,
    this.mimeType,
    this.size = 0,
  });

  final int id;
  final String path;
  final String name;
  final DateTime openedAt;
  final FileCategory category;
  final String? mimeType;
  final int size;

  static RecentItem fromRow(Map<String, Object?> row) => RecentItem(
        id: (row['id'] as num).toInt(),
        path: row['path']! as String,
        name: row['name']! as String,
        openedAt: DateTime.fromMillisecondsSinceEpoch(
            (row['opened_at'] as num).toInt()),
        category: FileCategory.fromName(row['category'] as String?),
        mimeType: row['mime_type'] as String?,
        size: (row['size'] as num?)?.toInt() ?? 0,
      );
}

/// A coloured label that can be attached to any number of files.
class Tag {
  const Tag({required this.id, required this.name, required this.colorArgb});

  final int id;
  final String name;
  final int colorArgb;

  static const List<int> palette = <int>[
    0xFF0B6E99,
    0xFF7C3AED,
    0xFFE11D48,
    0xFFEA580C,
    0xFF16A34A,
    0xFFCA8A04,
    0xFF2563EB,
    0xFF64748B,
  ];

  static Tag fromRow(Map<String, Object?> row) => Tag(
        id: (row['id'] as num).toInt(),
        name: row['name']! as String,
        colorArgb: (row['color'] as num?)?.toInt() ?? palette.first,
      );
}
