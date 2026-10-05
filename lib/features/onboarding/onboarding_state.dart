import 'package:filevault/core/errors/failure.dart';
import 'package:filevault/domain/models/storage_permission_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_state.freezed.dart';

@freezed
class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(StoragePermissionStatus.unknown) StoragePermissionStatus status,
    @Default(false) bool isBusy,
    Failure? failure,
  }) = _OnboardingState;
}
