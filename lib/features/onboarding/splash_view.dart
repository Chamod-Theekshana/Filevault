import 'package:filevault/core/extensions/context_extensions.dart';
import 'package:filevault/core/router/app_routes.dart';
import 'package:filevault/core/theme/app_colors.dart';
import 'package:filevault/domain/models/storage_permission_status.dart';
import 'package:filevault/features/onboarding/onboarding_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashView extends ConsumerWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(onboardingViewModelProvider, (_, next) {
      if (next.status == StoragePermissionStatus.unknown) {
        return;
      }
      if (next.status.canEnterApp) {
        context.go(AppRoutes.home);
      } else {
        context.go(AppRoutes.onboarding);
      }
    });
    return Scaffold(
      body: Center(
        child: Semantics(
          label: context.l10n.splashSemantics,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: context.isDark
                      ? AppColors.darkPrimaryContainer
                      : AppColors.lightPrimaryFixed,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.shield,
                  size: 36,
                  color: context.isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(context.l10n.appName, style: context.texts.headlineLarge),
            ],
          ),
        ),
      ),
    );
  }
}
