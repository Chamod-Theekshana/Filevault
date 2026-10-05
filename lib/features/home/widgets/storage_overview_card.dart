import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/theme/app_colors.dart';
import 'package:filevault/core/theme/category_colors.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/domain/models/file_entity.dart';
import 'package:filevault/features/home/home_state.dart';
import 'package:flutter/material.dart';

class StorageOverviewCard extends StatelessWidget {
  const StorageOverviewCard({
    super.key,
    required this.primary,
    this.removable,
    required this.onCleanUp,
  });

  final StorageVolumeInfo? primary;
  final StorageVolumeInfo? removable;
  final VoidCallback onCleanUp;

  @override
  Widget build(BuildContext context) {
    final StorageVolumeInfo volume = primary ??
        const StorageVolumeInfo(
          id: 'internal',
          name: 'Internal storage',
          path: '',
          totalBytes: 0,
          usedBytes: 0,
          isPrimary: true,
          kind: StorageVolumeKind.internal,
        );
    final double fraction = volume.usedFraction.clamp(0.0, 1.0);
    final int percent = (fraction * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.darkSurfaceContainerLowest
            : AppColors.lightSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 8,
                      color: context.isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.lightSurfaceContainer,
                    ),
                    CircularProgressIndicator(
                      value: fraction == 0 ? 0.001 : fraction,
                      strokeWidth: 8,
                      color: context.isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimaryContainer,
                      strokeCap: StrokeCap.round,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text('$percent%', style: context.texts.headlineSmall),
                        Text(context.l10n.usedLabel, style: context.texts.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.phone_android, size: 18, color: context.colors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            volume.name,
                            style: context.texts.labelLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      context.l10n.usedOfTotal(
                        FileSizeFormatter.format(volume.usedBytes),
                        FileSizeFormatter.format(volume.totalBytes),
                      ),
                      style: context.texts.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      context.l10n.freeSpace(
                        FileSizeFormatter.format(volume.totalBytes - volume.usedBytes),
                      ),
                      style: context.texts.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      button: true,
                      label: context.l10n.cleanUp,
                      child: ActionChip(
                        avatar: Icon(Icons.auto_awesome, size: 18, color: context.colors.secondary),
                        label: Text(context.l10n.cleanUp),
                        onPressed: onCleanUp,
                        backgroundColor: context.isDark
                            ? AppColors.darkSecondaryContainer
                            : AppColors.lightSecondaryFixed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (removable != null) ...<Widget>[
            const SizedBox(height: 12),
            Divider(color: context.colors.outlineVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                FvCategoryTile(category: FileCategory.other, icon: Icons.sd_card),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(removable!.name, style: context.texts.labelMedium),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: removable!.usedFraction.clamp(0.0, 1.0),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    tooltip: context.l10n.ejectSdCard,
                    onPressed: () {},
                    icon: const Icon(Icons.eject_outlined),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
