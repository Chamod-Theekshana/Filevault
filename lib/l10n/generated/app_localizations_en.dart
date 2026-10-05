// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'FileVault';

  @override
  String get navHome => 'Home';

  @override
  String get navBrowse => 'Browse';

  @override
  String get navSearch => 'Search';

  @override
  String get navSettings => 'Settings';

  @override
  String get searchAction => 'Search';

  @override
  String get accountAction => 'Account';

  @override
  String get backAction => 'Go back';

  @override
  String get closeAction => 'Close';

  @override
  String get moreOptions => 'More options';

  @override
  String get splashSemantics => 'FileVault is checking storage access';

  @override
  String get permissionTitle => 'Permission Setup';

  @override
  String get permissionBadge => 'Storage Access';

  @override
  String get permissionStep => 'Step 1 of 2';

  @override
  String get permissionHeadline => 'Allow access to manage files';

  @override
  String get permissionBody =>
      'FileVault requires All Files Access (MANAGE_EXTERNAL_STORAGE) to browse, organize, encrypt, and safeguard your documents, photos, and media across internal and SD card storage.';

  @override
  String get permissionBenefitBrowseTitle => 'Browse & organize all folders';

  @override
  String get permissionBenefitBrowseSubtitle =>
      'Full directory tree support with zero blindspots';

  @override
  String get permissionBenefitEncryptTitle => 'Local AES-256 encryption';

  @override
  String get permissionBenefitEncryptSubtitle =>
      'Hardware-backed vault for private archives';

  @override
  String get permissionBenefitCleanTitle => 'Clean junk & duplicates safely';

  @override
  String get permissionBenefitCleanSubtitle =>
      'Reclaim space from lingering temp files';

  @override
  String get permissionPrivacy =>
      'Your files never leave your device. FileVault operates 100% offline with zero cloud tracking.';

  @override
  String get permissionGrant => 'Grant access';

  @override
  String get permissionNotNow => 'Not now';

  @override
  String get permissionOpeningSettings => 'Opening system settings...';

  @override
  String get permissionDeniedHeadline => 'Storage access was denied';

  @override
  String get permissionDeniedBody =>
      'Without All Files Access, FileVault cannot list, copy, or protect files on this device. You can grant access now or continue with limited features.';

  @override
  String get permissionTryAgain => 'Try again';

  @override
  String get permissionPermanentlyDeniedHeadline => 'Permission is blocked';

  @override
  String get permissionPermanentlyDeniedBody =>
      'All Files Access was permanently denied. Open system settings, tap Permissions, and allow access to all files.';

  @override
  String get permissionOpenSettings => 'Open settings';

  @override
  String get internalStorage => 'Internal storage';

  @override
  String usedOfTotal(String used, String total) {
    return '$used used of $total';
  }

  @override
  String freeSpace(String free) {
    return '$free free space';
  }

  @override
  String percentUsed(String percent) {
    return '$percent%';
  }

  @override
  String get usedLabel => 'used';

  @override
  String get cleanUp => 'Clean Up';

  @override
  String get sdCardOptions => 'SD Card options';

  @override
  String get ejectSdCard => 'Eject SD card';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String categoriesCount(int count) {
    return '$count categories';
  }

  @override
  String get categoryImages => 'Images';

  @override
  String get categoryVideos => 'Videos';

  @override
  String get categoryAudio => 'Audio';

  @override
  String get categoryDocuments => 'Documents';

  @override
  String get categoryDownloads => 'Downloads';

  @override
  String get categoryApks => 'APKs & Apps';

  @override
  String get categoryArchives => 'Archives';

  @override
  String get categoryTrash => 'Trash';

  @override
  String categoryCountSize(String count, String size) {
    return '$count • $size';
  }

  @override
  String get recentFiles => 'Recent files';

  @override
  String get viewAll => 'View all';

  @override
  String get quickAccess => 'Quick access';

  @override
  String get quickAccessMore => 'Quick access options';

  @override
  String get homeEmptyRecents => 'Files you open will show up here';

  @override
  String get browserEmptyTitle => 'This folder is empty';

  @override
  String get browserEmptyBody =>
      'Create a folder or copy files here to get started.';

  @override
  String get searchHint => 'Search files, folders, types';

  @override
  String get searchEmptyTitle => 'Search your vault';

  @override
  String get searchEmptyBody =>
      'Find files by name, type, size, or date. Indexing starts after storage access is granted.';

  @override
  String get settingsTitle => 'Filevault Settings';

  @override
  String get settingsSearch => 'Search settings';

  @override
  String get allFilesAccess => 'All Files Access';

  @override
  String get allFilesAccessGranted => 'Granted';

  @override
  String get allFilesAccessMissing => 'Not granted';

  @override
  String get allFilesAccessBody =>
      'Required to browse every folder, including SD cards and USB drives.';

  @override
  String get managePermission => 'Manage';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get accentOcean => 'Ocean Blue';

  @override
  String get accentForest => 'Forest Emerald';

  @override
  String get accentViolet => 'Deep Violet';

  @override
  String get accentRose => 'Rose Berry';

  @override
  String get accentAmber => 'Warm Amber';

  @override
  String get browsingSection => 'Browsing';

  @override
  String get defaultViewMode => 'Default view mode';

  @override
  String get defaultSort => 'Default sort';

  @override
  String get showHiddenFiles => 'Show hidden files';

  @override
  String get listView => 'List';

  @override
  String get gridView => 'Grid';

  @override
  String get sortName => 'Name';

  @override
  String get sortSize => 'Size';

  @override
  String get sortDate => 'Date';

  @override
  String get sortType => 'Type';

  @override
  String get trashSection => 'Trash & Storage';

  @override
  String get trashAutoClean => 'Auto-clean trash after';

  @override
  String daysCount(int days) {
    return '$days days';
  }

  @override
  String get never => 'Never';

  @override
  String get confirmBeforeDelete => 'Confirm before delete';

  @override
  String get aboutSection => 'About';

  @override
  String get appVersion => 'Version';

  @override
  String get licenses => 'Licenses';

  @override
  String get privacyOffline => '100% offline · no cloud tracking';

  @override
  String get comingSoonTitle => 'Coming in a later phase';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get recentsTitle => 'Recents';

  @override
  String get archiveTitle => 'Archives';

  @override
  String get analyzerTitle => 'Storage analyzer';

  @override
  String get operationsTitle => 'Operations';

  @override
  String get viewerTitle => 'Viewer';

  @override
  String get unknownValue => '—';
}
