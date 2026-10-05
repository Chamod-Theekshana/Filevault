import 'package:filevault/core/constants/app_constants.dart';
import 'package:filevault/domain/models/collection_items.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/models/file_operation.dart';

/// Favorites, recent files, tags and operation history – the "organisation"
/// metadata the app keeps on top of the file system.
abstract class CollectionsRepository {
  // Favorites
  Future<List<FavoriteItem>> favorites();
  Future<bool> isFavorite(String path);
  Future<void> addFavorite(FileEntry entry);
  Future<void> removeFavorite(String path);

  // Recents
  Future<List<RecentItem>> recents({int limit = AppConstants.maxRecentFiles});
  Future<void> recordOpened(FileEntry entry);
  Future<void> clearRecents();

  // Tags
  Future<List<Tag>> tags();
  Future<Tag> createTag(String name, int colorArgb);
  Future<void> updateTag(Tag tag);
  Future<void> deleteTag(int tagId);
  Future<List<Tag>> tagsFor(String path);
  Future<void> setTagsFor(String path, List<int> tagIds);
  Future<List<String>> pathsWithTag(int tagId);
  Future<Map<int, int>> tagCounts();

  // Operation history
  Future<List<OperationRecord>> operationHistory({int limit = 100});
  Future<void> recordOperation(FileOperation operation);
  Future<void> clearOperationHistory();

  /// Keeps metadata in sync after a rename/move/delete.
  Future<void> pathMoved(String oldPath, String newPath);
  Future<void> pathDeleted(String path);
}
