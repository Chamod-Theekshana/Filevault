import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/utils/date_formatter.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/core/widgets/fv_thumbnail.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/repositories/file_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Properties sheet: size, path, dates, permissions, checksums on demand.
Future<void> showPropertiesDialog(BuildContext context, FileEntry entry) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => FractionallySizedBox(
      heightFactor: 0.9,
      child: _PropertiesSheet(entry: entry),
    ),
  );
}

class _PropertiesSheet extends ConsumerStatefulWidget {
  const _PropertiesSheet({required this.entry});

  final FileEntry entry;

  @override
  ConsumerState<_PropertiesSheet> createState() => _PropertiesSheetState();
}

class _PropertiesSheetState extends ConsumerState<_PropertiesSheet> {
  DirectoryStats? _stats;
  String? _md5;
  String? _sha;
  bool _busyMd5 = false;
  bool _busySha = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry.isDirectory) _loadStats();
  }

  Future<void> _loadStats() async {
    final DirectoryStats? s =
        (await ref.read(fileRepositoryProvider).directoryStats(widget.entry.path)).valueOrNull;
    if (mounted) setState(() => _stats = s);
  }

  Future<void> _hash(HashAlgorithm algorithm) async {
    setState(() {
      if (algorithm == HashAlgorithm.md5) {
        _busyMd5 = true;
      } else {
        _busySha = true;
      }
    });
    final String? value =
        (await ref.read(fileRepositoryProvider).computeHash(widget.entry.path, algorithm)).valueOrNull;
    if (!mounted) return;
    setState(() {
      if (algorithm == HashAlgorithm.md5) {
        _md5 = value;
        _busyMd5 = false;
      } else {
        _sha = value;
        _busySha = false;
      }
    });
  }

  void _copy(String value) {
    Clipboard.setData(ClipboardData(text: value));
    context.showSnack(context.l10n.copied);
  }

  @override
  Widget build(BuildContext context) {
    final FileEntry e = widget.entry;
    final DirectoryStats? stats = _stats;
    return Column(
      children: <Widget>[
        FvSheetHeader(
          title: context.l10n.propertiesTitle,
          onClose: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              Row(
                children: <Widget>[
                  FvThumbnail(entry: e, size: 64, radius: 16),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(e.name, style: context.texts.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(
                          e.isDirectory
                              ? context.l10n.folder
                              : '${e.extension.toUpperCase()} • ${FileSizeFormatter.format(e.size)}',
                          style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FvCard(
                child: Column(
                  children: <Widget>[
                    _Row(
                      icon: Icons.sd_storage_outlined,
                      label: context.l10n.size,
                      value: e.isDirectory
                          ? (stats == null ? context.l10n.computing : FileSizeFormatter.format(stats.bytes))
                          : '${FileSizeFormatter.format(e.size)}  (${FileSizeFormatter.count(e.size)} B)',
                    ),
                    if (e.isDirectory)
                      _Row(
                        icon: Icons.inventory_2_outlined,
                        label: context.l10n.contains,
                        value: stats == null
                            ? context.l10n.computing
                            : '${context.l10n.fileCount(stats.files)}, ${context.l10n.folderCount(stats.folders)}',
                      ),
                    _Row(
                      icon: Icons.folder_outlined,
                      label: context.l10n.location,
                      value: e.parentPath,
                      onCopy: () => _copy(e.parentPath),
                    ),
                    _Row(
                      icon: Icons.schedule,
                      label: context.l10n.modified,
                      value: DateFormatter.full(e.modified),
                    ),
                    if (!e.isDirectory)
                      _Row(
                        icon: Icons.description_outlined,
                        label: context.l10n.mimeType,
                        value: e.mimeType ?? context.l10n.unknown,
                      ),
                    _Row(
                      icon: Icons.visibility_outlined,
                      label: context.l10n.hidden,
                      value: e.isHidden ? context.l10n.yes : context.l10n.no,
                      last: true,
                    ),
                  ],
                ),
              ),
              if (!e.isDirectory) ...<Widget>[
                const SizedBox(height: 16),
                FvCard(
                  child: Column(
                    children: <Widget>[
                      _HashRow(
                        label: context.l10n.md5Checksum,
                        value: _md5,
                        busy: _busyMd5,
                        onCompute: () => _hash(HashAlgorithm.md5),
                        onCopy: _md5 == null ? null : () => _copy(_md5!),
                      ),
                      _HashRow(
                        label: context.l10n.sha256Checksum,
                        value: _sha,
                        busy: _busySha,
                        onCompute: () => _hash(HashAlgorithm.sha256),
                        onCopy: _sha == null ? null : () => _copy(_sha!),
                        last: true,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FvCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.lock_outline, size: 18, color: context.colors.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(context.l10n.accessControl, style: context.texts.labelMedium),
                          Text(
                            e.path,
                            style: context.texts.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: context.l10n.copyPath,
                      onPressed: () => _copy(e.path),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FvFilledButton(
                label: context.l10n.close,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.onCopy,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onCopy;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: last
          ? null
          : BoxDecoration(border: Border(bottom: BorderSide(color: context.tokens.cardBorder))),
      padding: EdgeInsets.fromLTRB(14, 12, onCopy == null ? 14 : 4, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: context.colors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: context.texts.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: context.texts.bodyMedium?.copyWith(
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: onCopy),
        ],
      ),
    );
  }
}

class _HashRow extends StatelessWidget {
  const _HashRow({
    required this.label,
    required this.value,
    required this.busy,
    required this.onCompute,
    this.onCopy,
    this.last = false,
  });

  final String label;
  final String? value;
  final bool busy;
  final VoidCallback onCompute;
  final VoidCallback? onCopy;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final String? v = value;
    return Container(
      decoration: last
          ? null
          : BoxDecoration(border: Border(bottom: BorderSide(color: context.tokens.cardBorder))),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: <Widget>[
          Icon(Icons.fingerprint, size: 18, color: context.colors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: context.texts.labelSmall?.copyWith(color: context.colors.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(
                  busy ? context.l10n.computing : (v ?? '—'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          if (v == null)
            FvTonalButton(label: context.l10n.verify, onPressed: busy ? null : onCompute)
          else
            IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: onCopy),
        ],
      ),
    );
  }
}
