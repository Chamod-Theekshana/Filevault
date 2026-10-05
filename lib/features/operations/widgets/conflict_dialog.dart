import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/utils/date_formatter.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/utils/file_utils.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/core/widgets/fv_thumbnail.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/models/file_operation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// Replace / Skip / Keep both sheet shown when a destination already exists.
Future<ConflictDecision?> showConflictDialog(BuildContext context, ConflictInfo info) {
  return showModalBottomSheet<ConflictDecision>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (BuildContext context) => _ConflictSheet(info: info),
  );
}

class _ConflictSheet extends StatefulWidget {
  const _ConflictSheet({required this.info});

  final ConflictInfo info;

  @override
  State<_ConflictSheet> createState() => _ConflictSheetState();
}

class _ConflictSheetState extends State<_ConflictSheet> {
  bool _applyToAll = false;

  void _choose(ConflictResolution r) =>
      Navigator.of(context).pop(ConflictDecision(r, applyToAll: _applyToAll));

  FileEntry _entry(String path, int size, DateTime modified) => FileEntry(
        path: path,
        name: p.basename(path),
        isDirectory: false,
        size: size,
        modified: modified,
        category: FileUtils.categoryFor(p.basename(path)),
        extension: FileUtils.extensionOf(p.basename(path)),
        mimeType: FileUtils.mimeFor(p.basename(path)),
      );

  @override
  Widget build(BuildContext context) {
    final ConflictInfo info = widget.info;
    final String name = p.basename(info.destinationPath);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(context.l10n.conflictTitle, style: context.texts.headlineSmall),
            const SizedBox(height: 6),
            Text(
              context.l10n.conflictBody(name),
              style: context.texts.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _VersionCard(
                    label: context.l10n.existing,
                    entry: _entry(info.destinationPath, info.destinationSize, info.destinationModified),
                    highlight: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _VersionCard(
                    label: context.l10n.incoming,
                    entry: _entry(info.sourcePath, info.sourceSize, info.sourceModified),
                    highlight: true,
                    delta: info.sourceSize - info.destinationSize,
                  ),
                ),
              ],
            ),
            if (info.remaining > 0) ...<Widget>[
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _applyToAll,
                onChanged: (bool? v) => setState(() => _applyToAll = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.conflictApplyToAll, style: context.texts.titleSmall),
                subtitle: Text(context.l10n.conflictPending(info.remaining)),
              ),
            ],
            const SizedBox(height: 8),
            FvFilledButton(
              label: context.l10n.conflictReplace,
              icon: Icons.swap_horiz,
              onPressed: () => _choose(ConflictResolution.replace),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _choose(ConflictResolution.skip),
                    child: Text(context.l10n.conflictSkip),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _choose(ConflictResolution.keepBoth),
                    child: Text(context.l10n.conflictKeepBoth),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.l10n.cancel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.label,
    required this.entry,
    required this.highlight,
    this.delta,
  });

  final String label;
  final FileEntry entry;
  final bool highlight;
  final int? delta;

  @override
  Widget build(BuildContext context) {
    final int? d = delta;
    return FvCard(
      padding: const EdgeInsets.all(12),
      color: highlight
          ? (context.isDark
              ? context.colors.primaryContainer.withValues(alpha: 0.3)
              : context.colors.primaryFixed.withValues(alpha: 0.4))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: context.texts.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Center(child: FvThumbnail(entry: entry, size: 72, radius: 14)),
          const SizedBox(height: 10),
          Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.texts.titleSmall),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Icon(Icons.sd_storage_outlined, size: 14, color: context.colors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(FileSizeFormatter.format(entry.size), style: context.texts.bodySmall),
              if (d != null && d != 0) ...<Widget>[
                const SizedBox(width: 6),
                Text(
                  '${d > 0 ? '+' : '−'}${FileSizeFormatter.format(d.abs())}',
                  style: context.texts.labelSmall?.copyWith(
                    color: d > 0 ? context.tokens.success : context.colors.error,
                  ),
                ),
              ],
            ],
          ),
          Row(
            children: <Widget>[
              Icon(Icons.schedule, size: 14, color: context.colors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  DateFormatter.relative(entry.modified,
                      today: context.l10n.today, yesterday: context.l10n.yesterday),
                  style: context.texts.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
