import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_item.freezed.dart';

enum FileItemType { folder, image, video, audio, document, archive, apk, unknown }

@freezed
abstract class FileItem with _$FileItem {
  const factory FileItem({
    required String path,
    required String name,
    required int size,
    required DateTime modified,
    required FileItemType type,
    @Default(false) bool isHidden,
  }) = _FileItem;
  
  const FileItem._();
  
  bool get isDirectory => type == FileItemType.folder;
}

