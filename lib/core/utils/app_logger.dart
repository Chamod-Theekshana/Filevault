import 'package:logger/logger.dart';

/// Shared logger. Pretty output in debug, compact in release.
final Logger appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 6,
    lineLength: 100,
    colors: false,
    printEmojis: false,
  ),
);
