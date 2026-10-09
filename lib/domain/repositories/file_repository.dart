import 'package:filevault/core/errors/result.dart';
import 'package:filevault/core/utils/isolate_worker.dart';
import 'package:filevault/domain/models/file_entry.dart';

enum HashAlgorithm { md5, sha256 }

/// Recursive totals for a folder.
class DirectoryStats {
  const DirectoryStats({required this.files, required this.folders, required this.bytes});

  final int files;
  final int folders;
  final int bytes;
}

/// Decoded text file with the encoding that was detected.
class TextDocument {
  const TextDocument({required this.content, required this.encoding, required this.bytes});

  final String content;
  final String encoding;
  final int bytes;
}

/// Everything the UI needs to read and write the real file system. The
/// implementation is the only place that touches `dart:io` for browsing.
abstract class FileRepository {
  /// Lists [path] lazily in batches. Throws a [Failure] inside the stream when
  /// the folder cannot be read.
  Stream<List<FileEntry>> listDirectory(String path, {required bool showHidden});

  Future<Result<FileEntry>> stat(String path);

  Future<bool> exists(String path);

  /// The subset of [paths] that still exists (one background pass).
  Future<Set<String>> existingPaths(List<String> paths);

  bool isRestricted(String path);

  Future<Result<FileEntry>> createFolder(String parentPath, String name);

  Future<Result<FileEntry>> createFile(String parentPath, String name);

  Future<Result<FileEntry>> rename(String path, String newName);

  Future<Result<FileEntry>> duplicate(String path);

  Future<Result<int>> countChildren(String path);

  /// Hides [folder] from galleries with a `.nomedia` marker (or shows it
  /// again). Returns the files whose media-index entries should be refreshed.
  Future<Result<List<String>>> setHiddenFromGallery(String folder, {required bool hidden});

  /// True when [folder] carries a `.nomedia` marker.
  bool isHiddenFromGallery(String folder);

  /// Direct-child counts for many folders in one pass (off the UI isolate).
  Future<Map<String, int>> childCounts(List<String> folders, {required bool showHidden});

  Future<Result<DirectoryStats>> directoryStats(String path, {CancelToken? cancelToken});

  Future<Result<String>> computeHash(
    String path,
    HashAlgorithm algorithm, {
    CancelToken? cancelToken,
    ProgressCallback? onProgress,
  });

  Future<Result<TextDocument>> readText(String path);

  Future<Result<void>> writeText(String path, String content, {String encoding = 'utf-8'});

  /// Lists only direct children that match a category – used by the virtual
  /// category folders when the index is empty.
  Future<Result<List<FileEntry>>> listRecursive(
    String root, {
    required bool showHidden,
    bool Function(FileEntry entry)? where,
    int limit = 5000,
    CancelToken? cancelToken,
  });
}
