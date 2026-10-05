// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'operation_queue_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OperationQueueState {

 List<OperationTask> get tasks; bool get isMinimized;
/// Create a copy of OperationQueueState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OperationQueueStateCopyWith<OperationQueueState> get copyWith => _$OperationQueueStateCopyWithImpl<OperationQueueState>(this as OperationQueueState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OperationQueueState&&const DeepCollectionEquality().equals(other.tasks, tasks)&&(identical(other.isMinimized, isMinimized) || other.isMinimized == isMinimized));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(tasks),isMinimized);

@override
String toString() {
  return 'OperationQueueState(tasks: $tasks, isMinimized: $isMinimized)';
}


}

/// @nodoc
abstract mixin class $OperationQueueStateCopyWith<$Res>  {
  factory $OperationQueueStateCopyWith(OperationQueueState value, $Res Function(OperationQueueState) _then) = _$OperationQueueStateCopyWithImpl;
@useResult
$Res call({
 List<OperationTask> tasks, bool isMinimized
});




}
/// @nodoc
class _$OperationQueueStateCopyWithImpl<$Res>
    implements $OperationQueueStateCopyWith<$Res> {
  _$OperationQueueStateCopyWithImpl(this._self, this._then);

  final OperationQueueState _self;
  final $Res Function(OperationQueueState) _then;

/// Create a copy of OperationQueueState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tasks = null,Object? isMinimized = null,}) {
  return _then(_self.copyWith(
tasks: null == tasks ? _self.tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<OperationTask>,isMinimized: null == isMinimized ? _self.isMinimized : isMinimized // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [OperationQueueState].
extension OperationQueueStatePatterns on OperationQueueState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OperationQueueState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OperationQueueState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OperationQueueState value)  $default,){
final _that = this;
switch (_that) {
case _OperationQueueState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OperationQueueState value)?  $default,){
final _that = this;
switch (_that) {
case _OperationQueueState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<OperationTask> tasks,  bool isMinimized)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OperationQueueState() when $default != null:
return $default(_that.tasks,_that.isMinimized);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<OperationTask> tasks,  bool isMinimized)  $default,) {final _that = this;
switch (_that) {
case _OperationQueueState():
return $default(_that.tasks,_that.isMinimized);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<OperationTask> tasks,  bool isMinimized)?  $default,) {final _that = this;
switch (_that) {
case _OperationQueueState() when $default != null:
return $default(_that.tasks,_that.isMinimized);case _:
  return null;

}
}

}

/// @nodoc


class _OperationQueueState extends OperationQueueState {
  const _OperationQueueState({final  List<OperationTask> tasks = const [], this.isMinimized = false}): _tasks = tasks,super._();
  

 final  List<OperationTask> _tasks;
@override@JsonKey() List<OperationTask> get tasks {
  if (_tasks is EqualUnmodifiableListView) return _tasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tasks);
}

@override@JsonKey() final  bool isMinimized;

/// Create a copy of OperationQueueState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OperationQueueStateCopyWith<_OperationQueueState> get copyWith => __$OperationQueueStateCopyWithImpl<_OperationQueueState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OperationQueueState&&const DeepCollectionEquality().equals(other._tasks, _tasks)&&(identical(other.isMinimized, isMinimized) || other.isMinimized == isMinimized));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tasks),isMinimized);

@override
String toString() {
  return 'OperationQueueState(tasks: $tasks, isMinimized: $isMinimized)';
}


}

/// @nodoc
abstract mixin class _$OperationQueueStateCopyWith<$Res> implements $OperationQueueStateCopyWith<$Res> {
  factory _$OperationQueueStateCopyWith(_OperationQueueState value, $Res Function(_OperationQueueState) _then) = __$OperationQueueStateCopyWithImpl;
@override @useResult
$Res call({
 List<OperationTask> tasks, bool isMinimized
});




}
/// @nodoc
class __$OperationQueueStateCopyWithImpl<$Res>
    implements _$OperationQueueStateCopyWith<$Res> {
  __$OperationQueueStateCopyWithImpl(this._self, this._then);

  final _OperationQueueState _self;
  final $Res Function(_OperationQueueState) _then;

/// Create a copy of OperationQueueState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tasks = null,Object? isMinimized = null,}) {
  return _then(_OperationQueueState(
tasks: null == tasks ? _self._tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<OperationTask>,isMinimized: null == isMinimized ? _self.isMinimized : isMinimized // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
