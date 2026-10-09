import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/theme/category_colors.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/domain/models/category_summary.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/storage_volume.dart';
import 'package:filevault/features/home/widgets/home_sections.dart';
import 'package:flutter/material.dart';

/// Home storage summary.
///
/// Leads with the number people actually care about ("38.4 GB free"), then a
/// single bar that shows *what* fills the phone, broken down by category once
/// the index exists. The removable volume (SD card / USB) sits in the corner
/// as a compact chip instead of a second card.
class StorageOverviewCard extends StatelessWidget {
  const StorageOverviewCard({
    super.key,
    required this.primary,
    required this.removable,
    required this.categories,
    required this.indexed,
    required this.onCleanUp,
    required this.onAnalyze,
    required this.onOpenVolume,
  });

  final StorageVolume primary;
  final StorageVolume? removable;
  final List<CategorySummary> categories;
  final bool indexed;
  final VoidCallback onCleanUp;
  final VoidCallback onAnalyze;
  final void Function(StorageVolume volume) onOpenVolume;

  static const List<FileCategory> _barCategories = <FileCategory>[
    FileCategory.images,
    FileCategory.videos,
    FileCategory.audio,
    FileCategory.documents,
    FileCategory.apks,
    FileCategory.archives,
  ];

  List<_Segment> _segments(BuildContext context) {
    final Brightness b = Theme.of(context).brightness;
    final int total = primary.totalBytes;
    if (total <= 0) return const <_Segment>[];
    final int used = primary.usedBytes;
    if (!indexed) {
      return <_Segment>[
        _Segment(null, used / total, context.colors.primaryContainer, used),
      ];
    }
    final List<_Segment> out = <_Segment>[];
    int known = 0;
    for (final FileCategory c in _barCategories) {
      int bytes = 0;
      for (final CategorySummary s in categories) {
        if (s.category == c) bytes = s.totalBytes;
      }
      if (bytes <= 0) continue;
      // The index can lag behind reality; never draw more than is used.
      if (known + bytes > used) bytes = (used - known).clamp(0, used);
      known += bytes;
      out.add(_Segment(c, bytes / total, CategoryColors.ink(b, c), bytes));
    }
    final int other = used - known;
    if (other > 0) {
      out.add(_Segment(
        FileCategory.other,
        other / total,
        context.isDark ? context.colors.outline : context.colors.outlineVariant,
        other,
      ));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final StorageVolume? sd = removable;
    final bool ready = primary.totalBytes > 0;
    final List<_Segment> segments = _segments(context);
    final List<_Segment> legend = List<_Segment>.of(segments)
      ..sort((_Segment a, _Segment b) => b.bytes.compareTo(a.bytes));
    return FvCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.smartphone_outlined, size: 16, color: context.colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  primary.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelLarge?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ),
              if (sd != null) _VolumeChip(volume: sd, onTap: () => onOpenVolume(sd)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ready ? context.l10n.freeAmount(FileSizeFormatter.format(primary.freeBytes)) : context.l10n.loading,
            style: context.texts.displaySmall?.copyWith(
              fontSize: 30,
              height: 1.1,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          if (ready)
            Text(
              context.l10n.ofTotalUsed(FileSizeFormatter.format(primary.totalBytes), primary.usedPercent),
              style: context.texts.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          const SizedBox(height: 14),
          _UsageBar(segments: segments),
          if (indexed && legend.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: <Widget>[
                for (final _Segment s in legend.take(4))
                  _LegendDot(
                    color: s.color,
                    label: s.category == null
                        ? context.l10n.used
                        : categoryLabel(context.l10n, s.category!),
                    value: FileSizeFormatter.format(s.bytes),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Flexible(child: _CleanUpButton(onPressed: onCleanUp)),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onAnalyze,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(context.l10n.storageDetails),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segment {
  const _Segment(this.category, this.fraction, this.color, this.bytes);

  final FileCategory? category;
  final double fraction;
  final Color color;
  final int bytes;
}

class _UsageBar extends StatelessWidget {
  const _UsageBar({required this.segments});

  final List<_Segment> segments;

  @override
  Widget build(BuildContext context) {
    final double used = segments.fold<double>(0, (double a, _Segment s) => a + s.fraction).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10,
        child: ColoredBox(
          color: context.isDark ? context.colors.surfaceContainerHighest : context.colors.surfaceContainer,
          child: Row(
            children: <Widget>[
              for (int i = 0; i < segments.length; i++)
                if (segments[i].fraction > 0)
                  Expanded(
                    flex: (segments[i].fraction * 10000).round().clamp(1, 10000),
                    child: Container(
                      margin: EdgeInsets.only(right: i == segments.length - 1 ? 0 : 1.5),
                      color: segments[i].color,
                    ),
                  ),
              if (used < 1)
                Expanded(
                  flex: ((1 - used) * 10000).round().clamp(1, 10000),
                  child: const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ',
          style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
        ),
        Text(
          value,
          style: context.texts.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _CleanUpButton extends StatelessWidget {
  const _CleanUpButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.isDark ? Colors.white : context.colors.onSecondaryContainer;
    return Material(
      color: context.isDark
          ? context.tokens.amber.withValues(alpha: 0.22)
          : context.colors.secondaryContainer,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.cleaning_services_outlined, size: 18, color: ink),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  context.l10n.cleanUp,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelLarge?.copyWith(color: ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VolumeChip extends StatelessWidget {
  const _VolumeChip({required this.volume, required this.onTap});

  final StorageVolume volume;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.tokens.chipFill,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                volume.kind == StorageVolumeKind.usb ? Icons.usb : Icons.sd_card_outlined,
                size: 15,
                color: context.colors.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                '${volume.name} · ${volume.usedPercent}%',
                style: context.texts.labelMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
              Icon(Icons.chevron_right, size: 16, color: context.colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
