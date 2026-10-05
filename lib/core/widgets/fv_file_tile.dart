import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/utils/date_formatter.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/core/widgets/fv_thumbnail.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:flutter/material.dart';

/// Builds the "4.2 MB • Today, 09:15" meta line for an entry.
String entryMetaLine(BuildContext context, FileEntry entry, {bool withPath = false}) {
  final String date = DateFormatter.relative(
    entry.modified,
    today: context.l10n.today,
    yesterday: context.l10n.yesterday,
  );
  if (entry.isDirectory) {
    final int? n = entry.childCount;
    return n == null ? date : '${context.l10n.itemCount(n)}  •  $date';
  }
  final String size = FileSizeFormatter.format(entry.size);
  return withPath ? entry.parentPath : '$size  •  $date';
}

/// 64dp list row from the design: thumbnail, name, meta, overflow button.
class FvFileListTile extends StatelessWidget {
  const FvFileListTile({
    super.key,
    required this.entry,
    required this.onTap,
    this.onLongPress,
    this.onMore,
    this.selecting = false,
    this.selected = false,
    this.subtitle,
    this.trailingLabel,
    this.badges = const <Widget>[],
    this.showDivider = true,
  });

  final FileEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMore;
  final bool selecting;
  final bool selected;
  final String? subtitle;
  final Widget? trailingLabel;
  final List<Widget> badges;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final Color bg = selected
        ? (context.isDark
            ? context.colors.primaryContainer.withValues(alpha: 0.35)
            : context.colors.primaryFixed.withValues(alpha: 0.55))
        : Colors.transparent;
    return Semantics(
      selected: selected,
      label: entry.name,
      child: Material(
        color: bg,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            decoration: showDivider
                ? BoxDecoration(border: Border(bottom: BorderSide(color: context.tokens.cardBorder)))
                : null,
            padding: const EdgeInsets.only(left: 12, right: 4),
            child: Row(
              children: <Widget>[
                if (selecting) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 12, left: 4),
                    child: FvSelectCircle(selected: selected),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: FvThumbnail(entry: entry, size: 44),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              entry.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.texts.titleSmall,
                            ),
                          ),
                          for (final Widget b in badges) ...<Widget>[const SizedBox(width: 8), b],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle ?? entryMetaLine(context, entry),
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
                if (trailingLabel != null) ...<Widget>[const SizedBox(width: 8), trailingLabel!],
                if (onMore != null)
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      tooltip: context.l10n.more,
                      onPressed: onMore,
                      icon: const Icon(Icons.more_vert),
                      color: context.colors.onSurfaceVariant,
                    ),
                  )
                else
                  const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Square grid tile: media shows the thumbnail edge-to-edge, other files
/// show a category tile over a card.
class FvFileGridTile extends StatelessWidget {
  const FvFileGridTile({
    super.key,
    required this.entry,
    required this.onTap,
    this.onLongPress,
    this.selecting = false,
    this.selected = false,
    this.showName = true,
  });

  final FileEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selecting;
  final bool selected;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final bool media = entry.isImage || entry.isVideo;
    final Widget content = media
        ? _MediaTile(entry: entry, selected: selected, selecting: selecting, showName: showName)
        : _CardTile(entry: entry, selected: selected, selecting: selecting);
    return Semantics(
      selected: selected,
      label: entry.name,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? context.colors.primaryContainer : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.entry,
    required this.selected,
    required this.selecting,
    required this.showName,
  });

  final FileEntry entry;
  final bool selected;
  final bool selecting;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) => FvThumbnail(
              entry: entry,
              size: c.maxWidth,
              radius: 0,
              showBadge: false,
            ),
          ),
          if (showName)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 18, 8, 6),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Colors.transparent, Color(0xB3000000)],
                  ),
                ),
                child: Text(
                  selected ? context.l10n.selectedLabel : entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelMedium?.copyWith(color: Colors.white),
                ),
              ),
            ),
          if (selecting || selected)
            Positioned(
              left: 8,
              top: 8,
              child: FvSelectCircle(selected: selected, onDark: true),
            ),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.entry, required this.selected, required this.selecting});

  final FileEntry entry;
  final bool selected;
  final bool selecting;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected
            ? (context.isDark ? context.colors.primaryContainer.withValues(alpha: 0.35) : context.colors.primaryFixed.withValues(alpha: 0.5))
            : (context.isDark ? context.colors.surfaceContainerLow : context.colors.surfaceContainerLowest),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: context.tokens.cardBorder),
      ),
      padding: const EdgeInsets.all(10),
      child: Stack(
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Center(child: FvThumbnail(entry: entry, size: 56, radius: 14)),
              ),
              const SizedBox(height: 6),
              Text(
                entry.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: context.texts.labelMedium,
              ),
              const SizedBox(height: 2),
              Text(
                entry.isDirectory
                    ? (entry.childCount == null ? context.l10n.folder : context.l10n.itemCount(entry.childCount!))
                    : FileSizeFormatter.format(entry.size),
                style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
          if (selecting || selected)
            Positioned(left: 0, top: 0, child: FvSelectCircle(selected: selected)),
        ],
      ),
    );
  }
}
