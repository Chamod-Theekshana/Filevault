import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/theme/category_colors.dart';
import 'package:filevault/core/utils/date_formatter.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/core/widgets/fv_thumbnail.dart';
import 'package:filevault/domain/models/category_summary.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

String categoryLabel(AppLocalizations l10n, FileCategory c) => switch (c) {
      FileCategory.images => l10n.categoryImages,
      FileCategory.videos => l10n.categoryVideos,
      FileCategory.audio => l10n.categoryAudio,
      FileCategory.documents => l10n.categoryDocuments,
      FileCategory.downloads => l10n.categoryDownloads,
      FileCategory.apks => l10n.categoryApks,
      FileCategory.archives => l10n.categoryArchives,
      FileCategory.trash => l10n.categoryTrash,
      FileCategory.folders => l10n.categoryFolders,
      FileCategory.other => l10n.categoryOther,
    };

/// 2-column grid of category tiles.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
    required this.categories,
    required this.trashCount,
    required this.trashBytes,
    required this.indexed,
    required this.onTap,
  });

  final List<CategorySummary> categories;
  final int trashCount;
  final int trashBytes;
  final bool indexed;
  final void Function(FileCategory category) onTap;

  CategorySummary _summary(FileCategory c) {
    if (c == FileCategory.trash) {
      return CategorySummary(category: c, itemCount: trashCount, totalBytes: trashBytes);
    }
    for (final CategorySummary s in categories) {
      if (s.category == c) return s;
    }
    return CategorySummary.empty(c);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: FileCategory.homeTiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (BuildContext context, int i) {
        final FileCategory c = FileCategory.homeTiles[i];
        final CategorySummary s = _summary(c);
        final bool unknown = !indexed && c != FileCategory.trash;
        return _CategoryTile(
          summary: s,
          unknown: unknown,
          onTap: () => onTap(c),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.summary, required this.unknown, required this.onTap});

  final CategorySummary summary;
  final bool unknown;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.isDark ? context.colors.surfaceContainerLow : context.colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              FvCategoryTile(category: summary.category, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      categoryLabel(context.l10n, summary.category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unknown
                          ? '—'
                          : '${FileSizeFormatter.count(summary.itemCount)} • ${FileSizeFormatter.format(summary.totalBytes)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
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
}

/// Horizontally scrolling recent-file cards.
class RecentFilesRow extends StatelessWidget {
  const RecentFilesRow({super.key, required this.files, required this.onOpen});

  final List<FileEntry> files;
  final void Function(FileEntry entry) onOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 182,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: files.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int i) => _RecentCard(entry: files[i], onTap: () => onOpen(files[i])),
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.entry, required this.onTap});

  final FileEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool media = entry.isImage || entry.isVideo;
    return SizedBox(
      width: 156,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 118,
                decoration: BoxDecoration(
                  color: context.isDark ? context.colors.surfaceContainerLow : context.colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.tokens.cardBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: media
                    ? FvThumbnail(entry: entry, size: 156, radius: 0, showBadge: false, fit: BoxFit.cover)
                    : Center(
                        child: FvCategoryTile(
                          category: entry.category,
                          icon: CategoryColors.icon(entry.category),
                          size: 56,
                          radius: 16,
                          iconSize: 28,
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.titleSmall,
              ),
              Text(
                '${DateFormatter.short(entry.modified)} • ${FileSizeFormatter.format(entry.size)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grouped list of quick-access folders.
class QuickAccessList extends StatelessWidget {
  const QuickAccessList({super.key, required this.items, required this.onOpen});

  final List<QuickAccessEntry> items;
  final void Function(QuickAccessEntry entry) onOpen;

  @override
  Widget build(BuildContext context) {
    return FvCard(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < items.length; i++)
            _QuickRow(entry: items[i], last: i == items.length - 1, onTap: () => onOpen(items[i])),
        ],
      ),
    );
  }
}

class _QuickRow extends StatelessWidget {
  const _QuickRow({required this.entry, required this.last, required this.onTap});

  final QuickAccessEntry entry;
  final bool last;
  final VoidCallback onTap;

  IconData get _icon => switch (entry.id) {
        'downloads' => Icons.download_outlined,
        'camera' => Icons.photo_camera_outlined,
        'whatsapp' => Icons.chat_outlined,
        'screenshots' => Icons.screenshot_outlined,
        'documents' => Icons.description_outlined,
        'telegram' => Icons.send_outlined,
        _ => Icons.folder_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: last
          ? null
          : BoxDecoration(border: Border(bottom: BorderSide(color: context.tokens.cardBorder))),
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              FvCategoryTile(category: entry.category, icon: _icon, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.texts.titleSmall,
                          ),
                        ),
                        if (entry.itemCount > 0) ...<Widget>[
                          const SizedBox(width: 8),
                          FvCountBadge(FileSizeFormatter.count(entry.itemCount)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Secure Folder entry point shown on the home screen.
class SecureFolderCard extends StatelessWidget {
  const SecureFolderCard({
    super.key,
    required this.itemCount,
    required this.configured,
    required this.onTap,
  });

  final int itemCount;
  final bool configured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      color: context.colors.primaryContainer,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.colors.onPrimary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.lock_outline, color: context.colors.onPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.l10n.secureFolder,
                      style: context.texts.titleMedium?.copyWith(color: context.colors.onPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      configured
                          ? '${context.l10n.itemCount(itemCount)} • ${context.l10n.vaultSubtitle}'
                          : context.l10n.vaultNotSetUp,
                      style: context.texts.bodySmall?.copyWith(
                        color: context.colors.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.colors.onPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
