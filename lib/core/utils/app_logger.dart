import 'package:logger/logger.dart';

/// Shared logger. Data sources may use it; views must not.
final Logger appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 6,
    lineLength: 80,
    colors: false,
  ),
);
