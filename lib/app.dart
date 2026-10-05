import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/router/app_router.dart';
import 'package:filevault/core/theme/app_theme.dart';
import 'package:filevault/domain/models/app_settings.dart';
import 'package:filevault/features/operations/operations_controller.dart';
import 'package:filevault/features/operations/widgets/conflict_dialog.dart';
import 'package:filevault/features/operations/widgets/operation_progress_panel.dart';
import 'package:filevault/features/settings/settings_controller.dart';
import 'package:filevault/features/vault/vault_viewmodel.dart';
import 'package:filevault/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root widget: wires theme, router, localization and the global hooks the
/// operation queue needs (conflict dialog + notification titles).
class FileVaultApp extends ConsumerStatefulWidget {
  const FileVaultApp({super.key});

  @override
  ConsumerState<FileVaultApp> createState() => _FileVaultAppState();
}

class _FileVaultAppState extends ConsumerState<FileVaultApp>
    with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _installQueueHooks());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _installQueueHooks() {
    final OperationsController controller = ref.read(
      operationsProvider.notifier,
    );
    controller.conflictResolver = (info) async {
      final BuildContext? context = rootNavigatorKey.currentContext;
      if (context == null) return null;
      return showConflictDialog(context, info);
    };
    controller.notificationTitle = (op) {
      final BuildContext? context = rootNavigatorKey.currentContext;
      final AppLocalizations l10n = context == null
          ? const AppLocalizations(Locale('en'))
          : AppLocalizations.of(context);
      return op.totalFiles > 0
          ? l10n.operationFilesCount(
              operationVerb(l10n, op.type),
              op.totalFiles,
            )
          : operationVerb(l10n, op.type);
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-lock the Secure Folder when the app leaves the foreground.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final DateTime? at = _backgroundedAt;
      _backgroundedAt = null;
      if (at == null) return;
      final int minutes = ref.read(settingsProvider).vaultAutoLockMinutes;
      final bool expired = DateTime.now().difference(at).inMinutes >= minutes;
      if (expired && ref.read(vaultRepositoryProvider).isUnlocked) {
        ref.read(vaultProvider.notifier).lock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings settings = ref.watch(settingsProvider);
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
      localizationsDelegates: <LocalizationsDelegate<Object>>[
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
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.4,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}