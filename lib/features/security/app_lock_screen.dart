import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/features/security/app_lock_controller.dart';
import 'package:filevault/features/settings/settings_controller.dart';
import 'package:filevault/features/vault/widgets/pin_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-screen App Lock. Sits above the whole navigator (see `FileVaultApp`)
/// so nothing behind it can be seen or reached until the user authenticates.
class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  String _pin = '';
  int _shake = 0;
  bool _promptedBiometric = false;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    // Only show the fingerprint prompt while the app is actually visible –
    // the lock often engages while FileVault is in the background.
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
    } else {
      _lifecycle = AppLifecycleListener(onResume: _tryBiometric);
    }
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric({bool force = false}) async {
    if (!mounted) return;
    if (_promptedBiometric && !force) return;
    _promptedBiometric = true;
    if (!ref.read(settingsProvider).appLockBiometric) return;
    await ref.read(appLockProvider.notifier).unlockWithBiometrics(context.l10n.appLockReason);
  }

  void _digit(String d) {
    final AppLockState state = ref.read(appLockProvider);
    if (_pin.length >= kPinLength || state.cooldownSeconds > 0 || state.busy) return;
    setState(() => _pin += d);
    if (_pin.length == kPinLength) _submit();
  }

  Future<void> _submit() async {
    final bool ok = await ref.read(appLockProvider.notifier).unlockWithPin(_pin);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _pin = '';
        _shake++;
      });
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLockState state = ref.watch(appLockProvider);
    final bool biometric = ref.watch(settingsProvider).appLockBiometric && state.biometricsAvailable;
    final bool cooling = state.cooldownSeconds > 0;
    final String? message = switch (state.error) {
      'wrongPin' => '${context.l10n.vaultWrongPin} · ${context.l10n.vaultAttemptsLeft(state.attemptsLeft)}',
      'cooldown' => context.l10n.vaultLockedFor(state.cooldownSeconds),
      _ => null,
    };
    // This screen lives above the app's navigator, so it deliberately uses
    // no widgets that need an Overlay (tooltips, text fields).
    const Color ink = Colors.white;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Material(
      color: context.tokens.vault,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxHeight < 620;
            return Column(
              children: <Widget>[
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          FvAppIcon(size: compact ? 56 : 72),
                          SizedBox(height: compact ? 14 : 22),
                          Text(
                            context.l10n.appLockTitle,
                            style: context.texts.headlineMedium?.copyWith(color: ink),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Text(
                              message ?? context.l10n.appLockSubtitle,
                              key: ValueKey<String>(message ?? ''),
                              textAlign: TextAlign.center,
                              style: context.texts.bodyMedium?.copyWith(
                                color: message == null
                                    ? ink.withValues(alpha: 0.72)
                                    : const Color(0xFFFFB4AB),
                              ),
                            ),
                          ),
                          SizedBox(height: compact ? 20 : 30),
                          ShakeOnChange(
                            trigger: _shake,
                            child: PinDots(
                              length: kPinLength,
                              filled: _pin.length,
                              error: state.error == 'wrongPin' || cooling,
                              onDark: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                PinPad(
                  onDigit: _digit,
                  onBackspace: () {
                    if (_pin.isNotEmpty) {
                      setState(() => _pin = _pin.substring(0, _pin.length - 1));
                    }
                  },
                  enabled: !state.busy && !cooling,
                  onDark: true,
                  onBiometric: biometric ? () => _tryBiometric(force: true) : null,
                ),
                SizedBox(height: compact ? 8 : 20),
              ],
            );
          },
        ),
      ),
      ),
    );
  }
}

/// Bottom sheet asking for a 6-digit PIN. Returns the PIN, or null when the
/// user dismissed it. Used to confirm sensitive changes (turning App Lock
/// off, changing its PIN).
Future<String?> showPinPrompt(
  BuildContext context, {
  required String title,
  String? message,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => _PinPromptSheet(title: title, message: message),
  );
}

class _PinPromptSheet extends StatefulWidget {
  const _PinPromptSheet({required this.title, this.message});

  final String title;
  final String? message;

  @override
  State<_PinPromptSheet> createState() => _PinPromptSheetState();
}

class _PinPromptSheetState extends State<_PinPromptSheet> {
  String _pin = '';

  void _digit(String d) {
    if (_pin.length >= kPinLength) return;
    setState(() => _pin += d);
    if (_pin.length == kPinLength) {
      final String pin = _pin;
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (mounted) Navigator.of(context).pop(pin);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(widget.title, style: context.texts.headlineSmall, textAlign: TextAlign.center),
          if (widget.message != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              widget.message!,
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 22),
          PinDots(length: kPinLength, filled: _pin.length),
          const SizedBox(height: 18),
          PinPad(
            onDigit: _digit,
            onBackspace: () {
              if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
            },
          ),
        ],
      ),
    );
  }
}
