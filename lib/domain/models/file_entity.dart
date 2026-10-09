import 'package:equatable/equatable.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_entity.freezed.dart';

/// Immutable file-system entry. The real filesystem remains source of truth.
@freezed
abstract class FileEntity with _$FileEntity {
  const FileEntity._();

  const factory FileEntity({
    required String path,
    required String name,
    required bool isDirectory,
    required int size,
    required DateTime modified,
    String? mimeType,
    String? extension,
    @Default(false) bool isHidden,
    @Default(FileCategory.other) FileCategory category,
  }) = _FileEntity;
}

class CategorySummary extends Equatable {
  const CategorySummary({
    required this.category,
    required this.itemCount,
    required this.totalBytes,
  });

  final FileCategory category;
  final int itemCount;
  final int totalBytes;

  @override
  List<Object?> get props => <Object?>[category, itemCount, totalBytes];
}

class StorageVolumeInfo extends Equatable {
  const StorageVolumeInfo({
    required this.id,
    required this.name,
    required this.path,
    required this.totalBytes,
    required this.usedBytes,
    required this.isPrimary,
    required this.kind,
  });

  final String id;
  final String name;
  final String path;
  final int totalBytes;
  final int usedBytes;
  final bool isPrimary;
  final StorageVolumeKind kind;

  double get usedFraction {
    if (totalBytes <= 0) {
      return 0;
    }
    return usedBytes / totalBytes;
  }

  @override
  List<Object?> get props =>
      <Object?>[id, name, path, totalBytes, usedBytes, isPrimary, kind];
}

enum StorageVolumeKind { internal, sdCard, usb }
