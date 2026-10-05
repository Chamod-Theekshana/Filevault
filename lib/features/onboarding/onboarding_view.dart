import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'onboarding_viewmodel.dart';
import 'onboarding_state.dart';

class OnboardingView extends ConsumerWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingViewModelProvider);
    
    // Use a listener to navigate once granted, to avoid modifying router state during build
    ref.listen<OnboardingState>(onboardingViewModelProvider, (previous, next) {
      next.maybeWhen(
        granted: () => context.go('/home'),
        orElse: () {},
      );
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.folder_shared,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome to FileVault',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'To manage your files, we need permission to access the storage on this device.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              state.when(
                initial: () => const SizedBox.shrink(),
                loading: () => const CircularProgressIndicator(),
                granted: () => const Text('Permission granted. Loading...'),
                denied: () => ElevatedButton(
                  onPressed: () => ref.read(onboardingViewModelProvider.notifier).requestPermission(),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Grant Permission'),
                ),
                permanentlyDenied: () => Column(
                  children: [
                    const Text(
                      'Permission is permanently denied. Please enable it in system settings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => openAppSettings(),
                      child: const Text('Open Settings'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}