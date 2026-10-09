import 'package:filevault/app.dart';
import 'package:filevault/core/di/providers.dart';
import 'package:filevault/core/utils/app_logger.dart';
import 'package:filevault/data/database/app_database.dart';
import 'package:filevault/data/repositories/settings_repository_impl.dart';
import 'package:filevault/domain/models/app_settings.dart';
import 'package:filevault/features/settings/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.filevault.app.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Open the database and load settings before the first frame so the theme
  // never flashes and repositories can stay synchronous.
  final AppDatabase database = await AppDatabase.open();
  final AppSettings settings = await SettingsRepositoryImpl().load();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    appLogger.e('Flutter error', error: details.exception, stackTrace: details.stack);
  };

  runApp(
    ProviderScope(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(database),
        initialSettingsProvider.overrideWithValue(settings),
      ],
      child: const FileVaultApp(),
    ),
  );
}
