// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'operation_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OperationTask {

 String get id; OperationType get type; List<String> get sourcePaths; String? get destinationPath; OperationStatus get status; int get totalFiles; int get processedFiles; int get totalBytes; int get processedBytes; double get currentSpeedBytesPerSecond; String? get conflictFilePath; String? get errorMessage;
/// Create a copy of OperationTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OperationTaskCopyWith<OperationTask> get copyWith => _$OperationTaskCopyWithImpl<OperationTask>(this as OperationTask, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OperationTask;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OperationTask&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&const DeepCollectionEquality().equals(other.sourcePaths, _this.sourcePaths)&&(identical(other.destinationPath, _this.destinationPath) || other.destinationPath == _this.destinationPath)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.totalFiles, _this.totalFiles) || other.totalFiles == _this.totalFiles)&&(identical(other.processedFiles, _this.processedFiles) || other.processedFiles == _this.processedFiles)&&(identical(other.totalBytes, _this.totalBytes) || other.totalBytes == _this.totalBytes)&&(identical(other.processedBytes, _this.processedBytes) || other.processedBytes == _this.processedBytes)&&(identical(other.currentSpeedBytesPerSecond, _this.currentSpeedBytesPerSecond) || other.currentSpeedBytesPerSecond == _this.currentSpeedBytesPerSecond)&&(identical(other.conflictFilePath, _this.conflictFilePath) || other.conflictFilePath == _this.conflictFilePath)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage));
}


@override
int get hashCode {
  final _this = this as OperationTask;
  return Object.hash(runtimeType,_this.id,_this.type,const DeepCollectionEquality().hash(_this.sourcePaths),_this.destinationPath,_this.status,_this.totalFiles,_this.processedFiles,_this.totalBytes,_this.processedBytes,_this.currentSpeedBytesPerSecond,_this.conflictFilePath,_this.errorMessage);
}

@override
String toString() {
  final _this = this as OperationTask;
  return 'OperationTask(id: ${_this.id}, type: ${_this.type}, sourcePaths: ${_this.sourcePaths}, destinationPath: ${_this.destinationPath}, status: ${_this.status}, totalFiles: ${_this.totalFiles}, processedFiles: ${_this.processedFiles}, totalBytes: ${_this.totalBytes}, processedBytes: ${_this.processedBytes}, currentSpeedBytesPerSecond: ${_this.currentSpeedBytesPerSecond}, conflictFilePath: ${_this.conflictFilePath}, errorMessage: ${_this.errorMessage})';
}


}

