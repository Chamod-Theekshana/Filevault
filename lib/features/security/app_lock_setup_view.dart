import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/features/security/app_lock_controller.dart';
import 'package:filevault/features/vault/widgets/pin_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Turns App Lock on (or changes its PIN): choose a 6-digit PIN, confirm it,
/// optionally allow fingerprint unlock. Pops `true` on success.
class AppLockSetupView extends ConsumerStatefulWidget {
  const AppLockSetupView({super.key, this.changeOnly = false});

  /// When true only the PIN is replaced; App Lock is already on.
  final bool changeOnly;

  @override
  ConsumerState<AppLockSetupView> createState() => _AppLockSetupViewState();
}

class _AppLockSetupViewState extends ConsumerState<AppLockSetupView> {
  String _first = '';
  String _pin = '';
  bool _confirming = false;
  bool _mismatch = false;
  bool _useBiometric = true;
  bool _bioAvailable = false;
  bool _saving = false;
  int _shake = 0;

  @override
  void initState() {
    super.initState();
    ref.read(appLockProvider.notifier).biometricsAvailable().then((bool v) {
      if (mounted) setState(() => _bioAvailable = v);
    });
  }

  void _digit(String d) {
    if (_pin.length >= kPinLength || _saving) return;
    setState(() {
      _pin += d;
      _mismatch = false;
    });
    if (_pin.length == kPinLength) _submit();
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
        _mismatch = true;
        _shake++;
        _pin = '';
        _first = '';
        _confirming = false;
      });
      return;
    }
    setState(() => _saving = true);
    final AppLockController controller = ref.read(appLockProvider.notifier);
    if (widget.changeOnly) {
      await controller.changePin(_first);
    } else {
      await controller.enable(_first, biometric: _bioAvailable && _useBiometric);
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FvAppBar(
        leading: const FvBackButton(),
        title: widget.changeOnly ? context.l10n.appLockChangePin : context.l10n.appLock,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Column(
                  children: <Widget>[
                    const FvAppIcon(size: 64),
                    const SizedBox(height: 18),
                    Text(
                      _confirming ? context.l10n.vaultConfirmPin : context.l10n.appLockCreatePin,
                      style: context.texts.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _mismatch ? context.l10n.vaultPinMismatch : context.l10n.appLockSetupBody,
                      textAlign: TextAlign.center,
                      style: context.texts.bodyMedium?.copyWith(
                        color: _mismatch ? context.colors.error : context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 26),
                    ShakeOnChange(
                      trigger: _shake,
                      child: PinDots(length: kPinLength, filled: _pin.length, error: _mismatch),
                    ),
                    const SizedBox(height: 18),
                    if (_bioAvailable && !widget.changeOnly)
                      FvCard(
                        child: SwitchListTile(
                          value: _useBiometric,
                          onChanged: (bool v) => setState(() => _useBiometric = v),
                          title: Text(context.l10n.appLockUseBiometric, style: context.texts.titleSmall),
                          subtitle: Text(context.l10n.vaultEnableBiometricSub),
                          secondary: const Icon(Icons.fingerprint),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            PinPad(
              onDigit: _digit,
              onBackspace: () {
                if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
              },
              enabled: !_saving,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
