/// Route names. Paths that carry a file-system path pass it as the `path`
/// query parameter (see [withPath]).
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String browse = '/browse';
  static const String search = '/search';
  static const String settings = '/settings';

  static const String category = '/category';
  static const String trash = '/trash';
  static const String favorites = '/favorites';
  static const String recents = '/recents';
  static const String tags = '/tags';
  static const String operations = '/operations';
  static const String analyzer = '/analyzer';
  static const String largeFiles = '/analyzer/large';
  static const String duplicates = '/analyzer/duplicates';
  static const String junk = '/analyzer/junk';
  static const String archive = '/archive';
  static const String vault = '/vault';
  static const String vaultSetup = '/vault/setup';
  static const String imageViewer = '/viewer/image';
  static const String videoViewer = '/viewer/video';
  static const String audioPlayer = '/viewer/audio';
  static const String textEditor = '/viewer/text';
  static const String pdfViewer = '/viewer/pdf';
  static const String apkInfo = '/viewer/apk';

  /// Builds `route?path=<encoded>` (+ extra query params).
  static String withPath(String route, String path, {Map<String, String>? extra}) {
    return Uri(
      path: route,
      queryParameters: <String, String>{'path': path, ...?extra},
    ).toString();
  }
}
