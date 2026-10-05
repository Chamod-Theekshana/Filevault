import 'package:filevault/core/theme/category_colors.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/domain/models/file_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_state.freezed.dart';

@freezed
class HomeState with _$HomeState {
  const HomeState._();

  const factory HomeState({
    @Default(false) bool isLoading,
    @Default(<StorageVolumeInfo>[]) List<StorageVolumeInfo> volumes,
    @Default(<CategorySummary>[]) List<CategorySummary> categories,
    @Default(<FileEntity>[]) List<FileEntity> recents,
    @Default(<QuickAccessItem>[]) List<QuickAccessItem> quickAccess,
  }) = _HomeState;

  StorageVolumeInfo? get primary =>
      volumes.where((StorageVolumeInfo v) => v.isPrimary).firstOrNull;

  StorageVolumeInfo? get removable =>
      volumes.where((StorageVolumeInfo v) => !v.isPrimary).firstOrNull;
}

class QuickAccessItem {
  const QuickAccessItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.category,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final int count;
  final FileCategory category;
  final String icon;
}

String categoryCountSize(CategorySummary summary) {
  return '${_formatCount(summary.itemCount)} • ${FileSizeFormatter.format(summary.totalBytes)}';
}

String _formatCount(int count) {
  if (count >= 1000) {
    return '${(count / 1000).toStringAsFixed(count >= 10000 ? 0 : 2).replaceAll('.00', '')}'
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
  return '$count';
}
