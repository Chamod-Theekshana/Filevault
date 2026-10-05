import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/router/app_routes.dart';
import 'package:filevault/features/onboarding/onboarding_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Brand splash shown while the permission state is read.
class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  bool _navigated = false;

  void _decide(OnboardingState state) {
    if (_navigated || !state.checked) return;
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(state.canEnterApp ? AppRoutes.home : AppRoutes.onboarding);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<OnboardingState>(onboardingProvider, (_, OnboardingState next) => _decide(next));
    _decide(ref.watch(onboardingProvider));
    return Scaffold(
      body: Center(
        child: Semantics(
          label: context.l10n.appName,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: <BoxShadow>[context.tokens.fabShadow],
                ),
                child: Icon(Icons.shield_outlined, size: 44, color: context.colors.onPrimary),
              ),
              const SizedBox(height: 20),
              Text(context.l10n.appName, style: context.texts.headlineLarge),
              const SizedBox(height: 28),
              SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(minHeight: 4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
