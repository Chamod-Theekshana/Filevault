import 'dart:typed_data';

/// Package metadata read from an APK file via the platform channel.
class ApkInfo {
  const ApkInfo({
    required this.packageName,
    required this.appName,
    required this.versionName,
    required this.versionCode,
    required this.minSdk,
    required this.targetSdk,
    this.icon,
    this.permissions = const <String>[],
    this.isInstalled = false,
    this.installedVersionName,
  });

  final String packageName;
  final String appName;
  final String versionName;
  final int versionCode;
  final int minSdk;
  final int targetSdk;
  final Uint8List? icon;
  final List<String> permissions;
  final bool isInstalled;
  final String? installedVersionName;

  static ApkInfo fromMap(Map<Object?, Object?> map) => ApkInfo(
        packageName: (map['packageName'] as String?) ?? '',
        appName: (map['appName'] as String?) ?? '',
        versionName: (map['versionName'] as String?) ?? '',
        versionCode: (map['versionCode'] as num?)?.toInt() ?? 0,
        minSdk: (map['minSdk'] as num?)?.toInt() ?? 0,
        targetSdk: (map['targetSdk'] as num?)?.toInt() ?? 0,
        icon: map['icon'] as Uint8List?,
        permissions: ((map['permissions'] as List<Object?>?) ?? const <Object?>[])
            .map((Object? e) => e.toString())
            .toList(growable: false),
        isInstalled: map['isInstalled'] == true,
        installedVersionName: map['installedVersionName'] as String?,
      );
}
