import 'package:filevault/core/errors/result.dart';
import 'package:filevault/core/utils/isolate_worker.dart';
import 'package:filevault/data/services/file_system_service.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/repositories/file_repository.dart';

class FileRepositoryImpl implements FileRepository {
  const FileRepositoryImpl(this._fs);

  final FileSystemService _fs;

  @override
  Stream<List<FileEntry>> listDirectory(String path, {required bool showHidden}) =>
      _fs.list(path, showHidden: showHidden);

  @override
  Future<Result<FileEntry>> stat(String path) => Result.guard(() => _fs.stat(path));

  @override
  Future<bool> exists(String path) => _fs.exists(path);

  @override
  bool isRestricted(String path) => _fs.isRestricted(path);

  @override
  Future<Result<FileEntry>> createFolder(String parentPath, String name) =>
      Result.guard(() => _fs.createFolder(parentPath, name));

  @override
  Future<Result<FileEntry>> createFile(String parentPath, String name) =>
      Result.guard(() => _fs.createFile(parentPath, name));

  @override
  Future<Result<FileEntry>> rename(String path, String newName) =>
      Result.guard(() => _fs.rename(path, newName));

  @override
  Future<Result<FileEntry>> duplicate(String path) =>
      Result.guard(() => _fs.duplicate(path));

  @override
  Future<Result<int>> countChildren(String path) =>
      Result.guard(() => _fs.countChildren(path));

  @override
  Future<Result<DirectoryStats>> directoryStats(String path, {CancelToken? cancelToken}) =>
      Result.guard(() => _fs.directoryStats(path, cancelToken: cancelToken));

  @override
  Future<Result<String>> computeHash(
    String path,
    HashAlgorithm algorithm, {
    CancelToken? cancelToken,
    ProgressCallback? onProgress,
  }) =>
      Result.guard(() => _fs.computeHash(path, algorithm,
          cancelToken: cancelToken, onProgress: onProgress));

  @override
  Future<Result<TextDocument>> readText(String path) =>
      Result.guard(() => _fs.readText(path));

  @override
  Future<Result<void>> writeText(String path, String content, {String encoding = 'utf-8'}) =>
      Result.guard(() => _fs.writeText(path, content, encoding: encoding));

  @override
  Future<Result<List<FileEntry>>> listRecursive(
    String root, {
    required bool showHidden,
    bool Function(FileEntry entry)? where,
    int limit = 5000,
    CancelToken? cancelToken,
  }) {
    return Result.guard(() async {
      final List<FileEntry> all = await _fs.walk(
        root,
        includeHidden: showHidden,
        limit: where == null ? limit : limit * 4,
        cancelToken: cancelToken,
      );
      if (where == null) return all;
      return all.where(where).take(limit).toList(growable: false);
    });
  }
}
