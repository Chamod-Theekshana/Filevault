import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/core/widgets/fv_dialogs.dart';
import 'package:filevault/domain/models/collection_items.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lets the user attach coloured tags to a file.
Future<void> showTagPicker(BuildContext context, WidgetRef ref, String path) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) => _TagPicker(path: path),
  );
}

class _TagPicker extends ConsumerStatefulWidget {
  const _TagPicker({required this.path});

  final String path;

  @override
  ConsumerState<_TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends ConsumerState<_TagPicker> {
  List<Tag> _all = <Tag>[];
  Set<int> _selected = <int>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<Tag> all = await ref.read(collectionsRepositoryProvider).tags();
    final List<Tag> mine = await ref.read(collectionsRepositoryProvider).tagsFor(widget.path);
    if (!mounted) return;
    setState(() {
      _all = all;
      _selected = mine.map((Tag t) => t.id).toSet();
      _loading = false;
    });
  }

  Future<void> _createTag() async {
    final String? name = await showTextInputDialog(
      context,
      title: context.l10n.newTag,
      hint: context.l10n.tagName,
      confirmLabel: context.l10n.create,
      validateFileName: false,
      exists: (String n) => _all.any((Tag t) => t.name.toLowerCase() == n.toLowerCase()),
    );
    if (name == null) return;
    final int color = Tag.palette[_all.length % Tag.palette.length];
    final Tag tag = await ref.read(collectionsRepositoryProvider).createTag(name, color);
    if (!mounted) return;
    setState(() {
      _all = <Tag>[..._all, tag];
      _selected = <int>{..._selected, tag.id};
    });
  }

  Future<void> _save() async {
    await ref.read(collectionsRepositoryProvider).setTagsFor(widget.path, _selected.toList());
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(context.l10n.assignTags, style: context.texts.headlineSmall),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_all.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  context.l10n.tagsEmptyBody,
                  style: context.texts.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final Tag t in _all)
                    FvChip(
                      label: t.name,
                      icon: Icons.label,
                      color: Color(t.colorArgb),
                      selected: _selected.contains(t.id),
                      onTap: () => setState(() {
                        if (!_selected.remove(t.id)) _selected.add(t.id);
                      }),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: _createTag,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(context.l10n.newTag),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(onPressed: _save, child: Text(context.l10n.save)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
