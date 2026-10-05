import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/utils/file_utils.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/core/widgets/fv_file_tile.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/models/sort_options.dart';
import 'package:filevault/domain/models/storage_volume.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Multi-select file browser used to pick files to move into the vault.
Future<List<FileEntry>?> showVaultFilePicker(BuildContext context) {
  return showModalBottomSheet<List<FileEntry>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) =>
        const FractionallySizedBox(heightFactor: 0.94, child: _VaultFilePicker()),
  );
}

class _VaultFilePicker extends ConsumerStatefulWidget {
  const _VaultFilePicker();

  @override
  ConsumerState<_VaultFilePicker> createState() => _VaultFilePickerState();
}

class _VaultFilePickerState extends ConsumerState<_VaultFilePicker> {
  String? _path;
  StorageVolume? _volume;
  List<FileEntry> _entries = <FileEntry>[];
  final Map<String, FileEntry> _selected = <String, FileEntry>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final StorageVolume volume = await ref.read(storageRepositoryProvider).primaryVolume();
    if (!mounted) return;
    _volume = volume;
    await _open(volume.path);
  }

  Future<void> _open(String path) async {
    if (!mounted) return;
    setState(() {
      _path = path;
      _loading = true;
      _entries = <FileEntry>[];
    });
    final List<FileEntry> out = <FileEntry>[];
    try {
      await for (final List<FileEntry> batch
          in ref.read(fileRepositoryProvider).listDirectory(path, showHidden: false)) {
        out.addAll(batch);
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _entries = const SortSpec().apply(out);
      _loading = false;
    });
  }

  void _toggle(FileEntry entry) {
    setState(() {
      if (_selected.remove(entry.path) == null) _selected[entry.path] = entry;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? path = _path;
    final bool atRoot = path == null || path == (_volume?.path ?? '/');
    return Column(
      children: <Widget>[
        FvSheetHeader(
          title: context.l10n.vaultPickFiles,
          subtitle: path,
          onClose: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _entries.length + (atRoot ? 0 : 1),
                  itemBuilder: (BuildContext context, int index) {
                    if (!atRoot && index == 0) {
                      return ListTile(
                        leading: const Icon(Icons.arrow_upward),
                        title: Text(context.l10n.goUp),
                        onTap: () => _open(p.dirname(path)),
                      );
                    }
                    final FileEntry e = _entries[index - (atRoot ? 0 : 1)];
                    return FvFileListTile(
                      entry: e,
                      selecting: !e.isDirectory,
                      selected: _selected.containsKey(e.path),
                      onTap: () => e.isDirectory ? _open(e.path) : _toggle(e),
                      onLongPress: e.isDirectory ? null : () => _toggle(e),
                    );
                  },
                ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + context.padding.bottom),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: context.tokens.cardBorder)),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.l10n.selectedCount(_selected.length),
                  style: context.texts.titleSmall,
                ),
              ),
              FvFilledButton(
                label: context.l10n.addToSecureFolder,
                icon: Icons.lock_outline,
                expand: false,
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(_selected.values.toList()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Convenience used by tests: filters out entries that cannot be encrypted.
List<FileEntry> encryptableOnly(List<FileEntry> entries) =>
    entries.where((FileEntry e) => !e.isDirectory && FileUtils.isValidName(e.name)).toList();
