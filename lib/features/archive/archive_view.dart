import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/errors/failure.dart';
import 'package:filevault/core/errors/result.dart';
import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/utils/date_formatter.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/folder_picker_sheet.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/core/widgets/fv_dialogs.dart';
import 'package:filevault/domain/models/archive_entry.dart';
import 'package:filevault/features/operations/operations_controller.dart';
import 'package:filevault/core/utils/ui_overlays.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Read-only browser for the inside of an archive, with selective extract.
class ArchiveView extends ConsumerStatefulWidget {
  const ArchiveView({super.key, required this.path});

  final String path;

  @override
  ConsumerState<ArchiveView> createState() => _ArchiveViewState();
}

class _ArchiveViewState extends ConsumerState<ArchiveView> {
  List<ArchiveEntryInfo> _all = <ArchiveEntryInfo>[];
  final Set<String> _selected = <String>{};
  String _cwd = '';
  bool _loading = true;
  String? _password;
  String? _errorKey;
  int _archiveBytes = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorKey = null;
    });
    final Result<List<ArchiveEntryInfo>> r =
        await ref.read(archiveRepositoryProvider).listEntries(widget.path, password: _password);
    final int size =
        (await ref.read(fileRepositoryProvider).stat(widget.path)).valueOrNull?.size ?? 0;
    if (!mounted) return;
    final Failure? failure = r.failureOrNull;
    if (failure != null) {
      if (failure is WrongPasswordFailure) {
        setState(() {
          _loading = false;
          _errorKey = 'password';
        });
        await _askPassword();
        return;
      }
      setState(() {
        _loading = false;
        _errorKey = failure is UnsupportedFormatFailure ? 'unsupported' : 'corrupt';
      });
      return;
    }
    setState(() {
      _all = r.valueOrNull ?? <ArchiveEntryInfo>[];
      _archiveBytes = size;
      _loading = false;
    });
  }

  Future<void> _askPassword() async {
    final String? password = await showPasswordDialog(
      context,
      title: context.l10n.archivePasswordTitle,
      message: context.l10n.archivePasswordBody,
    );
    if (password == null || !mounted) return;
    setState(() => _password = password);
    await _load();
  }

  List<ArchiveEntryInfo> get _current {
    final List<ArchiveEntryInfo> out =
        _all.where((ArchiveEntryInfo e) => e.parentPath == _cwd).toList();
    out.sort((ArchiveEntryInfo a, ArchiveEntryInfo b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return out;
  }

  int get _uncompressedBytes =>
      _all.where((ArchiveEntryInfo e) => !e.isDirectory).fold(0, (int a, ArchiveEntryInfo e) => a + e.size);

  int get _fileCount => _all.where((ArchiveEntryInfo e) => !e.isDirectory).length;

  Future<void> _extract({List<String>? entries}) async {
    final String? destination = await showFolderPicker(
      context,
      confirmLabel: context.l10n.extractHere,
      initialPath: p.dirname(widget.path),
      title: context.l10n.extractTo,
    );
    if (destination == null || !mounted) return;
    ref.read(operationsProvider.notifier).enqueueExtract(
          widget.path,
          destination,
          entries: entries,
          password: _password,
        );
    setState(_selected.clear);
  }

  @override
  Widget build(BuildContext context) {
    final List<ArchiveEntryInfo> entries = _current;
    final List<String> crumbs = _cwd.isEmpty ? <String>[] : _cwd.split('/');
    return PopScope<Object?>(
      canPop: _cwd.isEmpty,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (didPop) return;
        setState(() {
          final int slash = _cwd.lastIndexOf('/');
          _cwd = slash < 0 ? '' : _cwd.substring(0, slash);
        });
      },
      child: Scaffold(
        appBar: FvAppBar(
          leading: const FvBackButton(),
          title: p.basename(widget.path),
          subtitle:
              '${FileSizeFormatter.format(_archiveBytes)} • ${context.l10n.fileCount(_fileCount)}',
          actions: <Widget>[
            FvIconButton(
              icon: _selected.length == entries.length && entries.isNotEmpty
                  ? Icons.deselect
                  : Icons.select_all,
              tooltip: context.l10n.selectAll,
              onPressed: entries.isEmpty
                  ? null
                  : () => setState(() {
                        if (_selected.length == entries.length) {
                          _selected.clear();
                        } else {
                          _selected
                            ..clear()
                            ..addAll(entries.map((ArchiveEntryInfo e) => e.path));
                        }
                      }),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _errorKey != null
                ? FvEmptyState(
                    icon: _errorKey == 'password' ? Icons.lock_outline : Icons.error_outline,
                    title: _errorKey == 'unsupported'
                        ? context.l10n.unsupportedArchive
                        : _errorKey == 'password'
                            ? context.l10n.archivePasswordTitle
                            : context.l10n.archiveCorrupt,
                    message: _errorKey == 'password'
                        ? context.l10n.archivePasswordBody
                        : context.l10n.unsupportedArchive,
                    action: _errorKey == 'password'
                        ? FvTonalButton(label: context.l10n.ok, onPressed: _askPassword)
                        : null,
                  )
                : Column(
                    children: <Widget>[
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: <Widget>[
                            Center(
                              child: FvChip(
                                label: p.basename(widget.path),
                                icon: Icons.folder_zip_outlined,
                                dense: true,
                                selected: _cwd.isEmpty,
                                onTap: _cwd.isEmpty ? null : () => setState(() => _cwd = ''),
                              ),
                            ),
                            for (int i = 0; i < crumbs.length; i++) ...<Widget>[
                              Icon(Icons.chevron_right, size: 16, color: context.colors.outline),
                              Center(
                                child: FvChip(
                                  label: crumbs[i],
                                  dense: true,
                                  selected: i == crumbs.length - 1,
                                  onTap: i == crumbs.length - 1
                                      ? null
                                      : () => setState(() => _cwd = crumbs.take(i + 1).join('/')),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Row(
                          children: <Widget>[
                            FvChip(
                              label: context.l10n.archiveMode,
                              icon: Icons.visibility_outlined,
                              dense: true,
                            ),
                            const SizedBox(width: 8),
                            if (_password != null)
                              FvChip(label: context.l10n.encrypted, icon: Icons.lock, dense: true),
                            const Spacer(),
                            Text(
                              FileSizeFormatter.format(_uncompressedBytes),
                              style: context.texts.labelMedium?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FvSectionHeader(
                        title: context.l10n.contents,
                        count: entries.length,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                      ),
                      Expanded(
                        child: entries.isEmpty
                            ? FvEmptyState(
                                icon: Icons.folder_open,
                                title: context.l10n.emptyFolderTitle,
                                message: context.l10n.emptyFolderBody,
                              )
                            : ListView.builder(
                                padding: EdgeInsets.only(bottom: 160 + context.padding.bottom),
                                itemCount: entries.length,
                                itemBuilder: (BuildContext context, int i) {
                                  final ArchiveEntryInfo e = entries[i];
                                  return _ArchiveRow(
                                    entry: e,
                                    selected: _selected.contains(e.path),
                                    onTap: () => e.isDirectory
                                        ? setState(() => _cwd = e.path)
                                        : setState(() {
                                            if (!_selected.remove(e.path)) _selected.add(e.path);
                                          }),
                                    onToggle: () => setState(() {
                                      if (!_selected.remove(e.path)) _selected.add(e.path);
                                    }),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
        bottomNavigationBar: _loading || _errorKey != null
            ? null
            : ReserveBottomSpace(
              height: 76,
              child: Material(
                color: context.isDark
                    ? context.colors.surfaceContainerHigh
                    : context.colors.surfaceContainerLowest,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: context.tokens.cardBorder)),
                  ),
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + context.padding.bottom),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      FvFilledButton(
                        label: _selected.isEmpty
                            ? context.l10n.extractAll
                            : context.l10n.extractSelected(_selected.length),
                        icon: Icons.unarchive_outlined,
                        onPressed: () =>
                            _extract(entries: _selected.isEmpty ? null : _selected.toList()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }
}

class _ArchiveRow extends StatelessWidget {
  const _ArchiveRow({
    required this.entry,
    required this.selected,
    required this.onTap,
    required this.onToggle,
  });

  final ArchiveEntryInfo entry;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? (context.isDark
                  ? context.colors.primaryContainer.withValues(alpha: 0.25)
                  : context.colors.primaryFixed.withValues(alpha: 0.4))
              : null,
          border: Border(bottom: BorderSide(color: context.tokens.cardBorder)),
        ),
        child: Row(
          children: <Widget>[
            GestureDetector(
              onTap: onToggle,
              child: FvSelectCircle(selected: selected),
            ),
            const SizedBox(width: 12),
            FvCategoryTile(category: entry.category, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.texts.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    <String>[
                      if (entry.isDirectory) context.l10n.folder else FileSizeFormatter.format(entry.size),
                      if (entry.modified != null) DateFormatter.short(entry.modified!),
                    ].join('  •  '),
                    style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (entry.isDirectory) Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
