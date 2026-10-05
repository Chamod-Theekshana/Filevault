// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppSettings {

 AppThemeMode get themeMode; int get accentArgb; bool get showHiddenFiles; int get trashAutoCleanDays; bool get confirmBeforeDelete; String get defaultViewMode; String get defaultSort;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.accentArgb, accentArgb) || other.accentArgb == accentArgb)&&(identical(other.showHiddenFiles, showHiddenFiles) || other.showHiddenFiles == showHiddenFiles)&&(identical(other.trashAutoCleanDays, trashAutoCleanDays) || other.trashAutoCleanDays == trashAutoCleanDays)&&(identical(other.confirmBeforeDelete, confirmBeforeDelete) || other.confirmBeforeDelete == confirmBeforeDelete)&&(identical(other.defaultViewMode, defaultViewMode) || other.defaultViewMode == defaultViewMode)&&(identical(other.defaultSort, defaultSort) || other.defaultSort == defaultSort));
}


@override
int get hashCode => Object.hash(runtimeType,themeMode,accentArgb,showHiddenFiles,trashAutoCleanDays,confirmBeforeDelete,defaultViewMode,defaultSort);

@override
String toString() {
  return 'AppSettings(themeMode: $themeMode, accentArgb: $accentArgb, showHiddenFiles: $showHiddenFiles, trashAutoCleanDays: $trashAutoCleanDays, confirmBeforeDelete: $confirmBeforeDelete, defaultViewMode: $defaultViewMode, defaultSort: $defaultSort)';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 AppThemeMode themeMode, int accentArgb, bool showHiddenFiles, int trashAutoCleanDays, bool confirmBeforeDelete, String defaultViewMode, String defaultSort
});




}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeMode = null,Object? accentArgb = null,Object? showHiddenFiles = null,Object? trashAutoCleanDays = null,Object? confirmBeforeDelete = null,Object? defaultViewMode = null,Object? defaultSort = null,}) {
  return _then(_self.copyWith(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,accentArgb: null == accentArgb ? _self.accentArgb : accentArgb // ignore: cast_nullable_to_non_nullable
as int,showHiddenFiles: null == showHiddenFiles ? _self.showHiddenFiles : showHiddenFiles // ignore: cast_nullable_to_non_nullable
as bool,trashAutoCleanDays: null == trashAutoCleanDays ? _self.trashAutoCleanDays : trashAutoCleanDays // ignore: cast_nullable_to_non_nullable
as int,confirmBeforeDelete: null == confirmBeforeDelete ? _self.confirmBeforeDelete : confirmBeforeDelete // ignore: cast_nullable_to_non_nullable
as bool,defaultViewMode: null == defaultViewMode ? _self.defaultViewMode : defaultViewMode // ignore: cast_nullable_to_non_nullable
as String,defaultSort: null == defaultSort ? _self.defaultSort : defaultSort // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AppThemeMode themeMode,  int accentArgb,  bool showHiddenFiles,  int trashAutoCleanDays,  bool confirmBeforeDelete,  String defaultViewMode,  String defaultSort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.themeMode,_that.accentArgb,_that.showHiddenFiles,_that.trashAutoCleanDays,_that.confirmBeforeDelete,_that.defaultViewMode,_that.defaultSort);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AppThemeMode themeMode,  int accentArgb,  bool showHiddenFiles,  int trashAutoCleanDays,  bool confirmBeforeDelete,  String defaultViewMode,  String defaultSort)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.themeMode,_that.accentArgb,_that.showHiddenFiles,_that.trashAutoCleanDays,_that.confirmBeforeDelete,_that.defaultViewMode,_that.defaultSort);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AppThemeMode themeMode,  int accentArgb,  bool showHiddenFiles,  int trashAutoCleanDays,  bool confirmBeforeDelete,  String defaultViewMode,  String defaultSort)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.themeMode,_that.accentArgb,_that.showHiddenFiles,_that.trashAutoCleanDays,_that.confirmBeforeDelete,_that.defaultViewMode,_that.defaultSort);case _:
  return null;

}
}

}

/// @nodoc


class _AppSettings implements AppSettings {
  const _AppSettings({this.themeMode = AppThemeMode.system, this.accentArgb = 0xFF0B6E99, this.showHiddenFiles = false, this.trashAutoCleanDays = 30, this.confirmBeforeDelete = true, this.defaultViewMode = 'list', this.defaultSort = 'name'});
  

@override@JsonKey() final  AppThemeMode themeMode;
@override@JsonKey() final  int accentArgb;
@override@JsonKey() final  bool showHiddenFiles;
@override@JsonKey() final  int trashAutoCleanDays;
@override@JsonKey() final  bool confirmBeforeDelete;
@override@JsonKey() final  String defaultViewMode;
@override@JsonKey() final  String defaultSort;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.accentArgb, accentArgb) || other.accentArgb == accentArgb)&&(identical(other.showHiddenFiles, showHiddenFiles) || other.showHiddenFiles == showHiddenFiles)&&(identical(other.trashAutoCleanDays, trashAutoCleanDays) || other.trashAutoCleanDays == trashAutoCleanDays)&&(identical(other.confirmBeforeDelete, confirmBeforeDelete) || other.confirmBeforeDelete == confirmBeforeDelete)&&(identical(other.defaultViewMode, defaultViewMode) || other.defaultViewMode == defaultViewMode)&&(identical(other.defaultSort, defaultSort) || other.defaultSort == defaultSort));
}


@override
int get hashCode => Object.hash(runtimeType,themeMode,accentArgb,showHiddenFiles,trashAutoCleanDays,confirmBeforeDelete,defaultViewMode,defaultSort);

@override
String toString() {
  return 'AppSettings(themeMode: $themeMode, accentArgb: $accentArgb, showHiddenFiles: $showHiddenFiles, trashAutoCleanDays: $trashAutoCleanDays, confirmBeforeDelete: $confirmBeforeDelete, defaultViewMode: $defaultViewMode, defaultSort: $defaultSort)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 AppThemeMode themeMode, int accentArgb, bool showHiddenFiles, int trashAutoCleanDays, bool confirmBeforeDelete, String defaultViewMode, String defaultSort
});




}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? themeMode = null,Object? accentArgb = null,Object? showHiddenFiles = null,Object? trashAutoCleanDays = null,Object? confirmBeforeDelete = null,Object? defaultViewMode = null,Object? defaultSort = null,}) {
  return _then(_AppSettings(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,accentArgb: null == accentArgb ? _self.accentArgb : accentArgb // ignore: cast_nullable_to_non_nullable
as int,showHiddenFiles: null == showHiddenFiles ? _self.showHiddenFiles : showHiddenFiles // ignore: cast_nullable_to_non_nullable
as bool,trashAutoCleanDays: null == trashAutoCleanDays ? _self.trashAutoCleanDays : trashAutoCleanDays // ignore: cast_nullable_to_non_nullable
as int,confirmBeforeDelete: null == confirmBeforeDelete ? _self.confirmBeforeDelete : confirmBeforeDelete // ignore: cast_nullable_to_non_nullable
as bool,defaultViewMode: null == defaultViewMode ? _self.defaultViewMode : defaultViewMode // ignore: cast_nullable_to_non_nullable
as String,defaultSort: null == defaultSort ? _self.defaultSort : defaultSort // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
