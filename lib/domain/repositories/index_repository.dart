import 'package:filevault/core/utils/isolate_worker.dart';
import 'package:filevault/domain/models/category_summary.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/models/search_models.dart';

/// The search index: a SQLite mirror of file metadata used for global
/// search, category tiles and the storage analyzer. The file system stays
/// the source of truth; the index is rebuilt by scanning.
abstract class IndexRepository {
  /// Walks every scan root and rebuilds the index. Progress is 0..1.
  Future<int> rebuild({
    required bool includeHidden,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  });

  Future<IndexStatus> status();

  Future<bool> get isEmpty;

  Future<List<SearchHit>> search(String query, SearchFilter filter, {int limit = 300});

  Future<List<CategorySummary>> categorySummaries();

  Future<List<FileEntry>> filesInCategory(
    FileCategory category, {
    int limit = 2000,
    int offset = 0,
    String? underPath,
  });

  Future<List<FileEntry>> largestFiles({int limit = 100, int minBytes = 0});

  Future<Map<String, int>> folderSizes({int limit = 12});

  Future<List<String>> recentSearches();
  Future<void> addRecentSearch(String query);
  Future<void> removeRecentSearch(String query);
  Future<void> clearRecentSearches();

  /// Incremental updates so the index stays fresh between scans.
  Future<void> upsertEntries(List<FileEntry> entries);
  Future<void> removePath(String path);
  Future<void> movePath(String oldPath, String newPath);
}
