import 'package:filevault/core/errors/failure.dart';
import 'package:filevault/domain/models/app_settings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_state.freezed.dart';

@freezed
abstract class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(StoragePermissionStatus.unknown) StoragePermissionStatus status,
    @Default(false) bool isBusy,
    Failure? failure,
  }) = _OnboardingState;
}
