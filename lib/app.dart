import 'package:filevault/core/di/app_state.dart';
import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/router/app_router.dart';
import 'package:filevault/core/router/app_routes.dart';
import 'package:filevault/core/theme/app_theme.dart';
import 'package:filevault/core/utils/lifecycle_guard.dart';
import 'package:filevault/core/utils/ui_overlays.dart';
import 'package:filevault/domain/models/app_settings.dart';
import 'package:filevault/features/operations/operations_controller.dart';
import 'package:filevault/features/operations/widgets/conflict_dialog.dart';
import 'package:filevault/features/operations/widgets/operation_progress_panel.dart';
import 'package:filevault/features/security/app_lock_controller.dart';
import 'package:filevault/features/security/app_lock_screen.dart';
import 'package:filevault/features/settings/settings_controller.dart';
import 'package:filevault/features/vault/vault_view.dart';
import 'package:filevault/features/vault/vault_viewmodel.dart';
import 'package:filevault/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Root widget: wires theme, router, localization, App Lock, the global
/// operation-progress panel and the hooks the operation queue needs.
class FileVaultApp extends ConsumerStatefulWidget {
  const FileVaultApp({super.key});

  @override
  ConsumerState<FileVaultApp> createState() => _FileVaultAppState();
}

class _FileVaultAppState extends ConsumerState<FileVaultApp> with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _installQueueHooks();
      ref.read(platformChannelProvider).setSecureWindow(ref.read(settingsProvider).secureWindow);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _installQueueHooks() {
    final OperationsController controller = ref.read(operationsProvider.notifier);
    controller.conflictResolver = (info) async {
      final BuildContext? context = rootNavigatorKey.currentContext;
      if (context == null) return null;
      return showConflictDialog(context, info);
    };
    controller.notificationTitle = (op) {
      final BuildContext? context = rootNavigatorKey.currentContext;
      final AppLocalizations l10n =
          context == null ? const AppLocalizations(Locale('en')) : AppLocalizations.of(context);
      return op.totalFiles > 0
          ? l10n.operationFilesCount(operationVerb(l10n, op.type), op.totalFiles)
          : operationVerb(l10n, op.type);
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (LifecycleGuard.active) return;
      _backgroundedAt ??= DateTime.now();
      ref.read(appLockProvider.notifier).onBackground();
      // "Immediately" really means immediately: lock the Secure Folder as
      // soon as FileVault leaves the screen, not when it comes back.
      if (ref.read(settingsProvider).vaultAutoLockMinutes <= 0) _lockVault();
    } else if (state == AppLifecycleState.resumed) {
      ref.read(appLockProvider.notifier).onForeground();
      final DateTime? at = _backgroundedAt;
      _backgroundedAt = null;
      if (at == null) return;
      final int minutes = ref.read(settingsProvider).vaultAutoLockMinutes;
      if (DateTime.now().difference(at).inMinutes >= minutes) _lockVault();
    }
  }

  void _lockVault() {
    if (!ref.read(vaultRepositoryProvider).isUnlocked) return;
    ref.read(vaultProvider.notifier).lock();
    // Viewers opened from the Secure Folder show decrypted content; close
    // them so the user lands on the vault's lock screen when they return.
    if (VaultView.openScreens > 0) {
      rootNavigatorKey.currentState?.popUntil(
        (Route<dynamic> route) => route.settings.name == AppRoutes.vault || route.isFirst,
      );
    }
  }

  bool get _lockShowing =>
      ref.read(appReadyProvider) &&
      ref.read(settingsProvider).appLockEnabled &&
      ref.read(appLockProvider).locked;

  /// While App Lock covers the screen, the system back gesture must not pop
  /// the (hidden) pages underneath it.
  @override
  Future<bool> didPopRoute() async => _lockShowing;

  @override
  Widget build(BuildContext context) {
    final AppSettings settings = ref.watch(settingsProvider);
    ref.listen<bool>(
      settingsProvider.select((AppSettings s) => s.secureWindow),
      (bool? _, bool secure) => ref.read(platformChannelProvider).setSecureWindow(secure),
    );
    return MaterialApp.router(
      title: 'FileVault',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(appRouterProvider),
      theme: AppTheme.light(accentArgb: settings.accentArgb),
      darkTheme: AppTheme.dark(accentArgb: settings.accentArgb),
      themeMode: switch (settings.themeMode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      },
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (BuildContext context, Widget? child) {
        // Clamp text scaling so the dense file rows stay readable.
        final MediaQueryData mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.4),
          ),
          child: Stack(
            children: <Widget>[
              _LockAware(child: child ?? const SizedBox.shrink()),
              const _GlobalPanelHost(),
              const _AppLockGate(),
            ],
          ),
        );
      },
    );
  }
}

