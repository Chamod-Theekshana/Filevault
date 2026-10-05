import 'package:filevault/domain/models/file_category.dart';
import 'package:path/path.dart' as p;

/// Immutable snapshot of a file-system entry. The real file system is always
/// the source of truth – this is only what we last observed.
class FileEntry {
  const FileEntry({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.size,
    required this.modified,
    required this.category,
    this.mimeType,
    this.extension = '',
    this.isHidden = false,
    this.childCount,
  });

  final String path;
  final String name;
  final bool isDirectory;
  final int size;
  final DateTime modified;
  final FileCategory category;
  final String? mimeType;

  /// Lower-case extension without the dot, or an empty string.
  final String extension;
  final bool isHidden;

  /// Number of direct children for folders, if it has been counted.
  final int? childCount;

  String get parentPath => p.dirname(path);

  /// File name without its extension.
  String get stem =>
      isDirectory || extension.isEmpty ? name : p.basenameWithoutExtension(name);

  bool get isArchive => category == FileCategory.archives;
  bool get isApk => category == FileCategory.apks;
  bool get isImage => category == FileCategory.images;
  bool get isVideo => category == FileCategory.videos;
  bool get isAudio => category == FileCategory.audio;

  FileEntry copyWith({
    String? path,
    String? name,
    bool? isDirectory,
    int? size,
    DateTime? modified,
    FileCategory? category,
    String? mimeType,
    String? extension,
    bool? isHidden,
    int? childCount,
  }) {
    return FileEntry(
      path: path ?? this.path,
      name: name ?? this.name,
      isDirectory: isDirectory ?? this.isDirectory,
      size: size ?? this.size,
      modified: modified ?? this.modified,
      category: category ?? this.category,
      mimeType: mimeType ?? this.mimeType,
      extension: extension ?? this.extension,
      isHidden: isHidden ?? this.isHidden,
      childCount: childCount ?? this.childCount,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'path': path,
        'name': name,
        'isDirectory': isDirectory,
        'size': size,
        'modified': modified.millisecondsSinceEpoch,
        'category': category.name,
        'mimeType': mimeType,
        'extension': extension,
        'isHidden': isHidden,
        'childCount': childCount,
      };

  static FileEntry fromMap(Map<String, Object?> map) => FileEntry(
        path: map['path']! as String,
        name: map['name']! as String,
        isDirectory: map['isDirectory'] == true || map['isDirectory'] == 1,
        size: (map['size'] as num?)?.toInt() ?? 0,
        modified: DateTime.fromMillisecondsSinceEpoch(
            (map['modified'] as num?)?.toInt() ?? 0),
        category: FileCategory.fromName(map['category'] as String?),
        mimeType: map['mimeType'] as String?,
        extension: (map['extension'] as String?) ?? '',
        isHidden: map['isHidden'] == true || map['isHidden'] == 1,
        childCount: (map['childCount'] as num?)?.toInt(),
      );

  @override
  bool operator ==(Object other) =>
      other is FileEntry &&
      other.path == path &&
      other.size == size &&
      other.modified == modified &&
      other.isDirectory == isDirectory;

  @override
  int get hashCode => Object.hash(path, size, modified, isDirectory);

  @override
  String toString() => 'FileEntry($path)';
}
