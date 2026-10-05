import 'package:filevault/core/errors/result.dart';
import 'package:filevault/domain/models/trash_item.dart';

/// App-managed trash. Files are moved into a hidden folder on the same
/// volume and their original path is remembered in the database.
abstract class TrashRepository {
  Future<List<TrashItem>> items();

  Future<int> totalBytes();

  /// Moves [path] into trash. Returns the created record.
  Future<Result<TrashItem>> moveToTrash(String path);

  /// Restores an item to its original location (or Downloads when the
  /// original folder is gone). Returns the restored path.
  Future<Result<String>> restore(TrashItem item);

  Future<Result<void>> deletePermanently(TrashItem item);

  Future<Result<int>> emptyTrash();

  /// Removes everything older than [days]. Returns the number of purged items.
  Future<int> purgeExpired(int days);

  /// Trash folder for the volume that contains [path].
  String trashFolderFor(String path);
}