/// @nodoc
abstract mixin class $OperationTaskCopyWith<$Res>  {
  factory $OperationTaskCopyWith(OperationTask value, $Res Function(OperationTask) _then) = _$OperationTaskCopyWithImpl;
@useResult
$Res call({
 String id, OperationType type, List<String> sourcePaths, String? destinationPath, OperationStatus status, int totalFiles, int processedFiles, int totalBytes, int processedBytes, double currentSpeedBytesPerSecond, String? conflictFilePath, String? errorMessage
});




}
/// @nodoc
class _$OperationTaskCopyWithImpl<$Res>
    implements $OperationTaskCopyWith<$Res> {
  _$OperationTaskCopyWithImpl(this._self, this._then);

  final OperationTask _self;
  final $Res Function(OperationTask) _then;

/// Create a copy of OperationTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? sourcePaths = null,Object? destinationPath = freezed,Object? status = null,Object? totalFiles = null,Object? processedFiles = null,Object? totalBytes = null,Object? processedBytes = null,Object? currentSpeedBytesPerSecond = null,Object? conflictFilePath = freezed,Object? errorMessage = freezed,}) {
  return _then(OperationTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OperationType,sourcePaths: null == sourcePaths ? _self.sourcePaths : sourcePaths // ignore: cast_nullable_to_non_nullable
as List<String>,destinationPath: freezed == destinationPath ? _self.destinationPath : destinationPath // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OperationStatus,totalFiles: null == totalFiles ? _self.totalFiles : totalFiles // ignore: cast_nullable_to_non_nullable
as int,processedFiles: null == processedFiles ? _self.processedFiles : processedFiles // ignore: cast_nullable_to_non_nullable
as int,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,processedBytes: null == processedBytes ? _self.processedBytes : processedBytes // ignore: cast_nullable_to_non_nullable
as int,currentSpeedBytesPerSecond: null == currentSpeedBytesPerSecond ? _self.currentSpeedBytesPerSecond : currentSpeedBytesPerSecond // ignore: cast_nullable_to_non_nullable
as double,conflictFilePath: freezed == conflictFilePath ? _self.conflictFilePath : conflictFilePath // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OperationTask].
extension OperationTaskPatterns on OperationTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OperationTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OperationTask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OperationTask value)  $default,){
final _that = this;
switch (_that) {
case _OperationTask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OperationTask value)?  $default,){
final _that = this;
switch (_that) {
case _OperationTask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  OperationType type,  List<String> sourcePaths,  String? destinationPath,  OperationStatus status,  int totalFiles,  int processedFiles,  int totalBytes,  int processedBytes,  double currentSpeedBytesPerSecond,  String? conflictFilePath,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OperationTask() when $default != null:
return $default(_that.id,_that.type,_that.sourcePaths,_that.destinationPath,_that.status,_that.totalFiles,_that.processedFiles,_that.totalBytes,_that.processedBytes,_that.currentSpeedBytesPerSecond,_that.conflictFilePath,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  OperationType type,  List<String> sourcePaths,  String? destinationPath,  OperationStatus status,  int totalFiles,  int processedFiles,  int totalBytes,  int processedBytes,  double currentSpeedBytesPerSecond,  String? conflictFilePath,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _OperationTask():
return $default(_that.id,_that.type,_that.sourcePaths,_that.destinationPath,_that.status,_that.totalFiles,_that.processedFiles,_that.totalBytes,_that.processedBytes,_that.currentSpeedBytesPerSecond,_that.conflictFilePath,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  OperationType type,  List<String> sourcePaths,  String? destinationPath,  OperationStatus status,  int totalFiles,  int processedFiles,  int totalBytes,  int processedBytes,  double currentSpeedBytesPerSecond,  String? conflictFilePath,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _OperationTask() when $default != null:
return $default(_that.id,_that.type,_that.sourcePaths,_that.destinationPath,_that.status,_that.totalFiles,_that.processedFiles,_that.totalBytes,_that.processedBytes,_that.currentSpeedBytesPerSecond,_that.conflictFilePath,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _OperationTask extends OperationTask {
  const _OperationTask({required this.id, required this.type, required  List<String> sourcePaths, this.destinationPath, this.status = OperationStatus.queued, this.totalFiles = 0, this.processedFiles = 0, this.totalBytes = 0, this.processedBytes = 0, this.currentSpeedBytesPerSecond = 0, this.conflictFilePath, this.errorMessage}): _sourcePaths = sourcePaths,super._();
  

@override final  String id;
@override final  OperationType type;
 final  List<String> _sourcePaths;
@override List<String> get sourcePaths {
  if (_sourcePaths is EqualUnmodifiableListView) return _sourcePaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sourcePaths);
}

@override final  String? destinationPath;
@override@JsonKey() final  OperationStatus status;
@override@JsonKey() final  int totalFiles;
@override@JsonKey() final  int processedFiles;
@override@JsonKey() final  int totalBytes;
@override@JsonKey() final  int processedBytes;
@override@JsonKey() final  double currentSpeedBytesPerSecond;
@override final  String? conflictFilePath;
@override final  String? errorMessage;

/// Create a copy of OperationTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OperationTaskCopyWith<_OperationTask> get copyWith => __$OperationTaskCopyWithImpl<_OperationTask>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OperationTask&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.sourcePaths, _sourcePaths)&&(identical(other.destinationPath, destinationPath) || other.destinationPath == destinationPath)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalFiles, totalFiles) || other.totalFiles == totalFiles)&&(identical(other.processedFiles, processedFiles) || other.processedFiles == processedFiles)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&(identical(other.processedBytes, processedBytes) || other.processedBytes == processedBytes)&&(identical(other.currentSpeedBytesPerSecond, currentSpeedBytesPerSecond) || other.currentSpeedBytesPerSecond == currentSpeedBytesPerSecond)&&(identical(other.conflictFilePath, conflictFilePath) || other.conflictFilePath == conflictFilePath)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,type,const DeepCollectionEquality().hash(_sourcePaths),destinationPath,status,totalFiles,processedFiles,totalBytes,processedBytes,currentSpeedBytesPerSecond,conflictFilePath,errorMessage);
}

@override
String toString() {
    return 'OperationTask(id: $id, type: $type, sourcePaths: $sourcePaths, destinationPath: $destinationPath, status: $status, totalFiles: $totalFiles, processedFiles: $processedFiles, totalBytes: $totalBytes, processedBytes: $processedBytes, currentSpeedBytesPerSecond: $currentSpeedBytesPerSecond, conflictFilePath: $conflictFilePath, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$OperationTaskCopyWith<$Res> implements $OperationTaskCopyWith<$Res> {
  factory _$OperationTaskCopyWith(_OperationTask value, $Res Function(_OperationTask) _then) = __$OperationTaskCopyWithImpl;
@override @useResult
$Res call({
 String id, OperationType type, List<String> sourcePaths, String? destinationPath, OperationStatus status, int totalFiles, int processedFiles, int totalBytes, int processedBytes, double currentSpeedBytesPerSecond, String? conflictFilePath, String? errorMessage
});




}
/// @nodoc
class __$OperationTaskCopyWithImpl<$Res>
    implements _$OperationTaskCopyWith<$Res> {
  __$OperationTaskCopyWithImpl(this._self, this._then);

  final _OperationTask _self;
  final $Res Function(_OperationTask) _then;

/// Create a copy of OperationTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? sourcePaths = null,Object? destinationPath = freezed,Object? status = null,Object? totalFiles = null,Object? processedFiles = null,Object? totalBytes = null,Object? processedBytes = null,Object? currentSpeedBytesPerSecond = null,Object? conflictFilePath = freezed,Object? errorMessage = freezed,}) {
  return _then(_OperationTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OperationType,sourcePaths: null == sourcePaths ? _self._sourcePaths : sourcePaths // ignore: cast_nullable_to_non_nullable
as List<String>,destinationPath: freezed == destinationPath ? _self.destinationPath : destinationPath // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OperationStatus,totalFiles: null == totalFiles ? _self.totalFiles : totalFiles // ignore: cast_nullable_to_non_nullable
as int,processedFiles: null == processedFiles ? _self.processedFiles : processedFiles // ignore: cast_nullable_to_non_nullable
as int,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,processedBytes: null == processedBytes ? _self.processedBytes : processedBytes // ignore: cast_nullable_to_non_nullable
as int,currentSpeedBytesPerSecond: null == currentSpeedBytesPerSecond ? _self.currentSpeedBytesPerSecond : currentSpeedBytesPerSecond // ignore: cast_nullable_to_non_nullable
as double,conflictFilePath: freezed == conflictFilePath ? _self.conflictFilePath : conflictFilePath // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
