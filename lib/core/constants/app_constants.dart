/// Global FileVault constants. Keep platform paths out of the UI layer.
abstract final class AppConstants {
  static const String appName = 'FileVault';
  static const String prefsThemeMode = 'settings.themeMode';
  static const String prefsAccentColor = 'settings.accentColor';
  static const String prefsShowHidden = 'settings.showHiddenFiles';
  static const String prefsTrashAutoCleanDays = 'settings.trashAutoCleanDays';
  static const String prefsConfirmDelete = 'settings.confirmBeforeDelete';
  static const String prefsOnboardingSkipped = 'onboarding.skipped';
  static const String prefsDefaultViewMode = 'settings.defaultViewMode';
  static const String prefsDefaultSort = 'settings.defaultSort';
  static const int minSdk = 26;
  static const int scopedStorageSdk = 30;
  static const int defaultTrashAutoCleanDays = 30;
  static const int defaultAccentColor = 0xFF0B6E99;
}
