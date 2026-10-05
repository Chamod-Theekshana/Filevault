import 'dart:io';

import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

/// Pure helpers for classifying and naming files. No I/O, no Flutter.
abstract final class FileUtils {
  static const Set<String> imageExt = <String>{
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif', 'avif', 'svg',
    'tif', 'tiff', 'raw', 'dng', 'cr2', 'nef', 'ico',
  };
  static const Set<String> videoExt = <String>{
    'mp4', 'mkv', 'webm', 'mov', 'avi', '3gp', 'm4v', 'ts', 'flv', 'wmv', 'mts',
  };
  static const Set<String> audioExt = <String>{
    'mp3', 'm4a', 'aac', 'flac', 'wav', 'ogg', 'oga', 'opus', 'wma', 'amr',
    'mid', 'midi', 'aiff',
  };
  static const Set<String> documentExt = <String>{
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'odt', 'ods', 'odp',
    'txt', 'rtf', 'md', 'csv', 'epub', 'mobi', 'json', 'xml', 'html', 'htm',
    'log', 'ini', 'cfg', 'yaml', 'yml', 'toml', 'dart', 'kt', 'java', 'py',
    'js', 'ts', 'c', 'cpp', 'h', 'sh', 'sql', 'tex',
  };
  static const Set<String> archiveExt = <String>{
    'zip', 'rar', '7z', 'tar', 'gz', 'tgz', 'bz2', 'xz', 'jar', 'war',
  };
  static const Set<String> apkExt = <String>{'apk', 'apks', 'xapk', 'aab'};
  static const Set<String> textExt = <String>{
    'txt', 'md', 'csv', 'json', 'xml', 'html', 'htm', 'log', 'ini', 'cfg',
    'yaml', 'yml', 'toml', 'dart', 'kt', 'java', 'py', 'js', 'ts', 'c', 'cpp',
    'h', 'sh', 'sql', 'tex', 'properties', 'gradle', 'kts', 'conf', 'env',
    'srt', 'vtt', 'rtf',
  };

  static const String _invalidChars = r'[\\/:*?"<>|]';

  /// Lower-case extension without the dot. "archive.tar.gz" -> "gz".
  static String extensionOf(String name) {
    final String ext = p.extension(name);
    return ext.isEmpty ? '' : ext.substring(1).toLowerCase();
  }

  static FileCategory categoryFor(String name, {bool isDirectory = false}) {
    if (isDirectory) return FileCategory.folders;
    final String ext = extensionOf(name);
    if (imageExt.contains(ext)) return FileCategory.images;
    if (videoExt.contains(ext)) return FileCategory.videos;
    if (audioExt.contains(ext)) return FileCategory.audio;
    if (apkExt.contains(ext)) return FileCategory.apks;
    if (archiveExt.contains(ext)) return FileCategory.archives;
    if (documentExt.contains(ext)) return FileCategory.documents;
    final String? mime = lookupMimeType(name);
    if (mime != null) {
      if (mime.startsWith('image/')) return FileCategory.images;
      if (mime.startsWith('video/')) return FileCategory.videos;
      if (mime.startsWith('audio/')) return FileCategory.audio;
      if (mime.startsWith('text/')) return FileCategory.documents;
    }
    return FileCategory.other;
  }

  static String? mimeFor(String name) => lookupMimeType(name);

  static bool isTextLike(FileEntry entry) {
    if (entry.isDirectory) return false;
    if (textExt.contains(entry.extension)) return true;
    final String? mime = entry.mimeType;
    return mime != null && mime.startsWith('text/');
  }

  static bool isPdf(FileEntry entry) => entry.extension == 'pdf';

  /// Only formats the pure-Dart archive engine can read.
  static bool isReadableArchive(String name) {
    final String lower = name.toLowerCase();
    return lower.endsWith('.zip') ||
        lower.endsWith('.jar') ||
        lower.endsWith('.tar') ||
        lower.endsWith('.tar.gz') ||
        lower.endsWith('.tgz') ||
        lower.endsWith('.gz') ||
        lower.endsWith('.tar.bz2') ||
        lower.endsWith('.bz2') ||
        lower.endsWith('.tar.xz') ||
        lower.endsWith('.xz');
  }

  static bool isValidName(String name) {
    if (name.trim().isEmpty) return false;
    if (name == '.' || name == '..') return false;
    if (RegExp(_invalidChars).hasMatch(name)) return false;
    return name.length <= 255;
  }

  /// Builds a name that does not collide with existing entries, in the style
  /// "report (1).pdf", "report (2).pdf".
  static String uniqueName(String name, bool Function(String candidate) exists) {
    if (!exists(name)) return name;
    final String ext = p.extension(name);
    final String stem = ext.isEmpty ? name : name.substring(0, name.length - ext.length);
    for (int i = 1; i < 10000; i++) {
      final String candidate = '$stem ($i)$ext';
      if (!exists(candidate)) return candidate;
    }
    return '$stem-${DateTime.now().millisecondsSinceEpoch}$ext';
  }

  static String uniquePathSync(String path) {
    final String dir = p.dirname(path);
    final String name = p.basename(path);
    final String fresh = uniqueName(name, (String c) {
      final String candidate = p.join(dir, c);
      return File(candidate).existsSync() ||
          Directory(candidate).existsSync() ||
          Link(candidate).existsSync();
    });
    return p.join(dir, fresh);
  }

  /// True when [child] lives inside [parent] (or is the same path).
  static bool isWithin(String parent, String child) {
    final String a = p.normalize(parent);
    final String b = p.normalize(child);
    return b == a || p.isWithin(a, b);
  }

  /// Breadcrumb-friendly display name for a folder path.
  static String displayName(String path, {String primaryLabel = 'Internal storage'}) {
    if (path == '/storage/emulated/0' || path == '/sdcard') return primaryLabel;
    final String base = p.basename(path);
    return base.isEmpty ? path : base;
  }

  /// Short badge text for thumbnails: "PDF", "ZIP", "JPG".
  static String badge(FileEntry entry) {
    if (entry.isDirectory) return '';
    final String ext = entry.extension.toUpperCase();
    return ext.length > 4 ? ext.substring(0, 4) : ext;
  }

  /// Unix style permission string such as "-rw-r--r--".
  static String modeString(FileStat stat, {required bool isDirectory}) {
    final int mode = stat.mode;
    final StringBuffer out = StringBuffer(isDirectory ? 'd' : '-');
    const List<int> bits = <int>[256, 128, 64, 32, 16, 8, 4, 2, 1];
    const String chars = 'rwxrwxrwx';
    for (int i = 0; i < 9; i++) {
      out.write((mode & bits[i]) != 0 ? chars[i] : '-');
    }
    return out.toString();
  }
}
