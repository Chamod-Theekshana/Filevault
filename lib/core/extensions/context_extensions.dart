import 'package:filevault/core/theme/app_theme.dart';
import 'package:filevault/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Small conveniences so widgets stay short and readable.
extension FvContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get texts => Theme.of(this).textTheme;
  FvTokens get tokens =>
      Theme.of(this).extension<FvTokens>() ??
      (isDark ? FvTokens.dark : FvTokens.light);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  AppLocalizations get l10n => AppLocalizations.of(this);
  Size get screen => MediaQuery.sizeOf(this);
  EdgeInsets get padding => MediaQuery.paddingOf(this);

  /// Shows a floating snackbar, replacing any currently visible one.
  void showSnack(String message, {SnackBarAction? action}) {
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(this);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: action,
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
