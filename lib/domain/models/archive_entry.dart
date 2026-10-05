import 'package:filevault/domain/models/file_category.dart';

/// One entry inside an archive, as listed without extracting anything.
class ArchiveEntryInfo {
  const ArchiveEntryInfo({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.size,
    this.compressedSize,
    this.modified,
    this.isEncrypted = false,
  });

  /// Path inside the archive, '/' separated, no leading slash.
  final String path;
  final String name;
  final bool isDirectory;
  final int size;
  final int? compressedSize;
  final DateTime? modified;
  final bool isEncrypted;

  String get parentPath {
    final int slash = path.lastIndexOf('/');
    return slash < 0 ? '' : path.substring(0, slash);
  }

  FileCategory get category => isDirectory ? FileCategory.folders : _categoryOf(name);

  static FileCategory _categoryOf(String name) {
    final int dot = name.lastIndexOf('.');
    final String ext = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
    if (<String>{'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'svg'}.contains(ext)) {
      return FileCategory.images;
    }
    if (<String>{'mp4', 'mkv', 'webm', 'mov', 'avi', '3gp'}.contains(ext)) {
      return FileCategory.videos;
    }
    if (<String>{'mp3', 'm4a', 'aac', 'flac', 'wav', 'ogg', 'opus'}.contains(ext)) {
      return FileCategory.audio;
    }
    if (<String>{'zip', 'rar', '7z', 'tar', 'gz', 'tgz', 'bz2', 'xz'}.contains(ext)) {
      return FileCategory.archives;
    }
    if (ext == 'apk') return FileCategory.apks;
    if (ext.isNotEmpty) return FileCategory.documents;
    return FileCategory.other;
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'path': path,
        'name': name,
        'isDirectory': isDirectory,
        'size': size,
        'compressedSize': compressedSize,
        'modified': modified?.millisecondsSinceEpoch,
        'isEncrypted': isEncrypted,
      };

  static ArchiveEntryInfo fromMap(Map<String, Object?> m) => ArchiveEntryInfo(
        path: m['path']! as String,
        name: m['name']! as String,
        isDirectory: m['isDirectory'] == true,
        size: (m['size'] as num?)?.toInt() ?? 0,
        compressedSize: (m['compressedSize'] as num?)?.toInt(),
        modified: m['modified'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch((m['modified'] as num).toInt()),
        isEncrypted: m['isEncrypted'] == true,
      );
}

enum ArchiveFormat { zip, tarGz, tar }

extension ArchiveFormatX on ArchiveFormat {
  String get extension => switch (this) {
        ArchiveFormat.zip => 'zip',
        ArchiveFormat.tarGz => 'tar.gz',
        ArchiveFormat.tar => 'tar',
      };

  String get label => switch (this) {
        ArchiveFormat.zip => 'ZIP',
        ArchiveFormat.tarGz => 'TAR.GZ',
        ArchiveFormat.tar => 'TAR',
      };

  bool get supportsPassword => this == ArchiveFormat.zip;
}
