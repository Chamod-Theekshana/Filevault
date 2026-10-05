import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/domain/models/storage_volume.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// Horizontal breadcrumb trail: "Internal storage › Download".
class BreadcrumbBar extends StatefulWidget {
  const BreadcrumbBar({
    super.key,
    required this.path,
    required this.volume,
    required this.onNavigate,
  });

  final String path;
  final StorageVolume? volume;
  final void Function(String path) onNavigate;

  @override
  State<BreadcrumbBar> createState() => _BreadcrumbBarState();
}

class _BreadcrumbBarState extends State<BreadcrumbBar> {
  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(BreadcrumbBar old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) _scrollToEnd();
  }

  @override
  void initState() {
    super.initState();
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.hasClients) return;
      _controller.animateTo(
        _controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String root = widget.volume?.path ?? '/';
    final String rootLabel = widget.volume?.name ?? context.l10n.internalStorage;
    final List<(String, String)> crumbs = <(String, String)>[(rootLabel, root)];
    if (widget.path != root && widget.path.startsWith(root)) {
      final String rel = p.relative(widget.path, from: root);
      if (rel.isNotEmpty && rel != '.') {
        String acc = root;
        for (final String segment in p.split(rel)) {
          acc = p.join(acc, segment);
          crumbs.add((segment, acc));
        }
      }
    } else if (widget.path != root) {
      crumbs
        ..clear()
        ..addAll(<(String, String)>[
          for (int i = 0; i < p.split(widget.path).length; i++)
            (
              p.split(widget.path)[i].isEmpty ? '/' : p.split(widget.path)[i],
              p.joinAll(p.split(widget.path).take(i + 1)),
            ),
        ]);
    }
    return SizedBox(
      height: 48,
      child: ListView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: crumbs.length,
        itemBuilder: (BuildContext context, int i) {
          final bool last = i == crumbs.length - 1;
          final (String label, String target) = crumbs[i];
          return Row(
            children: <Widget>[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(Icons.chevron_right, size: 16, color: context.colors.outline),
                ),
              Center(
                child: FvChip(
                  label: label,
                  icon: i == 0
                      ? (widget.volume?.isPrimary ?? true ? Icons.smartphone : Icons.sd_card_outlined)
                      : last
                          ? Icons.folder_open
                          : null,
                  selected: last,
                  dense: true,
                  onTap: last ? null : () => widget.onNavigate(target),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// "156 items · 4.1 GB free" strip with the volume usage bar.
class FolderStatsBar extends StatelessWidget {
  const FolderStatsBar({
    super.key,
    required this.itemCount,
    required this.volume,
    required this.onFilter,
    this.filterCount = 0,
  });

  final int itemCount;
  final StorageVolume? volume;
  final VoidCallback onFilter;
  final int filterCount;

  @override
  Widget build(BuildContext context) {
    final StorageVolume? v = volume;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: context.isDark ? context.colors.surfaceContainerLow : context.colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: context.isDark ? context.colors.primaryContainer : context.colors.primaryFixed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.donut_small_outlined, size: 18, color: context.colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        context.l10n.itemCount(itemCount),
                        style: context.texts.titleSmall?.copyWith(
                          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                        ),
                      ),
                      if (v != null)
                        Text(
                          context.l10n.freeIn(FileSizeFormatter.format(v.freeBytes), v.name),
                          style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FvChip(
                  label: context.l10n.filter,
                  icon: Icons.tune,
                  dense: true,
                  selected: filterCount > 0,
                  onTap: onFilter,
                ),
              ],
            ),
            if (v != null && v.totalBytes > 0) ...<Widget>[
              const SizedBox(height: 10),
              FvSegmentedBar(
                height: 8,
                segments: <(double, Color)>[
                  (v.usedFraction * 0.82, context.colors.primaryContainer),
                  (v.usedFraction * 0.18, context.tokens.amber),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
