import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/utils/file_utils.dart';
import 'package:flutter/material.dart';

/// Text prompt used for new folder / new file / rename / tag name.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String hint,
  String initialValue = '',
  String? confirmLabel,
  bool selectStem = true,
  bool validateFileName = true,
  bool Function(String value)? exists,
}) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) => _TextInputDialog(
      title: title,
      hint: hint,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
      selectStem: selectStem,
      validateFileName: validateFileName,
      exists: exists,
    ),
  );
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.hint,
    required this.initialValue,
    required this.confirmLabel,
    required this.selectStem,
    required this.validateFileName,
    required this.exists,
  });

  final String title;
  final String hint;
  final String initialValue;
  final String? confirmLabel;
  final bool selectStem;
  final bool validateFileName;
  final bool Function(String value)? exists;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    final String value = widget.initialValue;
    final int dot = value.lastIndexOf('.');
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.selectStem && dot > 0 ? dot : value.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String value = _controller.text.trim();
    final String? error = _validate(value);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(value);
  }

  String? _validate(String value) {
    if (value.isEmpty) return context.l10n.nameEmpty;
    if (widget.validateFileName && !FileUtils.isValidName(value)) return context.l10n.invalidName;
    if (widget.exists?.call(value) ?? false) return context.l10n.nameAlreadyExists;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        decoration: InputDecoration(hintText: widget.hint, errorText: _error),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.l10n.cancel)),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel ?? context.l10n.ok)),
      ],
    );
  }
}

/// Yes/no confirmation. Returns true when confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  bool destructive = false,
  IconData? icon,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      icon: icon == null
          ? null
          : Icon(icon, color: destructive ? context.colors.error : context.colors.primary, size: 32),
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(context.l10n.cancel)),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: context.colors.error,
                  foregroundColor: context.colors.onError,
                )
              : null,
          child: Text(confirmLabel ?? context.l10n.ok),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Password prompt for encrypted archives.
Future<String?> showPasswordDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) => _PasswordDialog(title: title, message: message),
  );
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.title, required this.message});

  final String title;
  final String message;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(Icons.lock_outline, color: context.colors.primary, size: 32),
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(widget.message, style: context.texts.bodyMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: _obscure,
            onSubmitted: (String v) => Navigator.of(context).pop(v),
            decoration: InputDecoration(
              hintText: context.l10n.password,
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.l10n.cancel)),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(context.l10n.ok),
        ),
      ],
    );
  }
}

/// Picks one of several options presented as a list.
Future<T?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<(T, String, IconData?)> options,
  T? selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (BuildContext context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title, style: context.texts.headlineSmall),
            ),
          ),
          for (final (T value, String label, IconData? icon) in options)
            ListTile(
              leading: icon == null ? null : Icon(icon),
              title: Text(label),
              trailing: value == selected
                  ? Icon(Icons.check_circle, color: context.colors.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(value),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
