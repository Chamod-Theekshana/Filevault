import 'package:filevault/core/errors/failure.dart';
import 'package:filevault/core/errors/result.dart';
import 'package:filevault/data/services/file_system_service.dart';
import 'package:filevault/domain/models/file_entity.dart';
import 'package:filevault/domain/repositories/file_repository.dart';

class FileRepositoryImpl implements FileRepository {
  FileRepositoryImpl(this._service);
  
  final FileSystemService _service;

  @override
  Future<Result<List<FileEntity>>> listDirectory(String path, {bool showHidden = false}) async {
    try {
      final List<FileEntity> files = await _service.listDirectory(path, showHidden: showHidden);
      return Result<List<FileEntity>>.success(files);
    } catch (e) {
      return Result<List<FileEntity>>.failure(Failure(e.toString()));
    }
  }
}
