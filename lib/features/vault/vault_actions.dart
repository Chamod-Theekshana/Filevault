import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/router/app_routes.dart';
import 'package:filevault/domain/repositories/vault_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Single entry point for "Move to Secure Folder" from anywhere in the app.
///
/// Files and whole folders are accepted. The user always passes through the
/// Secure Folder screen – which asks for the PIN or fingerprint every time it
/// is opened – before anything is moved, and sees the transfer there.
Future<void> moveToSecureFolder(
  BuildContext context,
  WidgetRef ref,
  List<String> paths,
) async {
  if (paths.isEmpty) return;
  // Read before any await: the caller's ref may be disposed afterwards.
  final VaultRepository repo = ref.read(vaultRepositoryProvider);
  final bool configured = await repo.isConfigured();
  if (!context.mounted) return;
  if (!configured) {
    final bool? created = await context.push<bool>(AppRoutes.vaultSetup);
    if (created != true) return;
    if (!context.mounted) {
      // Nowhere to continue from: don't leave the fresh vault unlocked.
      repo.lock();
      return;
    }
  }
  context.push(AppRoutes.vault, extra: <String, Object?>{'pendingAdd': paths});
}
