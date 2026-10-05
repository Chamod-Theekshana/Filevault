/// Storage permission snapshot used by onboarding and the router.
enum StoragePermissionStatus {
  unknown,
  granted,
  denied,
  permanentlyDenied,
  skipped,
}

extension StoragePermissionStatusX on StoragePermissionStatus {
  bool get canEnterApp =>
      this == StoragePermissionStatus.granted ||
      this == StoragePermissionStatus.skipped;

  bool get needsOnboarding =>
      this == StoragePermissionStatus.denied ||
      this == StoragePermissionStatus.permanentlyDenied ||
      this == StoragePermissionStatus.unknown;
}
