import 'package:filevault/domain/models/category_summary.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/models/storage_volume.dart';

/// Full picture of one volume: category totals, biggest folders and files.
class StorageBreakdown {
  const StorageBreakdown({
    required this.volume,
    required this.categories,
    required this.largestFolders,
    required this.largestFiles,
    required this.scannedFiles,
    required this.scannedBytes,
  });

  final StorageVolume volume;
  final List<CategorySummary> categories;
  final List<FolderSize> largestFolders;
  final List<FileEntry> largestFiles;
  final int scannedFiles;
  final int scannedBytes;

  /// Bytes used by the system / other apps that the scan could not see.
  int get unaccountedBytes {
    final int diff = volume.usedBytes - scannedBytes;
    return diff < 0 ? 0 : diff;
  }

  CategorySummary summaryOf(FileCategory c) => categories.firstWhere(
        (CategorySummary s) => s.category == c,
        orElse: () => CategorySummary.empty(c),
      );
}

class FolderSize {
  const FolderSize({required this.path, required this.name, required this.bytes, required this.fileCount});

  final String path;
  final String name;
  final int bytes;
  final int fileCount;
}

/// Files that share size and SHA-256.
class DuplicateGroup {
  const DuplicateGroup({required this.hash, required this.size, required this.files});

  final String hash;
  final int size;
  final List<FileEntry> files;

  int get wastedBytes => size * (files.length - 1);
}

enum JunkKind { cache, temp, log, thumbnail, emptyFolder }

class JunkItem {
  const JunkItem({
    required this.path,
    required this.name,
    required this.bytes,
    required this.kind,
    required this.isDirectory,
  });

  final String path;
  final String name;
  final int bytes;
  final JunkKind kind;
  final bool isDirectory;
}

class JunkReport {
  const JunkReport({required this.items});

  final List<JunkItem> items;

  int get totalBytes => items.fold(0, (int a, JunkItem b) => a + b.bytes);

  List<JunkItem> ofKind(JunkKind kind) =>
      items.where((JunkItem i) => i.kind == kind).toList(growable: false);

  List<JunkItem> get junkFiles =>
      items.where((JunkItem i) => i.kind != JunkKind.emptyFolder).toList(growable: false);

  List<JunkItem> get emptyFolders => ofKind(JunkKind.emptyFolder);
}
