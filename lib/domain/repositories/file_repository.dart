import 'package:filevault/core/errors/result.dart';
import 'package:filevault/domain/models/file_entity.dart';

abstract class FileRepository {
  Future<Result<List<FileEntity>>> listDirectory(String path, {bool showHidden = false});
}
