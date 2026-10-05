import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:filevault/domain/models/file_entity.dart';
import 'package:filevault/core/theme/category_colors.dart';

class FileSystemService {
  Future<List<FileEntity>> listDirectory(String path, {bool showHidden = false}) async {
    final Directory dir = Directory(path);
    if (!await dir.exists()) {
      return <FileEntity>[];
    }

    final List<FileEntity> files = <FileEntity>[];
    final Stream<FileSystemEntity> stream = dir.list(followLinks: false);

    await for (final FileSystemEntity entity in stream) {
      final String name = p.basename(entity.path);
      if (!showHidden && name.startsWith('.')) {
        continue;
      }

      final FileStat stat = await entity.stat();
      final bool isDir = stat.type == FileSystemEntityType.directory;
      final String? extension = isDir ? null : p.extension(name);
      final String? mime = isDir ? null : lookupMimeType(entity.path);
      final FileCategory category = _determineCategory(isDir, mime, extension);

      files.add(
        FileEntity(
          path: entity.path,
          name: name,
          isDirectory: isDir,
          size: stat.size,
          modified: stat.modified,
          mimeType: mime,
          extension: extension,
          isHidden: name.startsWith('.'),
          category: category,
        ),
      );
    }
    return files;
  }

  FileCategory _determineCategory(bool isDir, String? mime, String? ext) {
    if (isDir) {
      return FileCategory.downloads;
    }
    if (mime == null) {
      if (ext == '.apk') return FileCategory.apks;
      return FileCategory.other;
    }
    if (mime.startsWith('image/')) return FileCategory.images;
    if (mime.startsWith('video/')) return FileCategory.videos;
    if (mime.startsWith('audio/')) return FileCategory.audio;
    if (mime.startsWith('text/') || mime == 'application/pdf') {
      return FileCategory.documents;
    }
    if (ext == '.zip' || ext == '.tar' || ext == '.gz' || ext == '.rar' || ext == '.7z') {
      return FileCategory.archives;
    }
    return FileCategory.other;
  }
}
