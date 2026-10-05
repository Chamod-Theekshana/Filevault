import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/router/app_routes.dart';
import 'package:filevault/core/theme/app_colors.dart';
import 'package:filevault/core/theme/category_colors.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/domain/models/file_entity.dart';
import 'package:filevault/features/home/home_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key, required this.categories});

  final List<CategorySummary> categories;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(context.l10n.categoriesTitle, style: context.texts.headlineSmall),
            const Spacer(),
            Text(
              context.l10n.categoriesCount(categories.length),
              style: context.texts.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 64,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (BuildContext context, int index) {
            final CategorySummary item = categories[index];
            return _CategoryButton(summary: item);
          },
        ),
      ],
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({required this.summary});

  final CategorySummary summary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.isDark
          ? AppColors.darkSurfaceContainerLow
          : AppColors.lightSurfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (summary.category == FileCategory.trash) {
            context.push(AppRoutes.trash);
          } else if (summary.category == FileCategory.archives) {
            context.push(AppRoutes.archive);
          } else {
            context.go(AppRoutes.browse);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              FvCategoryTile(
                category: summary.category,
                icon: _icon(summary.category),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      _label(context, summary.category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.labelLarge,
                    ),
                    Text(
                      context.l10n.categoryCountSize(
                        '${summary.itemCount}',
                        FileSizeFormatter.format(summary.totalBytes),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _icon(FileCategory category) {
    return switch (category) {
      FileCategory.images => Icons.image_outlined,
      FileCategory.videos => Icons.videocam_outlined,
      FileCategory.audio => Icons.headphones_outlined,
      FileCategory.documents => Icons.description_outlined,
      FileCategory.downloads => Icons.download_outlined,
      FileCategory.apks => Icons.android_outlined,
      FileCategory.archives => Icons.folder_zip_outlined,
      FileCategory.trash => Icons.delete_outlined,
      FileCategory.folders => Icons.folder_outlined,
      FileCategory.other => Icons.insert_drive_file_outlined,
    };
  }

  String _label(BuildContext context, FileCategory category) {
    return switch (category) {
      FileCategory.images => context.l10n.categoryImages,
      FileCategory.videos => context.l10n.categoryVideos,
      FileCategory.audio => context.l10n.categoryAudio,
      FileCategory.documents => context.l10n.categoryDocuments,
      FileCategory.downloads => context.l10n.categoryDownloads,
      FileCategory.apks => context.l10n.categoryApks,
      FileCategory.archives => context.l10n.categoryArchives,
      FileCategory.trash => context.l10n.categoryTrash,
      FileCategory.folders => context.l10n.navBrowse,
      FileCategory.other => context.l10n.unknownValue,
    };
  }
}

class QuickAccessList extends StatelessWidget {
  const QuickAccessList({super.key, required this.items});

  final List<QuickAccessItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(context.l10n.quickAccess, style: context.texts.headlineSmall),
            const Spacer(),
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                tooltip: context.l10n.quickAccessMore,
                onPressed: () {},
                icon: const Icon(Icons.more_vert, size: 18),
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: context.isDark
                ? AppColors.darkSurfaceContainerLowest
                : AppColors.lightSurfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: context.isDark
                  ? AppColors.darkSurfaceContainer
                  : AppColors.lightSurfaceContainer,
            ),
            itemBuilder: (BuildContext context, int index) {
              final QuickAccessItem item = items[index];
              return SizedBox(
                height: 64,
                child: ListTile(
                  onTap: () => context.go(AppRoutes.browse),
                  leading: FvCategoryTile(
                    category: item.category,
                    icon: item.icon == 'camera'
                        ? Icons.photo_camera_outlined
                        : item.icon == 'chat'
                            ? Icons.chat_outlined
                            : item.icon == 'screenshot'
                                ? Icons.screenshot_outlined
                                : Icons.download_for_offline_outlined,
                  ),
                  title: Text(item.title, style: context.texts.labelLarge),
                  subtitle: Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
