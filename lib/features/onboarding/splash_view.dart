import 'package:filevault/core/di/app_state.dart';
import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/router/app_routes.dart';
import 'package:filevault/core/utils/app_logger.dart';
import 'package:filevault/core/widgets/fv_app_bar.dart';
import 'package:filevault/features/home/home_viewmodel.dart';
import 'package:filevault/features/onboarding/onboarding_viewmodel.dart';
import 'package:filevault/features/settings/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Brand splash. It stays on screen until everything the first screen needs
/// is loaded – permission state, expired-trash cleanup, storage volumes,
/// category totals, recents and the Secure Folder status – so Home never
/// appears half-empty or "pops in". A safety timeout keeps a slow SD card
/// from holding the app hostage.
class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  static const Duration _minimumVisible = Duration(milliseconds: 450);
  static const Duration _maximumWait = Duration(seconds: 10);

  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    if (_started) return;
    _started = true;
    final Stopwatch watch = Stopwatch()..start();
    bool canEnter = false;
    try {
      // 1. Storage permission (decides between onboarding and home).
      await ref.read(onboardingProvider.notifier).refresh();
      final OnboardingState permission = ref.read(onboardingProvider);
      canEnter = permission.canEnterApp;

      if (canEnter) {
        // 2. Housekeeping that changes what Home shows.
        final int days = ref.read(settingsProvider).trashAutoCleanDays;
        if (days > 0) {
          await ref.read(trashRepositoryProvider).purgeExpired(days).timeout(
                const Duration(seconds: 4),
                onTimeout: () => 0,
              );
        }
        // 3. Everything Home renders, loaded in parallel by its view model.
        await ref.read(homeProvider.notifier).firstLoad.timeout(_maximumWait, onTimeout: () {});
      }
    } catch (error, stack) {
      appLogger.w('Startup step failed', error: error, stackTrace: stack);
    }
    final Duration elapsed = watch.elapsed;
    if (elapsed < _minimumVisible) {
      await Future<void>.delayed(_minimumVisible - elapsed);
    }
    if (!mounted) return;
    ref.read(appReadyProvider.notifier).state = true;
    context.go(canEnter ? AppRoutes.home : AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Spacer(flex: 5),
              Semantics(
                label: context.l10n.appName,
                child: const FvAppIcon(size: 96),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.appName,
                style: context.texts.headlineLarge?.copyWith(letterSpacing: -0.6),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.splashTagline,
                style: context.texts.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              const Spacer(flex: 4),
              SizedBox(
                width: 112,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: context.tokens.chipFill,
                    color: context.colors.primaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.splashLoading,
                style: context.texts.labelMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
