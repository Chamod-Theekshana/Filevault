import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/errors/result.dart';
import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/core/widgets/fv_dialogs.dart';
import 'package:filevault/domain/repositories/file_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Text/code viewer with a simple editor, encoding detection, line numbers
/// and word-wrap toggle.
class TextEditorView extends ConsumerStatefulWidget {
  const TextEditorView({super.key, required this.path});

  final String path;

  @override
  ConsumerState<TextEditorView> createState() => _TextEditorViewState();
}

class _TextEditorViewState extends ConsumerState<TextEditorView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  String _encoding = 'UTF-8';
  int _bytes = 0;
  bool _loading = true;
  bool _dirty = false;
  bool _wrap = true;
  bool _lineNumbers = true;
  bool _tooLarge = false;
  String _original = '';

  @override
  void initState() {
    super.initState();
    _load();
    _controller.addListener(() {
      final bool dirty = _controller.text != _original;
      if (dirty != _dirty) setState(() => _dirty = dirty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final Result<TextDocument> r = await ref.read(fileRepositoryProvider).readText(widget.path);
    if (!mounted) return;
    r.fold(
      onSuccess: (TextDocument doc) => setState(() {
        // Set the baseline first: assigning `text` fires the listener
        // synchronously, which would otherwise mark the file as edited.
        _original = doc.content;
        _controller.text = doc.content;
        _dirty = false;
        _encoding = doc.encoding;
        _bytes = doc.bytes;
        _loading = false;
      }),
      onFailure: (_) => setState(() {
        _loading = false;
        _tooLarge = true;
      }),
    );
  }

  Future<void> _save() async {
    final Result<void> r = await ref
        .read(fileRepositoryProvider)
        .writeText(widget.path, _controller.text, encoding: _encoding);
    if (!mounted) return;
    r.fold(
      onSuccess: (_) {
        setState(() {
          _original = _controller.text;
          _dirty = false;
        });
        context.showSnack(context.l10n.saved);
      },
      onFailure: (_) => context.showSnack(context.l10n.somethingWentWrong),
    );
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    return showConfirmDialog(
      context,
      title: context.l10n.discardChanges,
      message: context.l10n.discardChangesBody,
      confirmLabel: context.l10n.discard,
      destructive: true,
    );
  }

  int get _lineCount => '\n'.allMatches(_controller.text).length + 1;

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !_dirty,
      onPopInvokedWithResult: (bool didPop, Object? _) async {
        if (didPop) return;
        if (await _confirmDiscard() && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: FvAppBar(
          leading: const FvBackButton(),
          title: p.basename(widget.path),
          subtitle: '$_encoding • ${FileSizeFormatter.format(_bytes)}${_dirty ? ' • ${context.l10n.unsaved}' : ''}',
          actions: <Widget>[
            FvIconButton(
              icon: Icons.copy_all_outlined,
              tooltip: context.l10n.copy,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _controller.text));
                context.showSnack(context.l10n.copied);
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (String value) {
                switch (value) {
                  case 'wrap':
                    setState(() => _wrap = !_wrap);
                  case 'lines':
                    setState(() => _lineNumbers = !_lineNumbers);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                CheckedPopupMenuItem<String>(
                  value: 'wrap',
                  checked: _wrap,
                  child: Text(context.l10n.wordWrap),
                ),
                CheckedPopupMenuItem<String>(
                  value: 'lines',
                  checked: _lineNumbers,
                  child: Text(context.l10n.lineNumbers),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FvTonalButton(
                label: context.l10n.save,
                icon: Icons.check,
                onPressed: _dirty ? _save : null,
              ),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _tooLarge
                ? FvEmptyState(
                    icon: Icons.description_outlined,
                    title: context.l10n.fileTooLargeToEdit,
                    message: context.l10n.noAppToOpen,
                  )
                : Column(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          color: context.isDark
                              ? context.colors.surfaceContainerLowest
                              : context.colors.surfaceContainerLowest,
                          child: SingleChildScrollView(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(0, 12, 12, 24),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                if (_lineNumbers)
                                  Container(
                                    width: 48,
                                    padding: const EdgeInsets.only(right: 8, top: 2),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: <Widget>[
                                        for (int i = 1; i <= _lineCount; i++)
                                          Text(
                                            '$i',
                                            style: context.texts.bodySmall?.copyWith(
                                              fontFamily: 'monospace',
                                              height: 1.5,
                                              color: context.colors.outline,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                Expanded(
                                  child: _wrap
                                      ? _editor(context)
                                      : SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: SizedBox(
                                            width: context.screen.width * 2,
                                            child: _editor(context),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _StatusBar(
                        lines: _lineCount,
                        characters: _controller.text.length,
                        dirty: _dirty,
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _editor(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      style: context.texts.bodyMedium?.copyWith(fontFamily: 'monospace', height: 1.5),
      decoration: const InputDecoration(
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.lines, required this.characters, required this.dirty});

  final int lines;
  final int characters;
  final bool dirty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + context.padding.bottom),
      decoration: BoxDecoration(
        color: context.isDark ? context.colors.surfaceContainer : context.colors.surfaceContainerLow,
        border: Border(top: BorderSide(color: context.tokens.cardBorder)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.notes, size: 16, color: context.colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '${context.l10n.lnCol(lines, 1)}  •  ${context.l10n.bytesCount(characters)}',
            style: context.texts.bodySmall?.copyWith(
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dirty ? context.tokens.amber : context.tokens.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            dirty ? context.l10n.unsaved : context.l10n.readWrite,
            style: context.texts.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
