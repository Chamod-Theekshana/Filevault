# FileVault

An Android file manager built with Flutter — browse, search, organise and
clean up storage, plus a **Secure Folder** that encrypts files on-device with
AES-256-GCM.

The UI follows the FileVault design system (Material 3, Roboto Flex headlines,
Inter body text, semantic category colours) in both light and dark themes.

## Getting started

```bash
flutter pub get
flutter run            # debug build on a connected device
flutter build apk --release
```

Requirements: Flutter 3.27 or newer (Dart 3.8+), Android SDK 26+ (Android 8.0),
JDK 17.

On Android 11+ the app asks for **All files access**
(`MANAGE_EXTERNAL_STORAGE`) during onboarding; on Android 10 and below it uses
the classic storage permission. Without it FileVault still runs, but only sees
its own folders.

## What's inside

| Area | Features |
| --- | --- |
| Home | storage gauge per volume, category tiles, recents, quick-access folders, Secure Folder card |
| Browser | breadcrumbs, list/grid, sort, hidden files, lazy listing, multi-select, in-folder filter |
| Operations | copy / move / delete / compress / extract / encrypt queue with pause, resume, cancel, conflict resolution and a foreground-service notification |
| Trash | app-managed trash with restore, auto-purge countdown and bulk delete |
| Archives | create and browse ZIP / TAR / TAR.GZ / BZ2 / XZ, extract selected entries, password-protected ZIP |
| Search | indexed global search with type, size and date filters, recent searches |
| Analyzer | storage breakdown, largest folders and files, duplicate finder (SHA-256), junk and empty-folder cleaner |
| Secure Folder | PIN + optional biometric unlock, AES-256-GCM chunked encryption, auto-lock, move in/out |
| Viewers | images, video, audio with queue, text/code editor, PDF, APK info |
| Organisation | favorites, recent files, coloured tags, operation history |
| Settings | theme, accent colour, default layout and sort, hidden files, trash retention, security, about |

## Project layout

```
lib/
  core/          constants, DI, errors, router, theme, utils, shared widgets
  domain/        models and repository interfaces (no Flutter, no dart:io)
  data/          services (file system, archive, crypto, platform channel),
                 SQLite database and repository implementations
  features/      one folder per screen: view + view model + widgets
  l10n/          every user-facing string
android/         manifest, Kotlin platform channel and foreground service
```

The architecture is MVVM with Riverpod: views hold no logic, view models never
import `dart:io`, and repositories are the single source of truth. Heavy work
(listing, hashing, archiving, indexing, encryption) runs in worker isolates
with progress and cancellation.

## Tests

```bash
flutter test
```

Covers sorting, file classification and formatting, the file-system service,
the archive engine, vault cryptography (round-trip plus tamper detection),
search filters, the operation queue and widget smoke tests.

## Release build

Add `android/key.properties` to sign with your own key:

```properties
storeFile=/absolute/path/to/keystore.jks
storePassword=…
keyAlias=…
keyPassword=…
```

Without that file the release build falls back to the debug key. Minification
and resource shrinking are on; keep rules live in
`android/app/proguard-rules.pro`.

Play Store note: `MANAGE_EXTERNAL_STORAGE` requires the "File manager"
declaration in the Play Console.
