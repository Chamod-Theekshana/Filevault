import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/core/utils/isolate_worker.dart';
import 'package:filevault/domain/models/analyzer_models.dart';
import 'package:filevault/domain/models/file_entry.dart';

/// Storage analysis tools. Heavy scanning runs in worker isolates.
abstract class AnalyzerRepository {
  Future<StorageBreakdown> breakdown({
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  });

  Future<List<FileEntry>> largeFiles({
    int minBytes = AppConstants.largeFileThresholdBytes,
    int limit = 200,
  });

  /// Groups by size first, then hashes only candidates. Hashes are cached in
  /// the database keyed by path + size + mtime.
  Future<List<DuplicateGroup>> findDuplicates({
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  });

  Future<JunkReport> scanJunk({
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  });

  /// Deletes the given junk items permanently. Returns bytes freed.
  Future<int> deleteJunk(List<JunkItem> items);
}
