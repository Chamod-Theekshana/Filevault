import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/domain/models/archive_entry.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class CreateArchiveRequest {
  const CreateArchiveRequest({
    required this.sources,
    required this.archivePath,
    required this.format,
    required this.level,
    required this.password,
    required this.deleteSources,
  });

  final List<String> sources;
  final String archivePath;
  final ArchiveFormat format;
  final int level;
  final String? password;
  final bool deleteSources;
}

/// "Create archive" sheet: name, format, compression level, password and
/// the option to delete the sources afterwards.
Future<CreateArchiveRequest?> showCreateArchiveSheet(
  BuildContext context, {
  required List<FileEntry> sources,
  required String suggestedName,
  required String destinationDir,
}) {
  return showModalBottomSheet<CreateArchiveRequest>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => _CreateArchiveSheet(
      sources: sources,
      suggestedName: suggestedName,
      destinationDir: destinationDir,
    ),
  );
}

class _CreateArchiveSheet extends StatefulWidget {
  const _CreateArchiveSheet({
    required this.sources,
    required this.suggestedName,
    required this.destinationDir,
  });

  final List<FileEntry> sources;
  final String suggestedName;
  final String destinationDir;

  @override
  State<_CreateArchiveSheet> createState() => _CreateArchiveSheetState();
}

class _CreateArchiveSheetState extends State<_CreateArchiveSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.suggestedName);
  final TextEditingController _password = TextEditingController();
  ArchiveFormat _format = ArchiveFormat.zip;
  int _level = 6;
  bool _deleteSources = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  int get _totalBytes => widget.sources.fold(0, (int a, FileEntry e) => a + e.size);

  void _submit() {
    final String base = _name.text.trim().isEmpty ? widget.suggestedName : _name.text.trim();
    final String fileName = '$base.${_format.extension}';
    final String password = _password.text;
    Navigator.of(context).pop(CreateArchiveRequest(
      sources: widget.sources.map((FileEntry e) => e.path).toList(),
      archivePath: p.join(widget.destinationDir, fileName),
      format: _format,
      level: _level,
      password: _format.supportsPassword && password.isNotEmpty ? password : null,
      deleteSources: _deleteSources,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(context.l10n.createArchive, style: context.texts.headlineSmall),
              const SizedBox(height: 4),
              Text(
                '${context.l10n.itemCount(widget.sources.length)} • ${FileSizeFormatter.format(_totalBytes)}',
                style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: context.l10n.archiveName,
                  suffixText: '.${_format.extension}',
                  prefixIcon: const Icon(Icons.folder_zip_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Text(context.l10n.format, style: context.texts.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  for (final ArchiveFormat f in ArchiveFormat.values)
                    FvChip(
                      label: f.label,
                      selected: _format == f,
                      onTap: () => setState(() => _format = f),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(context.l10n.compressionLevel, style: context.texts.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  for (final (int level, String label) in <(int, String)>[
                    (0, context.l10n.compressionStore),
                    (1, context.l10n.compressionFast),
                    (6, context.l10n.compressionNormal),
                    (9, context.l10n.compressionBest),
                  ])
                    FvChip(
                      label: label,
                      selected: _level == level,
                      onTap: () => setState(() => _level = level),
                    ),
                ],
              ),
              if (_format.supportsPassword) ...<Widget>[
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: context.l10n.setPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.info_outline, size: 16, color: context.colors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        context.l10n.passwordNote,
                        style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _deleteSources,
                onChanged: (bool? v) => setState(() => _deleteSources = v ?? false),
                controlAffinity: ListTileControlAffinity.trailing,
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.deleteSourceAfterArchive, style: context.texts.titleSmall),
                subtitle: Text(context.l10n.deleteSourceSub(FileSizeFormatter.format(_totalBytes))),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(context.l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FvFilledButton(
                      label: context.l10n.createArchive,
                      icon: Icons.archive_outlined,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