bool _watchLockShowing(WidgetRef ref) {
  final bool ready = ref.watch(appReadyProvider);
  final bool locked = ref.watch(appLockProvider.select((AppLockState s) => s.locked));
  final bool enabled = ref.watch(settingsProvider.select((AppSettings s) => s.appLockEnabled));
  return ready && locked && enabled;
}

/// Takes the app's pages out of keyboard focus while App Lock is showing.
class _LockAware extends ConsumerWidget {
  const _LockAware({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExcludeFocus(excluding: _watchLockShowing(ref), child: child);
  }
}

/// Covers the whole app with the lock screen while App Lock is engaged.
/// It appears instantly (no fade-in, so content never flashes on resume)
/// and fades out after a successful unlock. [BlockSemantics] keeps screen
/// readers from announcing the hidden pages underneath.
class _AppLockGate extends ConsumerWidget {
  const _AppLockGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool show = _watchLockShowing(ref);
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !show,
        child: AnimatedSwitcher(
          duration: Duration.zero,
          reverseDuration: const Duration(milliseconds: 180),
          child: show
              ? const BlockSemantics(child: AppLockScreen())
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Hosts the floating operation-progress card above *every* screen – tabs,
/// pushed screens and the Secure Folder alike – so copy, move and vault
/// transfers always show their progress. It gets its own [Overlay] because it
/// lives above the router's navigator (tooltips and ink need one).
class _GlobalPanelHost extends StatefulWidget {
  const _GlobalPanelHost();

  @override
  State<_GlobalPanelHost> createState() => _GlobalPanelHostState();
}

class _GlobalPanelHostState extends State<_GlobalPanelHost> {
  // Lives as long as the app itself, so it is never removed or disposed.
  late final OverlayEntry _entry = OverlayEntry(builder: (_) => const _PositionedPanel());

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(child: Overlay(initialEntries: <OverlayEntry>[_entry]));
  }
}

class _PositionedPanel extends ConsumerWidget {
  const _PositionedPanel();

  static const Set<String> _tabRoutes = <String>{
    AppRoutes.home,
    AppRoutes.browse,
    AppRoutes.search,
    AppRoutes.settings,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);
    final bool locked = _watchLockShowing(ref);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        router.routerDelegate,
        openPopupCount,
        reservedBottomSpace,
      ]),
      builder: (BuildContext context, Widget? _) {
        final String path = router.routerDelegate.currentConfiguration.uri.path;
        final bool overTabs = _tabRoutes.contains(path);
        final double bottomInset = MediaQuery.paddingOf(context).bottom;
        // Hidden – but kept alive so timers survive – while a dialog or sheet
        // is open, or while App Lock covers the app.
        final bool hidden = locked || openPopupCount.value > 0;
        final double base = overTabs ? 80 + bottomInset : bottomInset + 8;
        return Visibility(
          visible: !hidden,
          maintainState: true,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: base + reservedBottomSpace.value),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: const OperationProgressPanel(),
              ),
            ),
          ),
        );
      },
    );
  }
}
