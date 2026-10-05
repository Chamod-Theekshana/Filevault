import 'package:flutter/widgets.dart';

/// Hand-written localization layer.
///
/// All user-facing strings live here so the app stays localization-ready
/// without a code-generation step. Add a new language by subclassing
/// [AppLocalizations] and registering the locale in [supportedLocales].
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('en'));
  }

  // ---------------------------------------------------------------- general
  String get appName => 'FileVault';
  String get ok => 'OK';
  String get cancel => 'Cancel';
  String get save => 'Save';
  String get done => 'Done';
  String get retry => 'Retry';
  String get close => 'Close';
  String get back => 'Back';
  String get next => 'Next';
  String get skip => 'Skip';
  String get create => 'Create';
  String get rename => 'Rename';
  String get delete => 'Delete';
  String get copy => 'Copy';
  String get move => 'Move';
  String get share => 'Share';
  String get more => 'More';
  String get select => 'Select';
  String get selectedLabel => 'Selected';
  String get selectAll => 'Select all';
  String get invertSelection => 'Invert selection';
  String get clearSelection => 'Clear selection';
  String get viewAll => 'View all';
  String get review => 'Review';
  String get clean => 'Clean';
  String get enable => 'Enable';
  String get restore => 'Restore';
  String get remove => 'Remove';
  String get open => 'Open';
  String get openWith => 'Open with';
  String get search => 'Search';
  String get settings => 'Settings';
  String get loading => 'Loading…';
  String get unknown => 'Unknown';
  String get yes => 'Yes';
  String get no => 'No';
  String get items => 'items';
  String get today => 'Today';
  String get yesterday => 'Yesterday';
  String get never => 'Never';
  String get copied => 'Copied to clipboard';
  String get somethingWentWrong => 'Something went wrong';
  String get notNow => 'Not now';
  String get apply => 'Apply';
  String get reset => 'Reset';
  String get all => 'All';
  String get folder => 'Folder';
  String get file => 'File';
  String get name => 'Name';
  String get size => 'Size';
  String get date => 'Date';
  String get type => 'Type';
  String get path => 'Path';
  String get modified => 'Modified';
  String get sortBy => 'Sort by';
  String get ascending => 'Ascending';
  String get descending => 'Descending';
  String get foldersFirst => 'Folders first';
  String get listView => 'List view';
  String get gridView => 'Grid view';
  String get showHiddenFiles => 'Show hidden files';
  String get hideHiddenFiles => 'Hide hidden files';
  String get newFolder => 'New folder';
  String get newFile => 'New file';
  String get createArchive => 'Create archive';
  String get addToSecureFolder => 'Move to Secure Folder';
  String get encrypted => 'Encrypted';
  String get readOnly => 'Read-only';
  String get free => 'free';
  String get used => 'used';
  String get ofTotal => 'of';

  String itemCount(int n) => n == 1 ? '1 item' : '$n items';
  String fileCount(int n) => n == 1 ? '1 file' : '$n files';
  String folderCount(int n) => n == 1 ? '1 folder' : '$n folders';
  String selectedCount(int n) => '$n selected';
  String usedOfTotal(String used, String total) => '$used used of $total';
  String freeSpace(String free) => '$free free space';
  String freeIn(String free, String volume) => '$free free in $volume';
  String percentFull(int percent) => '$percent% full';
  String daysLeft(int d) => d == 1 ? '1d left' : '${d}d left';
  String deletedAgo(String ago) => 'Deleted $ago';
  String fromPath(String path) => 'from $path';
  String inFolder(String folder) => 'in $folder';

  // ----------------------------------------------------------------- nav
  String get navHome => 'Home';
  String get navBrowse => 'Browse';
  String get navSearch => 'Search';
  String get navSettings => 'Settings';

  // ---------------------------------------------------------- onboarding
  String get permissionSetup => 'Permission Setup';
  String get storageAccess => 'STORAGE ACCESS';
  String stepOf(int step, int total) => 'Step $step of $total';
  String get permissionTitle => 'Allow access to manage files';
  String get permissionBody =>
      'FileVault needs All Files Access to browse, organize, encrypt and safeguard your documents, photos and media across internal and SD card storage.';
  String get permissionLegacyBody =>
      'FileVault needs storage permission to browse, organize, encrypt and safeguard your documents, photos and media.';
  String get permissionFeatureBrowse => 'Browse & organize all folders';
  String get permissionFeatureBrowseSub =>
      'Full directory tree support with zero blind spots';
  String get permissionFeatureVault => 'Local AES-256 encryption';
  String get permissionFeatureVaultSub =>
      'Hardware-backed vault for private files';
  String get permissionFeatureClean => 'Clean junk & duplicates safely';
  String get permissionFeatureCleanSub =>
      'Reclaim space from lingering temp files';
  String get permissionPrivacyNote =>
      'Your files never leave your device. FileVault works 100% offline with zero cloud tracking.';
  String get grantAccess => 'Grant access';
  String get openSystemSettings => 'Open system settings';
  String get permissionDeniedTitle => 'Access was denied';
  String get permissionDeniedBody =>
      'Without storage access FileVault can only show its own folders. You can grant access any time from Settings.';
  String get permissionPermanentlyDenied =>
      'Permission is blocked. Enable "All files access" for FileVault in system settings.';
  String get continueLimited => 'Continue with limited access';

  // ---------------------------------------------------------------- home
  String get internalStorage => 'Internal storage';
  String get sdCard => 'SD card';
  String get usbStorage => 'USB storage';
  String get cleanUp => 'Clean Up';
  String get eject => 'Eject';
  String get categories => 'Categories';
  String categoriesCount(int n) => '$n categories';
  String get recentFiles => 'Recent files';
  String get noRecentFiles =>
      'Files you open will show up here for quick access.';
  String get quickAccess => 'Quick access';
  String get quickAccessMore => 'Quick access options';
  String get favorites => 'Favorites';
  String get secureFolder => 'Secure Folder';
  String get tags => 'Tags';
  String get operationsHistory => 'Operations';

  // ---------------------------------------------------------- categories
  String get categoryImages => 'Images';
  String get categoryVideos => 'Videos';
  String get categoryAudio => 'Audio';
  String get categoryDocuments => 'Documents';
  String get categoryDownloads => 'Downloads';
  String get categoryApks => 'APKs & Apps';
  String get categoryArchives => 'Archives';
  String get categoryTrash => 'Trash';
  String get categoryFolders => 'Folders';
  String get categoryOther => 'Other';
  String get categoryAppsSystem => 'Apps & System';

  // ------------------------------------------------------------- browser
  String get folders => 'FOLDERS';
  String get files => 'FILES';
  String get recentMedia => 'RECENT MEDIA';
  String get filter => 'Filter';
  String get recent => 'Recent';
  String get emptyFolderTitle => 'This folder is empty';
  String get emptyFolderBody =>
      'Drop files here by copying or moving them from another folder.';
  String get restrictedFolderTitle => 'Restricted by Android';
  String get restrictedFolderBody =>
      'Android does not allow apps to read this folder on newer versions. Use a computer or the system Files app to inspect it.';
  String get cannotReadFolder => 'Unable to read this folder';
  String get folderMarked => 'folder marked';
  String foldersMarked(int n) => n == 1 ? '1 folder marked' : '$n folders marked';
  String filesMarked(int n) => n == 1 ? '1 file marked' : '$n files marked';
  String get totalSelectedVolume => 'Total selected volume';
  String acrossItems(String size, int n) => '$size across ${itemCount(n)}';
  String get ready => 'Ready';
  String get goUp => 'Go to parent folder';
  String get createFolderTitle => 'New folder';
  String get createFileTitle => 'New file';
  String get folderNameHint => 'Folder name';
  String get fileNameHint => 'File name';
  String get renameTitle => 'Rename';
  String get nameAlreadyExists => 'A file with that name already exists';
  String get invalidName => 'Name contains characters that are not allowed';
  String get nameEmpty => 'Name cannot be empty';
  String get deleteTitle => 'Move to trash?';
  String deleteBody(int n) =>
      '${itemCount(n)} will be moved to trash. You can restore them later.';
  String get deletePermanentlyTitle => 'Delete permanently?';
  String deletePermanentlyBody(int n) =>
      '${itemCount(n)} will be permanently erased. This cannot be undone.';
  String get moveToTrash => 'Move to trash';
  String get deletePermanently => 'Delete permanently';
  String get duplicate => 'Duplicate';
  String get compressToZip => 'Compress to ZIP';
  String get extract => 'Extract';
  String get extractHere => 'Extract here';
  String get extractTo => 'Extract to…';
  String get addToFavorites => 'Add to favorites';
  String get removeFromFavorites => 'Remove from favorites';
  String get addTags => 'Tags';
  String get properties => 'Properties';
  String get copyPath => 'Copy path';
  String get install => 'Install';
  String get selectDestination => 'Select destination';
  String get pasteHere => 'Paste here';
  String get copyHere => 'Copy here';
  String get moveHere => 'Move here';
  String get chooseFolder => 'Choose folder';
  String movedToTrash(int n) => '${itemCount(n)} moved to trash';
  String get undo => 'Undo';
  String get addedToFavorites => 'Added to favorites';
  String get removedFromFavorites => 'Removed from favorites';
  String get noAppToOpen => 'No app found to open this file';
  String get folderCreated => 'Folder created';
  String get fileCreated => 'File created';
  String get renamed => 'Renamed';

  // ---------------------------------------------------------- properties
  String get propertiesTitle => 'File Properties';
  String get contains => 'Contains';
  String get location => 'Location';
  String get mimeType => 'MIME type';
  String get accessControl => 'Access control';
  String get md5Checksum => 'MD5 checksum';
  String get sha256Checksum => 'SHA-256 checksum';
  String get verify => 'Verify';
  String get computing => 'Computing…';
  String get parentFolder => 'Parent folder';
  String get readable => 'Readable';
  String get writable => 'Writable';
  String get hidden => 'Hidden';

  // ---------------------------------------------------------- operations
  String get operationCopy => 'Copying';
  String get operationMove => 'Moving';
  String get operationDelete => 'Deleting';
  String get operationCompress => 'Compressing';
  String get operationExtract => 'Extracting';
  String get operationEncrypt => 'Encrypting';
  String get operationDecrypt => 'Decrypting';
  String get operationTrash => 'Moving to trash';
  String get operationRestore => 'Restoring';
  String operationFilesCount(String verb, int n) => '$verb ${fileCount(n)}';
  String get pause => 'Pause';
  String get resume => 'Resume';
  String get paused => 'Paused';
  String get queued => 'Queued';
  String get completed => 'Completed';
  String get failed => 'Failed';
  String get cancelled => 'Cancelled';
  String get running => 'Running';
  String ofFiles(int done, int total) => '$done of $total';
  String get operationDone => 'Done';
  String timeLeft(String t) => '$t left';
  String get calculating => 'Calculating…';
  String get noOperations => 'No file operations yet';
  String get noOperationsBody =>
      'Copy, move, compress or extract files and their progress will appear here.';
  String get clearHistory => 'Clear history';
  String get operationFailedTitle => 'Operation failed';

  // ------------------------------------------------------------ conflict
  String get conflictTitle => 'File already exists';
  String conflictBody(String name) =>
      '"$name" already exists in the destination. What would you like to do?';
  String get conflictReplace => 'Replace';
  String get conflictSkip => 'Skip';
  String get conflictKeepBoth => 'Keep both';
  String get conflictApplyToAll => 'Apply to remaining conflicts';
  String conflictPending(int n) => '$n other conflicts pending';
  String get existing => 'Existing';
  String get incoming => 'Incoming';

  // --------------------------------------------------------------- trash
  String get trash => 'Trash';
  String get trashEmptyTitle => 'Trash is empty';
  String trashEmptyBody(int days) =>
      'Items you delete will be kept here for $days days before being permanently removed from your device.';
  String get trashEmptyBodyNever =>
      'Items you delete will be kept here until you remove them yourself.';
  String get browseFiles => 'Browse files';
  String get trashStorage => 'Trash storage';
  String usedInBin(String size) => '$size used in bin';
  String available(String size) => '$size available';
  String get proTip => 'Pro tip';
  String get trashProTip =>
      'Files can still be retrieved any time before the auto-expiration countdown completes.';
  String get autoPurgeActive => 'Auto-purge active';
  String get autoPurgeOff => 'Auto-purge off';
  String autoPurgeBody(int days) =>
      'Items in trash are permanently erased after $days days.';
  String get autoPurgeBodyNever => 'Items stay in trash until you empty it.';
  String get deletedFiles => 'Deleted Files';
  String get emptyTrash => 'Empty';
  String get emptyTrashTitle => 'Empty trash?';
  String emptyTrashBody(int n) =>
      '${itemCount(n)} will be permanently erased. This cannot be undone.';
  String restoreCount(int n) => 'Restore ($n)';
  String get restored => 'Restored';
  String get restoreFailed => 'Could not restore some items';
  String get originalLocationMissing =>
      'The original folder no longer exists, so the item was restored to Downloads';
  String get expiresSoon => 'Expires soon';
  String nDays(int n) => n == 1 ? '1 day' : '$n days';

  // ------------------------------------------------------------- archive
  String get archiveMode => 'Archive Mode (Read-only)';
  String get contents => 'Contents';
  String extractSelected(int n) => 'Extract selected ($n)';
  String get extractAll => 'Extract all';
  String get archiveName => 'Archive name';
  String get format => 'Format';
  String get compressionLevel => 'Compression level';
  String get compressionStore => 'Store';
  String get compressionFast => 'Fast';
  String get compressionNormal => 'Normal';
  String get compressionBest => 'Best';
  String get setPassword => 'Set password (Optional)';
  String get passwordNote =>
      'Leaves file names visible while locking content payloads.';
  String get deleteSourceAfterArchive => 'Delete source files after archive';
  String deleteSourceSub(String size) => 'Frees up $size on this storage';
  String get archivePasswordTitle => 'Archive is encrypted';
  String get archivePasswordBody => 'Enter the password to read this archive.';
  String get password => 'Password';
  String get wrongPassword => 'Wrong password or corrupted archive';
  String get unsupportedArchive =>
      'This archive format is not supported yet. ZIP, TAR, GZ, TGZ and BZ2 archives can be opened.';
  String get archiveCreated => 'Archive created';
  String get extractionComplete => 'Extraction complete';
  String get archiveCorrupt => 'This archive appears to be damaged';
  String get openArchive => 'Browse archive';

  // -------------------------------------------------------------- search
  String get searchHint => 'Search files and folders';
  String get recentSearches => 'Recent searches';
  String get clearAll => 'Clear all';
  String resultsFor(String q) => "Results for '$q'";
  String found(int n) => '$n found';
  String get noResultsTitle => 'Nothing matched';
  String get noResultsBody =>
      'Try a different spelling, remove filters or run a deep scan to index new files.';
  String get deepScan => 'Deep Vault Scan';
  String get deepScanBody => 'Re-index every folder, including hidden files';
  String get scan => 'Scan';
  String get scanning => 'Scanning…';
  String indexedFiles(int n) => '$n files indexed';
  String get searchFilters => 'Search filters';
  String get sizeRange => 'Size';
  String get dateRange => 'Modified';
  String get anySize => 'Any size';
  String get sizeSmall => '< 1 MB';
  String get sizeMedium => '1 – 100 MB';
  String get sizeLarge => '> 100 MB';
  String get anyDate => 'Any time';
  String get last7Days => 'Last 7 days';
  String get last30Days => 'Last 30 days';
  String get thisYear => 'This year';
  String get searchInCurrentFolder => 'Search in this folder';
  String get indexEmptyTitle => 'Index not built yet';
  String get indexEmptyBody =>
      'Run a scan once so global search can find files instantly.';

  // ------------------------------------------------------------ analyzer
  String get storageBreakdown => 'Storage Breakdown';
  String get usedLabel => 'Used';
  String get optimizationTools => 'Optimization Tools';
  String get optimizationSub => 'Free up space with smart recommendations';
  String recoverable(String size) => '$size recoverable';
  String get largeFiles => 'Large files';
  String largeFilesSub(int n, String limit) => '$n files over $limit';
  String get duplicateFiles => 'Duplicate files';
  String duplicatesSub(int n) => '$n duplicate files';
  String get junkCache => 'Junk & cache';
  String get junkSub => 'Temporary files & logs';
  String get emptyFolders => 'Empty folders';
  String emptyFoldersSub(int n) => '$n unused directory paths';
  String get smartSweep => 'Smart Deep Sweep';
  String get smartSweepBody => 'Scan all storage for junk in one tap';
  String get largestFolders => 'Largest folders';
  String get analyzing => 'Analyzing storage…';
  String get duplicatesEmpty => 'No duplicates found. Your storage is tidy.';
  String get largeFilesEmpty => 'No large files found.';
  String get junkEmpty => 'Nothing to clean right now.';
  String get emptyFoldersEmpty => 'No empty folders found.';
  String duplicateGroup(int n, String size) => '$n copies • $size each';
  String get keepNewest => 'Keep newest';
  String get keepOldest => 'Keep oldest';
  String get selectAllButOne => 'Select all but first';
  String deleteSelected(int n) => 'Delete selected ($n)';
  String cleanSelected(String size) => 'Clean $size';
  String get cleanJunkTitle => 'Clean junk?';
  String cleanJunkBody(int n, String size) =>
      '${itemCount(n)} ($size) will be permanently deleted. Apps will rebuild their cache when needed.';
  String get cleaned => 'Cleaned';
  String get junkCacheKind => 'App cache';
  String get junkTempKind => 'Temporary file';
  String get junkLogKind => 'Log file';
  String get junkThumbKind => 'Thumbnail cache';
  String get junkEmptyFolderKind => 'Empty folder';
  String get rescan => 'Rescan';

  // -------------------------------------------------------------- viewer
  String get mediaViewer => 'Media Viewer';
  String get documentReader => 'Document Reader';
  String get nowPlaying => 'Now Playing';
  String fromFolder(String folder) => 'From $folder';
  String get upNext => 'Up Next';
  String get audioRoute => 'AUDIO ROUTE';
  String get speakerRoute => 'Device speaker';
  String get edit => 'Edit';
  String get favorite => 'Favorite';
  String get rotate => 'Rotate';
  String get info => 'Info';
  String ofCount(int i, int n) => '$i of $n';
  String get doubleTapToZoom => 'Double tap to zoom';
  String get edited => 'Edited';
  String get unsaved => 'Unsaved';
  String get saved => 'Saved';
  String get readWrite => 'Read & Write';
  String get encoding => 'Encoding';
  String get wordWrap => 'Word wrap';
  String get lineNumbers => 'Line numbers';
  String lnCol(int ln, int col) => 'Ln $ln, Col $col';
  String bytesCount(int n) => '$n bytes';
  String get fileTooLargeToEdit =>
      'This file is too large to open in the editor (limit 4 MB).';
  String get discardChanges => 'Discard changes?';
  String get discardChangesBody => 'Unsaved edits will be lost.';
  String get discard => 'Discard';
  String get cannotPlay => 'This media cannot be played';
  String get apkInfo => 'APK Info';
  String get packageName => 'Package';
  String get version => 'Version';
  String get minSdk => 'Minimum Android';
  String get targetSdk => 'Target Android';
  String get installApk => 'Install';
  String get installApkBody =>
      'Android will ask you to confirm the installation. Only install apps you trust.';
  String pageOf(int p, int n) => 'Page $p of $n';

  // --------------------------------------------------------------- vault
  String get vaultTitle => 'Secure Folder';
  String get vaultSubtitle => 'AES-256 encrypted, offline';
  String get vaultSetupTitle => 'Set up your Secure Folder';
  String get vaultSetupBody =>
      'Choose a 6-digit PIN. Files you move here are encrypted with AES-256-GCM and hidden from every other app.';
  String get vaultCreatePin => 'Create PIN';
  String get vaultConfirmPin => 'Confirm PIN';
  String get vaultEnterPin => 'Enter PIN';
  String get vaultPinMismatch => 'PINs do not match. Try again.';
  String get vaultWrongPin => 'Wrong PIN';
  String vaultAttemptsLeft(int n) => '$n attempts left';
  String vaultLockedFor(int s) => 'Too many attempts. Try again in ${s}s';
  String get vaultUnlockBiometric => 'Unlock with fingerprint';
  String get vaultBiometricReason => 'Unlock your Secure Folder';
  String get vaultEnableBiometric => 'Use fingerprint to unlock';
  String get vaultEnableBiometricSub => 'Keep PIN as a backup';
  String get vaultEmptyTitle => 'Your vault is empty';
  String get vaultEmptyBody =>
      'Add photos, videos or documents. They are encrypted on-device and removed from their original location.';
  String get vaultAddFiles => 'Add files';
  String get vaultExport => 'Move out of vault';
  String get vaultExportTitle => 'Move out of vault?';
  String vaultExportBody(int n) =>
      '${itemCount(n)} will be decrypted and restored to their original folder.';
  String get vaultDeleteTitle => 'Delete from vault?';
  String vaultDeleteBody(int n) =>
      '${itemCount(n)} will be permanently erased. There is no trash for encrypted files.';
  String get vaultLock => 'Lock';
  String get vaultLocked => 'Vault locked';
  String get vaultChangePin => 'Change PIN';
  String get vaultCurrentPin => 'Current PIN';
  String get vaultNewPin => 'New PIN';
  String get vaultPinChanged => 'PIN updated';
  String get vaultAutoLock => 'Auto-lock';
  String get vaultAutoLockSub => 'Lock when the app goes to the background';
  String vaultAfterMinutes(int m) => m == 0 ? 'Immediately' : 'After $m min';
  String vaultAdded(int n) => '${itemCount(n)} secured';
  String vaultExported(int n) => '${itemCount(n)} moved out';
  String get vaultForgotPin => 'Forgot PIN?';
  String get vaultForgotPinBody =>
      'The PIN cannot be recovered. Resetting the vault permanently destroys every file inside it.';
  String get vaultReset => 'Reset vault';
  String get vaultDecrypting => 'Decrypting…';
  String get vaultOpenFailed => 'Could not open this file';
  String get vaultStorageUsed => 'Vault size';
  String get vaultNotSetUp => 'Not set up';
  String get vaultSecuredWithPin => 'Protected with PIN';
  String get vaultPickFiles => 'Choose files to secure';
  String get vaultHiddenNote =>
      'Encrypted files are stored inside FileVault\'s private storage and are never indexed by the gallery.';

  // ------------------------------------------------------------ settings
  String get settingsTitle => 'FileVault Settings';
  String get allFilesAccess => 'All Files Access';
  String get granted => 'Granted';
  String get notGranted => 'Not granted';
  String get allFilesAccessSub => 'Unrestricted management on internal & SD card';
  String get allFilesAccessMissing =>
      'FileVault can only see its own folders until access is granted';
  String get scopedStorageNote => 'Scoped storage compliance';
  String get systemAppInfo => 'System App Info';
  String get appearance => 'APPEARANCE';
  String get theme => 'Theme';
  String get themeSub => 'Adjust contrast and ambient tone';
  String get themeSystem => 'System';
  String get themeLight => 'Light';
  String get themeDark => 'Dark';
  String get accentColor => 'Accent Color';
  String accentCurrent(String name) => name;
  String get accentOcean => 'Ocean Blue (System default)';
  String get accentForest => 'Forest Green';
  String get accentViolet => 'Violet';
  String get accentRose => 'Rose';
  String get accentAmber => 'Amber';
  String get browsing => 'BROWSING';
  String get defaultLayout => 'Default layout';
  String get sortOrder => 'Sort order';
  String get showHiddenSub => 'Files starting with dot (.)';
  String get confirmDeletion => 'Confirm file deletion';
  String get confirmDeletionSub => 'Show prompt when moving items to trash';
  String get trashAndStorage => 'TRASH & STORAGE';
  String get autoCleanTrash => 'Auto-clean trash';
  String get autoCleanTrashSub => 'Permanently erase files past expiration';
  String get security => 'SECURITY';
  String get about => 'ABOUT';
  String versionLabel(String v) => 'Version $v';
  String get privacyAndEncryption => 'Privacy & Encryption';
  String get privacySub => 'Local-first storage, AES-256 standard';
  String get privacyBody =>
      'FileVault never uploads your files. Everything – browsing, search indexing, hashing and encryption – runs on this device. The Secure Folder uses AES-256-GCM with a key derived from your PIN (PBKDF2-HMAC-SHA256, 120,000 rounds). Nothing leaves the phone.';
  String get openSourceLicenses => 'Open source licenses';
  String get licensesSub => 'Third-party notices and attributions';
  String get language => 'Language';
  String get languageEnglish => 'English';
  String get release => 'Release';
  String get resetIndex => 'Rebuild search index';
  String get resetIndexSub => 'Clears and rebuilds the search database';
  String get indexRebuilt => 'Index rebuilt';

  // --------------------------------------------------------- collections
  String get favoritesEmptyTitle => 'No favorites yet';
  String get favoritesEmptyBody =>
      'Long-press any file or folder and choose "Add to favorites".';
  String get recentsEmptyTitle => 'No recent files';
  String get recentsEmptyBody => 'Files you open will show up here.';
  String get clearRecents => 'Clear recents';
  String get tagsEmptyTitle => 'No tags yet';
  String get tagsEmptyBody => 'Create colored tags to group files across folders.';
  String get newTag => 'New tag';
  String get tagName => 'Tag name';
  String get tagColor => 'Color';
  String get editTag => 'Edit tag';
  String get deleteTag => 'Delete tag';
  String get assignTags => 'Assign tags';
  String get noTagsAssigned => 'No tags assigned';
  String taggedFiles(int n) => n == 1 ? '1 file' : '$n files';

  // -------------------------------------------------------------- errors
  String get errorPermission => 'Permission denied';
  String get errorNotFound => 'File not found';
  String get errorDiskFull => 'Not enough free space';
  String get errorNameTooLong => 'Name is too long';
  String get errorExists => 'Already exists';
  String get errorIo => 'Could not complete the file operation';
  String get errorUnknown => 'Unexpected error';
  String get errorCancelled => 'Cancelled';
  String get errorSameFolder => 'Source and destination are the same';
  String get errorIntoItself => 'Cannot move a folder into itself';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .any((Locale l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
