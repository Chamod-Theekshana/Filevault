import 'package:filevault/core/errors/result.dart';
import 'package:filevault/core/utils/isolate_worker.dart';
import 'package:filevault/data/services/archive_service.dart';
import 'package:filevault/domain/models/archive_entry.dart';
import 'package:filevault/domain/repositories/archive_repository.dart';

class ArchiveRepositoryImpl implements ArchiveRepository {
  const ArchiveRepositoryImpl(this._service);

  final ArchiveService _service;

  @override
  bool canOpen(String path) => _service.canOpen(path);

  @override
  Future<Result<List<ArchiveEntryInfo>>> listEntries(String archivePath, {String? password}) =>
      Result.guard(() => _service.listEntries(archivePath, password: password));

  @override
  Future<Result<int>> extract(
    String archivePath,
    String destinationDir, {
    List<String>? entryPaths,
    String? password,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) =>
      Result.guard(() => _service.extract(
            archivePath,
            destinationDir,
            entryPaths: entryPaths,
            password: password,
            onProgress: onProgress,
            cancelToken: cancelToken,
          ));

  @override
  Future<Result<void>> create(
    String archivePath,
    List<String> sources, {
    ArchiveFormat format = ArchiveFormat.zip,
    int level = 6,
    String? password,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) =>
      Result.guard(() => _service.create(
            archivePath,
            sources,
            format: format,
            level: level,
            password: password,
            onProgress: onProgress,
            cancelToken: cancelToken,
          ));
}
