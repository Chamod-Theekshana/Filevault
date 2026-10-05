import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/features/vault/vault_viewmodel.dart';
import 'package:filevault/features/vault/widgets/pin_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// First-run Secure Folder setup: choose a PIN, confirm it, optionally
/// enable the fingerprint shortcut.
class VaultSetupView extends ConsumerStatefulWidget {
  const VaultSetupView({super.key});

  @override
  ConsumerState<VaultSetupView> createState() => _VaultSetupViewState();
}

class _VaultSetupViewState extends ConsumerState<VaultSetupView> {
  String _first = '';
  String _pin = '';
  bool _confirming = false;
  bool _useBiometrics = false;
  bool _error = false;
  int _shake = 0;

  void _digit(String d) {
    if (_pin.length >= kPinLength) return;
    setState(() {
      _pin += d;
      _error = false;
    });
    if (_pin.length == kPinLength) _submit();
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    if (!_confirming) {
      setState(() {
        _first = _pin;
        _pin = '';
        _confirming = true;
      });
      return;
    }
    if (_pin != _first) {
      setState(() {
        _error = true;
        _shake++;
        _pin = '';
      });
      return;
    }
    final bool ok = await ref
        .read(vaultProvider.notifier)
        .setup(_first, enableBiometrics: _useBiometrics);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _error = true;
        _shake++;
        _pin = '';
        _first = '';
        _confirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final VaultState state = ref.watch(vaultProvider);
    return Scaffold(
      appBar: FvAppBar(leading: const FvBackButton(), title: context.l10n.vaultTitle),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: context.colors.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: <BoxShadow>[context.tokens.fabShadow],
                      ),
                      child: Icon(Icons.lock_outline, size: 34, color: context.colors.onPrimary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _confirming ? context.l10n.vaultConfirmPin : context.l10n.vaultSetupTitle,
                      style: context.texts.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error ? context.l10n.vaultPinMismatch : context.l10n.vaultSetupBody,
                      textAlign: TextAlign.center,
                      style: context.texts.bodyMedium?.copyWith(
                        color: _error ? context.colors.error : context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ShakeOnChange(
                      trigger: _shake,
                      child: PinDots(length: kPinLength, filled: _pin.length, error: _error),
                    ),
                    const SizedBox(height: 16),
                    if (state.biometricsAvailable)
                      SwitchListTile(
                        value: _useBiometrics,
                        onChanged: (bool v) => setState(() => _useBiometrics = v),
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.l10n.vaultEnableBiometric, style: context.texts.titleSmall),
                        subtitle: Text(context.l10n.vaultEnableBiometricSub),
                        secondary: const Icon(Icons.fingerprint),
                      ),
                    const SizedBox(height: 8),
                    FvInfoBanner(
                      icon: Icons.verified_user_outlined,
                      title: context.l10n.vaultHiddenNote,
                    ),
                  ],
                ),
              ),
            ),
            PinPad(
              onDigit: _digit,
              onBackspace: _backspace,
              enabled: !state.busy,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
