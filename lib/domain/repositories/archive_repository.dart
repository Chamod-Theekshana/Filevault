import 'package:filevault/core/errors/result.dart';
import 'package:filevault/core/utils/isolate_worker.dart';
import 'package:filevault/domain/models/archive_entry.dart';

/// Reading and writing archives without blocking the UI isolate.
abstract class ArchiveRepository {
  bool canOpen(String path);

  Future<Result<List<ArchiveEntryInfo>>> listEntries(String archivePath, {String? password});

  /// Extracts [entryPaths] (or everything when null) into [destinationDir].
  Future<Result<int>> extract(
    String archivePath,
    String destinationDir, {
    List<String>? entryPaths,
    String? password,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  });

  /// Creates an archive at [archivePath] from [sources].
  Future<Result<void>> create(
    String archivePath,
    List<String> sources, {
    ArchiveFormat format = ArchiveFormat.zip,
    int level = 6,
    String? password,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  });
}
