import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/utils/isolate_worker.dart';
import 'package:filevault/data/services/platform_channel_service.dart';
import 'package:filevault/domain/repositories/vault_repository.dart';
import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/router/app_routes.dart';
import 'package:filevault/core/utils/date_formatter.dart';
import 'package:filevault/core/utils/file_size_formatter.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/core/widgets/fv_common.dart';
import 'package:filevault/core/widgets/fv_dialogs.dart';
import 'package:filevault/domain/models/file_entry.dart';
import 'package:filevault/domain/models/vault_item.dart';
import 'package:filevault/features/security/app_lock_controller.dart';
import 'package:filevault/features/settings/settings_controller.dart';
import 'package:filevault/features/vault/vault_viewmodel.dart';
import 'package:filevault/features/vault/widgets/pin_pad.dart';
import 'package:filevault/features/vault/widgets/vault_file_picker.dart';
import 'package:filevault/features/viewer/open_file.dart';
import 'package:filevault/core/utils/ui_overlays.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Secure Folder: PIN/biometric lock screen, then the encrypted file list.
class VaultView extends ConsumerStatefulWidget {
  const VaultView({super.key, this.pendingAdd = const <String>[]});

  /// Files queued for encryption once the vault is unlocked.
  final List<String> pendingAdd;

  /// How many Secure Folder screens are in the navigation stack. Used to
  /// close viewers showing decrypted files when the vault auto-locks.
  static int openScreens = 0;

  @override
  ConsumerState<VaultView> createState() => _VaultViewState();
}

class _VaultViewState extends ConsumerState<VaultView> {
  List<String> _pending = <String>[];
  bool _promptedSetup = false;
  late final VaultViewModel _vm;
  late final VaultRepository _repo;
  late final PlatformChannelService _platform;
  late final bool _appWideSecure;

  @override
  void initState() {
    super.initState();
    _pending = List<String>.of(widget.pendingAdd);
    _vm = ref.read(vaultProvider.notifier);
    _repo = ref.read(vaultRepositoryProvider);
    _platform = ref.read(platformChannelProvider);
    _appWideSecure = ref.read(settingsProvider).secureWindow;
    VaultView.openScreens++;
    // Decrypted previews from an earlier visit are never kept around.
    _repo.clearTemporaryFiles();
    // No screenshots, screen recordings or recent-apps previews of the vault.
    _platform.setSecureWindow(true);
    // Coming back to the Secure Folder must always ask again: start locked
    // even if something left the key in memory.
    if (_repo.isUnlocked && _pending.isEmpty) {
      _repo.lock();
      Future<void>.microtask(_vm.lock);
    } else {
      Future<void>.microtask(_vm.load);
    }
  }

  @override
  void dispose() {
    // Leaving the Secure Folder locks it. The key is wiped right away; the
    // view-model update is deferred because providers must not notify
    // listeners while the widget tree is being torn down. Transfers that are
    // still running keep their own copy of the key and finish normally.
    _repo.lock();
    _repo.clearTemporaryFiles();
    VaultView.openScreens--;
    Future<void>.microtask(_vm.lock);
    if (!_appWideSecure) _platform.setSecureWindow(false);
    super.dispose();
  }

  void _flushPending() {
    if (_pending.isEmpty) return;
    final List<String> paths = _pending;
    _pending = <String>[];
    _vm.addFiles(paths);
  }

  @override
  Widget build(BuildContext context) {
    final VaultState state = ref.watch(vaultProvider);
    ref.listen<VaultState>(vaultProvider, (VaultState? prev, VaultState next) {
      if (next.unlocked && prev?.unlocked != true) _flushPending();
    });
    if (state.unlocked && _pending.isNotEmpty) {
      // Already unlocked (fresh vault right after setup): flush after build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _flushPending();
      });
    }
    if (state.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.status == VaultStatus.notConfigured) {
      if (!_promptedSetup) {
        _promptedSetup = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final bool? created = await context.push<bool>(AppRoutes.vaultSetup);
          if (!mounted) return;
          if (created != true) context.pop();
        });
      }
      return Scaffold(
        appBar: FvAppBar(leading: const FvBackButton(), title: context.l10n.vaultTitle),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (state.locked) return _VaultLockScreen(state: state);
    return _VaultContent(state: state, onAdd: _add);
  }

  Future<void> _add() async {
    final List<FileEntry>? files = await showVaultFilePicker(context);
    if (files == null || files.isEmpty || !mounted) return;
    _vm.addFiles(files.map((FileEntry e) => e.path).toList());
  }
}

