import 'dart:math' as math;

import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/domain/models/storage_volume.dart';
import 'package:flutter/material.dart';

/// Storage summary: donut gauge, used/free numbers, Clean Up action and an
/// optional removable-volume row.
class StorageOverviewCard extends StatelessWidget {
  const StorageOverviewCard({
    super.key,
    required this.primary,
    required this.removable,
    required this.onCleanUp,
    required this.onOpenVolume,
  });

  final StorageVolume primary;
  final StorageVolume? removable;
  final VoidCallback onCleanUp;
  final void Function(StorageVolume volume) onOpenVolume;

  @override
  Widget build(BuildContext context) {
    final StorageVolume? sd = removable;
    return FvCard(
      elevated: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _DonutGauge(fraction: primary.usedFraction),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.smartphone, size: 18, color: context.colors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            primary.name,
                            style: context.texts.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      primary.totalBytes == 0
                          ? context.l10n.loading
                          : context.l10n.usedOfTotal(
                              FileSizeFormatter.format(primary.usedBytes),
                              FileSizeFormatter.format(primary.totalBytes),
                            ),
                      style: context.texts.titleSmall?.copyWith(
                        fontSize: 15,
                        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      context.l10n.freeSpace(FileSizeFormatter.format(primary.freeBytes)),
                      style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    _CleanUpChip(onPressed: onCleanUp),
                  ],
                ),
              ),
            ],
          ),
          if (sd != null) ...<Widget>[
            const SizedBox(height: 14),
            Divider(height: 1, color: context.tokens.cardBorder),
            const SizedBox(height: 12),
            _RemovableRow(volume: sd, onOpen: () => onOpenVolume(sd)),
          ],
        ],
      ),
    );
  }
}

class _CleanUpChip extends StatelessWidget {
  const _CleanUpChip({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: context.isDark
            ? context.tokens.amber.withValues(alpha: 0.22)
            : context.colors.secondaryFixed,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.auto_awesome, size: 18, color: context.isDark ? context.tokens.amber : context.colors.onSecondaryContainer),
                const SizedBox(width: 8),
                Text(
                  context.l10n.cleanUp,
                  style: context.texts.labelLarge?.copyWith(
                    color: context.isDark ? context.tokens.amber : context.colors.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RemovableRow extends StatelessWidget {
  const _RemovableRow({required this.volume, required this.onOpen});

  final StorageVolume volume;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.tokens.chipFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              volume.kind == StorageVolumeKind.usb ? Icons.usb : Icons.sd_card_outlined,
              size: 20,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        volume.name,
                        style: context.texts.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${volume.usedPercent}%',
                      style: context.texts.labelMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: volume.usedFraction.clamp(0.0, 1.0),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.usedOfTotal(
                    FileSizeFormatter.format(volume.usedBytes),
                    FileSizeFormatter.format(volume.totalBytes),
                  ),
                  style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// Circular used-space gauge with the percentage in the middle.
class _DonutGauge extends StatelessWidget {
  const _DonutGauge({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final double f = fraction.clamp(0.0, 1.0);
    return SizedBox(
      width: 96,
      height: 96,
      child: CustomPaint(
        painter: _DonutPainter(
          fraction: f,
          track: context.isDark ? context.colors.surfaceContainerHigh : context.colors.surfaceContainer,
          fill: context.colors.primaryContainer,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '${(f * 100).round()}%',
                style: context.texts.headlineSmall?.copyWith(
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
              Text(
                context.l10n.used,
                style: context.texts.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.fraction, required this.track, required this.fill});

  final double fraction;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 9;
    final Rect rect = Offset.zero & size;
    final Rect arcRect = rect.deflate(stroke / 2 + 2);
    final Paint trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    final Paint fillPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = fill;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, trackPaint);
    if (fraction > 0) {
      canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * fraction, false, fillPaint);
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.fraction != fraction || old.track != track || old.fill != fill;
}
