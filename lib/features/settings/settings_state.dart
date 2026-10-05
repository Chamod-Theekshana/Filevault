import 'package:filevault/domain/models/app_settings.dart';
import 'package:filevault/domain/models/storage_permission_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_state.freezed.dart';

@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default(AppSettings()) AppSettings settings,
    @Default('1.0.0') String versionLabel,
    @Default(StoragePermissionStatus.unknown) StoragePermissionStatus permissionStatus,
  }) = _SettingsState;
}

class AccentOption {
  const AccentOption(this.argb, this.labelKey);

  final int argb;
  final String labelKey;

  static const List<AccentOption> all = <AccentOption>[
    AccentOption(0xFF0B6E99, 'accentOcean'),
    AccentOption(0xFF2E7D32, 'accentForest'),
    AccentOption(0xFF6750A4, 'accentViolet'),
    AccentOption(0xFFC2185B, 'accentRose'),
    AccentOption(0xFFE65100, 'accentAmber'),
  ];
}
