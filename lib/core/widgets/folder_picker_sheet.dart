import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/errors/result.dart';
import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/utils/file_utils.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/core/widgets/fv_dialogs.dart';
import 'package:filevault/domain/models/file_category.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/models/sort_options.dart';
import 'package:filevault/domain/models/storage_volume.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Full-height sheet that lets the user navigate to a destination folder.
/// Returns the chosen path or null.
Future<String?> showFolderPicker(
  BuildContext context, {
  required String confirmLabel,
  String? initialPath,
  Set<String> disabledPaths = const <String>{},
  String? title,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => FractionallySizedBox(
      heightFactor: 0.92,
      child: _FolderPicker(
        confirmLabel: confirmLabel,
        initialPath: initialPath,
        disabledPaths: disabledPaths,
        title: title,
      ),
    ),
  );
}

class _FolderPicker extends ConsumerStatefulWidget {
  const _FolderPicker({
    required this.confirmLabel,
    required this.initialPath,
    required this.disabledPaths,
    required this.title,
  });

  final String confirmLabel;
  final String? initialPath;
  final Set<String> disabledPaths;
  final String? title;

  @override
  ConsumerState<_FolderPicker> createState() => _FolderPickerState();
}

class _FolderPickerState extends ConsumerState<_FolderPicker> {
  List<StorageVolume> _volumes = <StorageVolume>[];
  String? _current;
  List<FileEntry> _folders = <FileEntry>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final List<StorageVolume> volumes =
        await ref.read(storageRepositoryProvider).volumes();
    if (!mounted) return;
    _volumes = volumes;
    final String? initial = widget.initialPath;
    final bool initialExists =
        initial != null && await ref.read(fileRepositoryProvider).exists(initial);
    if (!mounted) return;
    if (initialExists) {
      await _open(initial);
    } else if (_volumes.length == 1) {
      await _open(_volumes.first.path);
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _open(String path) async {
    if (!mounted) return;
    setState(() {
      _current = path;
      _loading = true;
      _error = null;
      _folders = <FileEntry>[];
    });
    final List<FileEntry> out = <FileEntry>[];
    try {
      await for (final List<FileEntry> batch in ref
          .read(fileRepositoryProvider)
          .listDirectory(path, showHidden: false)) {
        out.addAll(batch.where((FileEntry e) => e.isDirectory));
      }
      out.sort(const SortSpec().compare);
      if (!mounted) return;
      setState(() {
        _folders = out;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.l10n.cannotReadFolder;
      });
    }
  }

  StorageVolume? get _volume {
    final String? c = _current;
    if (c == null) return null;
    for (final StorageVolume v in _volumes) {
      if (FileUtils.isWithin(v.path, c)) return v;
    }
    return null;
  }

  void _goUp() {
    final String? c = _current;
    final StorageVolume? v = _volume;
    if (c == null) return;
    if (v == null || c == v.path) {
      if (_volumes.length > 1) {
        setState(() {
          _current = null;
          _folders = <FileEntry>[];
        });
      }
      return;
    }
    _open(p.dirname(c));
  }

  Future<void> _newFolder() async {
    final String? current = _current;
    if (current == null) return;
    final String? name = await showTextInputDialog(
      context,
      title: context.l10n.createFolderTitle,
      hint: context.l10n.folderNameHint,
      confirmLabel: context.l10n.create,
      exists: (String n) => _folders.any((FileEntry f) => f.name == n),
    );
    if (name == null) return;
    final Result<FileEntry> r = await ref.read(fileRepositoryProvider).createFolder(current, name);
    if (!mounted) return;
    r.fold(
      onSuccess: (FileEntry e) => _open(e.path),
      onFailure: (_) => context.showSnack(context.l10n.somethingWentWrong),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? current = _current;
    final bool canConfirm =
        current != null && !widget.disabledPaths.any((String d) => FileUtils.isWithin(d, current));
    final List<String> crumbs = <String>[];
    if (current != null) {
      final StorageVolume? v = _volume;
      final String root = v?.path ?? '/';
      crumbs.add(v?.name ?? root);
      final String rel = current == root ? '' : p.relative(current, from: root);
      if (rel.isNotEmpty && rel != '.') crumbs.addAll(p.split(rel));
    }
    return Column(
      children: <Widget>[
        FvSheetHeader(
          title: widget.title ?? context.l10n.selectDestination,
          subtitle: current,
          onClose: () => Navigator.of(context).pop(),
        ),
        if (current != null)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: <Widget>[
                for (int i = 0; i < crumbs.length; i++) ...<Widget>[
                  if (i > 0)
                    Icon(Icons.chevron_right, size: 16, color: context.colors.outline),
                  Center(
                    child: FvChip(
                      label: crumbs[i],
                      dense: true,
                      selected: i == crumbs.length - 1,
                      onTap: i == crumbs.length - 1
                          ? null
                          : () {
                              final StorageVolume? v = _volume;
                              final String root = v?.path ?? '/';
                              final String target = i == 0
                                  ? root
                                  : p.joinAll(<String>[root, ...crumbs.sublist(1, i + 1)]);
                              _open(target);
                            },
                    ),
                  ),
                ],
              ],
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : current == null
                  ? ListView(
                      children: <Widget>[
                        for (final StorageVolume v in _volumes)
                          ListTile(
                            leading: Icon(v.isPrimary ? Icons.smartphone : Icons.sd_card_outlined),
                            title: Text(v.name),
                            subtitle: Text(v.path),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _open(v.path),
                          ),
                      ],
                    )
                  : _error != null
                      ? Center(child: Text(_error!))
                      : ListView.builder(
                          itemCount: _folders.length + 1,
                          itemBuilder: (BuildContext context, int i) {
                            if (i == 0) {
                              return ListTile(
                                leading: const Icon(Icons.arrow_upward),
                                title: Text(context.l10n.goUp),
                                onTap: _goUp,
                              );
                            }
                            final FileEntry f = _folders[i - 1];
                            final bool disabled =
                                widget.disabledPaths.any((String d) => FileUtils.isWithin(d, f.path));
                            return ListTile(
                              enabled: !disabled,
                              leading: const FvCategoryTile(
                                category: FileCategory.folders,
                                icon: Icons.folder_outlined,
                                size: 40,
                              ),
                              title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: disabled ? null : () => _open(f.path),
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
              OutlinedButton.icon(
                onPressed: current == null ? null : _newFolder,
                icon: const Icon(Icons.create_new_folder_outlined, size: 20),
                label: Text(context.l10n.newFolder),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: canConfirm ? () => Navigator.of(context).pop(current) : null,
                  child: Text(widget.confirmLabel),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
