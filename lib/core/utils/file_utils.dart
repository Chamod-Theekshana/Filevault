import 'dart:math';
import '../../domain/models/file_item.dart';
import 'package:path/path.dart' as p;

class FileUtils {
  static String formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  static FileItemType getFileType(String path, bool isDirectory) {
    if (isDirectory) return FileItemType.folder;
    
    final ext = p.extension(path).toLowerCase();
    
    switch (ext) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
      case '.bmp':
        return FileItemType.image;
      case '.mp4':
      case '.mkv':
      case '.avi':
      case '.webm':
      case '.mov':
        return FileItemType.video;
      case '.mp3':
      case '.wav':
      case '.ogg':
      case '.flac':
      case '.m4a':
        return FileItemType.audio;
      case '.pdf':
      case '.doc':
      case '.docx':
      case '.txt':
      case '.xls':
      case '.xlsx':
      case '.ppt':
      case '.pptx':
        return FileItemType.document;
      case '.zip':
      case '.rar':
      case '.7z':
      case '.tar':
      case '.gz':
        return FileItemType.archive;
      case '.apk':
        return FileItemType.apk;
      default:
        return FileItemType.unknown;
    }
  }
}

