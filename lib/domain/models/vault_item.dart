import 'package:filevault/domain/models/file_category.dart';

/// Metadata for a file stored encrypted inside the Secure Folder. The
/// encrypted blob lives in app-private storage under [storedName].
class VaultItem {
  const VaultItem({
    required this.id,
    required this.name,
    required this.originalPath,
    required this.storedName,
    required this.size,
    required this.category,
    required this.addedAt,
    this.mimeType,
  });

  final int id;
  final String name;
  final String originalPath;
  final String storedName;
  final int size;
  final FileCategory category;
  final DateTime addedAt;
  final String? mimeType;

  String get extension {
    final int dot = name.lastIndexOf('.');
    return dot <= 0 ? '' : name.substring(dot + 1).toLowerCase();
  }

  static VaultItem fromRow(Map<String, Object?> row) => VaultItem(
        id: (row['id'] as num).toInt(),
        name: row['name']! as String,
        originalPath: row['original_path']! as String,
        storedName: row['stored_name']! as String,
        size: (row['size'] as num?)?.toInt() ?? 0,
        category: FileCategory.fromName(row['category'] as String?),
        addedAt: DateTime.fromMillisecondsSinceEpoch(
            (row['added_at'] as num).toInt()),
        mimeType: row['mime_type'] as String?,
      );
}

/// Lock-state of the Secure Folder as seen by the UI.
enum VaultStatus { notConfigured, locked, unlocked }