class _VaultLockScreen extends ConsumerStatefulWidget {
  const _VaultLockScreen({required this.state});

  final VaultState state;

  @override
  ConsumerState<_VaultLockScreen> createState() => _VaultLockScreenState();
}

class _VaultLockScreenState extends ConsumerState<_VaultLockScreen> {
  String _pin = '';
  int _shake = 0;
  bool _triedBiometric = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeBiometric());
  }

  Future<void> _maybeBiometric() async {
    if (_triedBiometric) return;
    // App Lock is asking first; two system prompts at once would fail.
    if (ref.read(appLockProvider).locked && ref.read(settingsProvider).appLockEnabled) return;
    _triedBiometric = true;
    if (!ref.read(settingsProvider).vaultBiometric) return;
    if (!widget.state.biometricsAvailable) return;
    await ref.read(vaultProvider.notifier).unlockWithBiometrics();
  }

  void _digit(String d) {
    if (_pin.length >= kPinLength || widget.state.cooldownSeconds > 0) return;
    setState(() => _pin += d);
    if (_pin.length == kPinLength) _submit();
  }

  Future<void> _submit() async {
    final bool ok = await ref.read(vaultProvider.notifier).unlock(_pin);
    if (!mounted) return;
    if (!ok) {
      setState(() {
      _pin = '';
      _shake++;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    final VaultState state = ref.watch(vaultProvider);
    final bool cooling = state.cooldownSeconds > 0;
    final String? message = switch (state.error) {
      'wrongPin' => '${context.l10n.vaultWrongPin} • ${context.l10n.vaultAttemptsLeft(state.attemptsLeft)}',
      'cooldown' => context.l10n.vaultLockedFor(state.cooldownSeconds),
      'biometric' => context.l10n.biometricFailed,
      _ => null,
    };
    const Color ink = Colors.white;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
      backgroundColor: context.tokens.vault,
      appBar: FvAppBar(
        backgroundColor: context.tokens.vault,
        leading: FvIconButton(
          icon: Icons.arrow_back,
          tooltip: context.l10n.back,
          color: ink,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleWidget: const SizedBox.shrink(),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: ink.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.key_rounded, size: 34, color: context.tokens.amber),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        context.l10n.vaultTitle,
                        style: context.texts.headlineMedium?.copyWith(color: ink),
                      ),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          message ?? context.l10n.vaultEnterPinToOpen,
                          key: ValueKey<String>(message ?? ''),
                          textAlign: TextAlign.center,
                          style: context.texts.bodyMedium?.copyWith(
                            color: message == null ? ink.withValues(alpha: 0.72) : const Color(0xFFFFB4AB),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      ShakeOnChange(
                        trigger: _shake,
                        child: PinDots(
                          length: kPinLength,
                          filled: _pin.length,
                          error: state.error == 'wrongPin' || cooling,
                          onDark: true,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: ink.withValues(alpha: 0.85)),
                        onPressed: () async {
                          final bool ok = await showConfirmDialog(
                            context,
                            title: context.l10n.vaultForgotPin,
                            message: context.l10n.vaultForgotPinBody,
                            confirmLabel: context.l10n.vaultReset,
                            destructive: true,
                            icon: Icons.warning_amber_outlined,
                          );
                          if (!ok || !context.mounted) return;
                          await ref.read(vaultProvider.notifier).reset();
                          if (context.mounted) context.pop();
                        },
                        child: Text(context.l10n.vaultForgotPin),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            PinPad(
              onDigit: _digit,
              onBackspace: () {
                if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
              },
              enabled: !state.busy && !cooling,
              onDark: true,
              onBiometric: state.biometricsAvailable && ref.watch(settingsProvider).vaultBiometric
                  ? () => ref.read(vaultProvider.notifier).unlockWithBiometrics()
                  : null,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      ),
    );
  }
}

class _VaultContent extends ConsumerWidget {
  const _VaultContent({required this.state, required this.onAdd});

  final VaultState state;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final VaultViewModel vm = ref.read(vaultProvider.notifier);
    return Scaffold(
      appBar: FvAppBar(
        leading: FvBackButton(
          icon: state.selecting ? Icons.close : Icons.arrow_back,
          onPressed: state.selecting ? vm.clearSelection : null,
        ),
        title: state.selecting
            ? context.l10n.selectedCount(state.selected.length)
            : context.l10n.vaultTitle,
        subtitle: state.selecting
            ? null
            : '${context.l10n.itemCount(state.items.length)} • ${FileSizeFormatter.format(state.totalBytes)}',
        actions: <Widget>[
          if (state.selecting)
            FvIconButton(icon: Icons.select_all, tooltip: context.l10n.selectAll, onPressed: vm.selectAll)
          else ...<Widget>[
            FvIconButton(
              icon: Icons.lock_outline,
              tooltip: context.l10n.vaultLock,
              onPressed: () {
                vm.lock();
                context.showSnack(context.l10n.vaultLocked);
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (String value) async {
                switch (value) {
                  case 'pin':
                    await _changePin(context, ref);
                  case 'biometric':
                    await vm.setBiometrics(!ref.read(settingsProvider).vaultBiometric);
                  case 'reset':
                    final bool ok = await showConfirmDialog(
                      context,
                      title: context.l10n.vaultReset,
                      message: context.l10n.vaultForgotPinBody,
                      confirmLabel: context.l10n.vaultReset,
                      destructive: true,
                      icon: Icons.warning_amber_outlined,
                    );
                    if (ok) await vm.reset();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(value: 'pin', child: Text(context.l10n.vaultChangePin)),
                if (state.biometricsAvailable)
                  PopupMenuItem<String>(
                    value: 'biometric',
                    child: Text(
                      ref.read(settingsProvider).vaultBiometric
                          ? context.l10n.vaultDisableBiometric
                          : context.l10n.vaultEnableBiometric,
                    ),
                  ),
                PopupMenuItem<String>(value: 'reset', child: Text(context.l10n.vaultReset)),
              ],
            ),
          ],
        ],
      ),
      body: state.items.isEmpty
          ? FvEmptyState(
              icon: Icons.lock_outline,
              title: context.l10n.vaultEmptyTitle,
              message: context.l10n.vaultEmptyBody,
              action: FvFilledButton(
                label: context.l10n.vaultAddFiles,
                icon: Icons.add,
                expand: false,
                onPressed: onAdd,
              ),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 160 + context.padding.bottom),
              children: <Widget>[
                FvInfoBanner(
                  icon: Icons.verified_user_outlined,
                  title: context.l10n.vaultSubtitle,
                  subtitle: context.l10n.vaultHiddenNote,
                ),
                const SizedBox(height: 16),
                FvCard(
                  child: Column(
                    children: <Widget>[
                      for (int i = 0; i < state.items.length; i++)
                        _VaultRow(
                          item: state.items[i],
                          selected: state.selected.contains(state.items[i].id),
                          selecting: state.selecting,
                          last: i == state.items.length - 1,
                          onTap: () async {
                            if (state.selecting) {
                              vm.toggle(state.items[i].id);
                              return;
                            }
                            await _preview(context, ref, state.items[i]);
                          },
                          onLongPress: () => vm.toggle(state.items[i].id),
                        ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: state.selecting
          ? null
          : null,
      bottomNavigationBar: !state.selecting
          ? null
          : ReserveBottomSpace(
              height: 76,
              child: Material(
              color: context.isDark ? context.colors.surfaceContainerHigh : context.colors.surfaceContainerLowest,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: context.tokens.cardBorder)),
                ),
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + context.padding.bottom),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final bool ok = await showConfirmDialog(
                            context,
                            title: context.l10n.vaultDeleteTitle,
                            message: context.l10n.vaultDeleteBody(state.selected.length),
                            confirmLabel: context.l10n.deletePermanently,
                            destructive: true,
                            icon: Icons.delete_forever_outlined,
                          );
                          if (!ok) return;
                          await vm.deleteSelected();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.isDark ? Colors.white : context.colors.error,
                          side: BorderSide(color: context.colors.error.withValues(alpha: 0.6)),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 20),
                        label: Text(context.l10n.delete),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FvFilledButton(
                        label: context.l10n.vaultExport,
                        icon: Icons.lock_open_outlined,
                        onPressed: () async {
                          final bool ok = await showConfirmDialog(
                            context,
                            title: context.l10n.vaultExportTitle,
                            message: context.l10n.vaultExportBody(state.selected.length),
                            confirmLabel: context.l10n.vaultExport,
                            icon: Icons.lock_open_outlined,
                          );
                          if (!ok) return;
                          vm.exportSelected();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
    );
  }

  Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    final String? current = await showPasswordDialog(
      context,
      title: context.l10n.vaultCurrentPin,
      message: context.l10n.vaultEnterPin,
    );
    if (current == null || !context.mounted) return;
    final String? next = await showPasswordDialog(
      context,
      title: context.l10n.vaultNewPin,
      message: context.l10n.vaultCreatePin,
    );
    if (next == null || next.isEmpty || !context.mounted) return;
    final bool ok = await ref.read(vaultProvider.notifier).changePin(current, next);
    if (!context.mounted) return;
    context.showSnack(ok ? context.l10n.vaultPinChanged : context.l10n.vaultWrongPin);
  }

  Future<void> _preview(BuildContext context, WidgetRef ref, VaultItem item) async {
    final ValueNotifier<double> progress = ValueNotifier<double>(0);
    final CancelToken cancel = CancelToken();
    // Captured up front: if the vault locks while decrypting, this screen is
    // replaced by the lock screen, but the dialog must still be closed.
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    Route<dynamic>? dialogRoute;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        dialogRoute ??= ModalRoute.of(context);
        return PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(context.l10n.vaultDecrypting),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.bodyMedium,
              ),
              const SizedBox(height: 14),
              ValueListenableBuilder<double>(
                valueListenable: progress,
                builder: (BuildContext context, double value, Widget? _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    FvLoadingBar(value: value <= 0 ? null : value),
                    const SizedBox(height: 8),
                    Text(
                      '${(value * 100).round()}%  ·  ${FileSizeFormatter.format(item.size)}',
                      style: context.texts.labelMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(onPressed: cancel.cancel, child: Text(context.l10n.cancel)),
          ],
        ),
        );
      },
    );
    final String? path = await ref.read(vaultProvider.notifier).decryptForViewing(
          item,
          onProgress: (double f, String? _) => progress.value = f,
          cancelToken: cancel,
        );
    // Remove exactly this dialog – never whatever happens to be on top (an
    // auto-lock may already have closed it).
    final Route<dynamic>? route = dialogRoute;
    if (navigator.mounted && route != null && route.isActive) navigator.removeRoute(route);
    // The dialog's listener goes away with the next frame; dispose after it.
    WidgetsBinding.instance.addPostFrameCallback((_) => progress.dispose());
    if (!context.mounted || cancel.isCancelled) return;
    if (path == null) {
      context.showSnack(context.l10n.vaultOpenFailed);
      return;
    }
    final FileEntry? entry = (await ref.read(fileRepositoryProvider).stat(path)).valueOrNull;
    if (entry == null || !context.mounted) return;
    await openFileEntry(context, ref, entry, recordRecent: false);
  }
}

class _VaultRow extends StatelessWidget {
  const _VaultRow({
    required this.item,
    required this.selected,
    required this.selecting,
    required this.last,
    required this.onTap,
    required this.onLongPress,
  });

  final VaultItem item;
  final bool selected;
  final bool selecting;
  final bool last;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: last
          ? null
          : BoxDecoration(border: Border(bottom: BorderSide(color: context.tokens.cardBorder))),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          color: selected
              ? (context.isDark
                  ? context.colors.primaryContainer.withValues(alpha: 0.3)
                  : context.colors.primaryFixed.withValues(alpha: 0.5))
              : null,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: <Widget>[
              if (selecting) ...<Widget>[
                FvSelectCircle(selected: selected),
                const SizedBox(width: 12),
              ],
              FvCategoryTile(category: item.category, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.texts.titleSmall,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.lock, size: 14, color: context.colors.primary),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${FileSizeFormatter.format(item.size)}  •  ${DateFormatter.ago(item.addedAt)}',
                      style: context.texts.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              if (!selecting) Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
