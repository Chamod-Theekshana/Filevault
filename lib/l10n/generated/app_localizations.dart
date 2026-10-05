import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'FileVault'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get navBrowse;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @searchAction.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchAction;

  /// No description provided for @accountAction.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountAction;

  /// No description provided for @backAction.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get backAction;

  /// No description provided for @closeAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeAction;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @splashSemantics.
  ///
  /// In en, this message translates to:
  /// **'FileVault is checking storage access'**
  String get splashSemantics;

  /// No description provided for @permissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission Setup'**
  String get permissionTitle;

  /// No description provided for @permissionBadge.
  ///
  /// In en, this message translates to:
  /// **'Storage Access'**
  String get permissionBadge;

  /// No description provided for @permissionStep.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 2'**
  String get permissionStep;

  /// No description provided for @permissionHeadline.
  ///
  /// In en, this message translates to:
  /// **'Allow access to manage files'**
  String get permissionHeadline;

  /// No description provided for @permissionBody.
  ///
  /// In en, this message translates to:
  /// **'FileVault requires All Files Access (MANAGE_EXTERNAL_STORAGE) to browse, organize, encrypt, and safeguard your documents, photos, and media across internal and SD card storage.'**
  String get permissionBody;

  /// No description provided for @permissionBenefitBrowseTitle.
  ///
  /// In en, this message translates to:
  /// **'Browse & organize all folders'**
  String get permissionBenefitBrowseTitle;

  /// No description provided for @permissionBenefitBrowseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full directory tree support with zero blindspots'**
  String get permissionBenefitBrowseSubtitle;

  /// No description provided for @permissionBenefitEncryptTitle.
  ///
  /// In en, this message translates to:
  /// **'Local AES-256 encryption'**
  String get permissionBenefitEncryptTitle;

  /// No description provided for @permissionBenefitEncryptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hardware-backed vault for private archives'**
  String get permissionBenefitEncryptSubtitle;

  /// No description provided for @permissionBenefitCleanTitle.
  ///
  /// In en, this message translates to:
  /// **'Clean junk & duplicates safely'**
  String get permissionBenefitCleanTitle;

  /// No description provided for @permissionBenefitCleanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reclaim space from lingering temp files'**
  String get permissionBenefitCleanSubtitle;

  /// No description provided for @permissionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your files never leave your device. FileVault operates 100% offline with zero cloud tracking.'**
  String get permissionPrivacy;

  /// No description provided for @permissionGrant.
  ///
  /// In en, this message translates to:
  /// **'Grant access'**
  String get permissionGrant;

  /// No description provided for @permissionNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get permissionNotNow;

  /// No description provided for @permissionOpeningSettings.
  ///
  /// In en, this message translates to:
  /// **'Opening system settings...'**
  String get permissionOpeningSettings;

  /// No description provided for @permissionDeniedHeadline.
  ///
  /// In en, this message translates to:
  /// **'Storage access was denied'**
  String get permissionDeniedHeadline;

  /// No description provided for @permissionDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Without All Files Access, FileVault cannot list, copy, or protect files on this device. You can grant access now or continue with limited features.'**
  String get permissionDeniedBody;

  /// No description provided for @permissionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get permissionTryAgain;

  /// No description provided for @permissionPermanentlyDeniedHeadline.
  ///
  /// In en, this message translates to:
  /// **'Permission is blocked'**
  String get permissionPermanentlyDeniedHeadline;

  /// No description provided for @permissionPermanentlyDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'All Files Access was permanently denied. Open system settings, tap Permissions, and allow access to all files.'**
  String get permissionPermanentlyDeniedBody;

  /// No description provided for @permissionOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get permissionOpenSettings;

  /// No description provided for @internalStorage.
  ///
  /// In en, this message translates to:
  /// **'Internal storage'**
  String get internalStorage;

  /// No description provided for @usedOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{used} used of {total}'**
  String usedOfTotal(String used, String total);

  /// No description provided for @freeSpace.
  ///
  /// In en, this message translates to:
  /// **'{free} free space'**
  String freeSpace(String free);

  /// No description provided for @percentUsed.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String percentUsed(String percent);

  /// No description provided for @usedLabel.
  ///
  /// In en, this message translates to:
  /// **'used'**
  String get usedLabel;

  /// No description provided for @cleanUp.
  ///
  /// In en, this message translates to:
  /// **'Clean Up'**
  String get cleanUp;

  /// No description provided for @sdCardOptions.
  ///
  /// In en, this message translates to:
  /// **'SD Card options'**
  String get sdCardOptions;

  /// No description provided for @ejectSdCard.
  ///
  /// In en, this message translates to:
  /// **'Eject SD card'**
  String get ejectSdCard;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @categoriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} categories'**
  String categoriesCount(int count);

  /// No description provided for @categoryImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get categoryImages;

  /// No description provided for @categoryVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get categoryVideos;

  /// No description provided for @categoryAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get categoryAudio;

  /// No description provided for @categoryDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get categoryDocuments;

  /// No description provided for @categoryDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get categoryDownloads;

  /// No description provided for @categoryApks.
  ///
  /// In en, this message translates to:
  /// **'APKs & Apps'**
  String get categoryApks;

  /// No description provided for @categoryArchives.
  ///
  /// In en, this message translates to:
  /// **'Archives'**
  String get categoryArchives;

  /// No description provided for @categoryTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get categoryTrash;

  /// No description provided for @categoryCountSize.
  ///
  /// In en, this message translates to:
  /// **'{count} • {size}'**
  String categoryCountSize(String count, String size);

  /// No description provided for @recentFiles.
  ///
  /// In en, this message translates to:
  /// **'Recent files'**
  String get recentFiles;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick access'**
  String get quickAccess;

  /// No description provided for @quickAccessMore.
  ///
  /// In en, this message translates to:
  /// **'Quick access options'**
  String get quickAccessMore;

  /// No description provided for @homeEmptyRecents.
  ///
  /// In en, this message translates to:
  /// **'Files you open will show up here'**
  String get homeEmptyRecents;

  /// No description provided for @browserEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get browserEmptyTitle;

  /// No description provided for @browserEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create a folder or copy files here to get started.'**
  String get browserEmptyBody;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search files, folders, types'**
  String get searchHint;

  /// No description provided for @searchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Search your vault'**
  String get searchEmptyTitle;

  /// No description provided for @searchEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Find files by name, type, size, or date. Indexing starts after storage access is granted.'**
  String get searchEmptyBody;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Filevault Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search settings'**
  String get settingsSearch;

  /// No description provided for @allFilesAccess.
  ///
  /// In en, this message translates to:
  /// **'All Files Access'**
  String get allFilesAccess;

  /// No description provided for @allFilesAccessGranted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get allFilesAccessGranted;

  /// No description provided for @allFilesAccessMissing.
  ///
  /// In en, this message translates to:
  /// **'Not granted'**
  String get allFilesAccessMissing;

  /// No description provided for @allFilesAccessBody.
  ///
  /// In en, this message translates to:
  /// **'Required to browse every folder, including SD cards and USB drives.'**
  String get allFilesAccessBody;

  /// No description provided for @managePermission.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get managePermission;

  /// No description provided for @appearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @accentOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean Blue'**
  String get accentOcean;

  /// No description provided for @accentForest.
  ///
  /// In en, this message translates to:
  /// **'Forest Emerald'**
  String get accentForest;

  /// No description provided for @accentViolet.
  ///
  /// In en, this message translates to:
  /// **'Deep Violet'**
  String get accentViolet;

  /// No description provided for @accentRose.
  ///
  /// In en, this message translates to:
  /// **'Rose Berry'**
  String get accentRose;

  /// No description provided for @accentAmber.
  ///
  /// In en, this message translates to:
  /// **'Warm Amber'**
  String get accentAmber;

  /// No description provided for @browsingSection.
  ///
  /// In en, this message translates to:
  /// **'Browsing'**
  String get browsingSection;

  /// No description provided for @defaultViewMode.
  ///
  /// In en, this message translates to:
  /// **'Default view mode'**
  String get defaultViewMode;

  /// No description provided for @defaultSort.
  ///
  /// In en, this message translates to:
  /// **'Default sort'**
  String get defaultSort;

  /// No description provided for @showHiddenFiles.
  ///
  /// In en, this message translates to:
  /// **'Show hidden files'**
  String get showHiddenFiles;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get listView;

  /// No description provided for @gridView.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get gridView;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortName;

  /// No description provided for @sortSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sortSize;

  /// No description provided for @sortDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get sortDate;

  /// No description provided for @sortType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get sortType;

  /// No description provided for @trashSection.
  ///
  /// In en, this message translates to:
  /// **'Trash & Storage'**
  String get trashSection;

  /// No description provided for @trashAutoClean.
  ///
  /// In en, this message translates to:
  /// **'Auto-clean trash after'**
  String get trashAutoClean;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String daysCount(int days);

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @confirmBeforeDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm before delete'**
  String get confirmBeforeDelete;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get appVersion;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @privacyOffline.
  ///
  /// In en, this message translates to:
  /// **'100% offline · no cloud tracking'**
  String get privacyOffline;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming in a later phase'**
  String get comingSoonTitle;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// No description provided for @recentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recents'**
  String get recentsTitle;

  /// No description provided for @archiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archives'**
  String get archiveTitle;

  /// No description provided for @analyzerTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage analyzer'**
  String get analyzerTitle;

  /// No description provided for @operationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get operationsTitle;

  /// No description provided for @viewerTitle.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get viewerTitle;

  /// No description provided for @unknownValue.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get unknownValue;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
