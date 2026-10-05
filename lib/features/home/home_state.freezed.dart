// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HomeState {

 bool get isLoading; List<StorageVolumeInfo> get volumes; List<CategorySummary> get categories; List<FileEntity> get recents; List<QuickAccessItem> get quickAccess;
/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeStateCopyWith<HomeState> get copyWith => _$HomeStateCopyWithImpl<HomeState>(this as HomeState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other.volumes, volumes)&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.recents, recents)&&const DeepCollectionEquality().equals(other.quickAccess, quickAccess));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,const DeepCollectionEquality().hash(volumes),const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(recents),const DeepCollectionEquality().hash(quickAccess));

@override
String toString() {
  return 'HomeState(isLoading: $isLoading, volumes: $volumes, categories: $categories, recents: $recents, quickAccess: $quickAccess)';
}


}

/// @nodoc
abstract mixin class $HomeStateCopyWith<$Res>  {
  factory $HomeStateCopyWith(HomeState value, $Res Function(HomeState) _then) = _$HomeStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, List<StorageVolumeInfo> volumes, List<CategorySummary> categories, List<FileEntity> recents, List<QuickAccessItem> quickAccess
});




}
/// @nodoc
class _$HomeStateCopyWithImpl<$Res>
    implements $HomeStateCopyWith<$Res> {
  _$HomeStateCopyWithImpl(this._self, this._then);

  final HomeState _self;
  final $Res Function(HomeState) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? volumes = null,Object? categories = null,Object? recents = null,Object? quickAccess = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,volumes: null == volumes ? _self.volumes : volumes // ignore: cast_nullable_to_non_nullable
as List<StorageVolumeInfo>,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<CategorySummary>,recents: null == recents ? _self.recents : recents // ignore: cast_nullable_to_non_nullable
as List<FileEntity>,quickAccess: null == quickAccess ? _self.quickAccess : quickAccess // ignore: cast_nullable_to_non_nullable
as List<QuickAccessItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeState].
extension HomeStatePatterns on HomeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeState value)  $default,){
final _that = this;
switch (_that) {
case _HomeState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeState value)?  $default,){
final _that = this;
switch (_that) {
case _HomeState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  List<StorageVolumeInfo> volumes,  List<CategorySummary> categories,  List<FileEntity> recents,  List<QuickAccessItem> quickAccess)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeState() when $default != null:
return $default(_that.isLoading,_that.volumes,_that.categories,_that.recents,_that.quickAccess);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  List<StorageVolumeInfo> volumes,  List<CategorySummary> categories,  List<FileEntity> recents,  List<QuickAccessItem> quickAccess)  $default,) {final _that = this;
switch (_that) {
case _HomeState():
return $default(_that.isLoading,_that.volumes,_that.categories,_that.recents,_that.quickAccess);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  List<StorageVolumeInfo> volumes,  List<CategorySummary> categories,  List<FileEntity> recents,  List<QuickAccessItem> quickAccess)?  $default,) {final _that = this;
switch (_that) {
case _HomeState() when $default != null:
return $default(_that.isLoading,_that.volumes,_that.categories,_that.recents,_that.quickAccess);case _:
  return null;

}
}

}

/// @nodoc


class _HomeState extends HomeState {
  const _HomeState({this.isLoading = false, final  List<StorageVolumeInfo> volumes = const <StorageVolumeInfo>[], final  List<CategorySummary> categories = const <CategorySummary>[], final  List<FileEntity> recents = const <FileEntity>[], final  List<QuickAccessItem> quickAccess = const <QuickAccessItem>[]}): _volumes = volumes,_categories = categories,_recents = recents,_quickAccess = quickAccess,super._();
  

@override@JsonKey() final  bool isLoading;
 final  List<StorageVolumeInfo> _volumes;
@override@JsonKey() List<StorageVolumeInfo> get volumes {
  if (_volumes is EqualUnmodifiableListView) return _volumes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_volumes);
}

 final  List<CategorySummary> _categories;
@override@JsonKey() List<CategorySummary> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  List<FileEntity> _recents;
@override@JsonKey() List<FileEntity> get recents {
  if (_recents is EqualUnmodifiableListView) return _recents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recents);
}

 final  List<QuickAccessItem> _quickAccess;
@override@JsonKey() List<QuickAccessItem> get quickAccess {
  if (_quickAccess is EqualUnmodifiableListView) return _quickAccess;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_quickAccess);
}


/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeStateCopyWith<_HomeState> get copyWith => __$HomeStateCopyWithImpl<_HomeState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other._volumes, _volumes)&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._recents, _recents)&&const DeepCollectionEquality().equals(other._quickAccess, _quickAccess));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,const DeepCollectionEquality().hash(_volumes),const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_recents),const DeepCollectionEquality().hash(_quickAccess));

@override
String toString() {
  return 'HomeState(isLoading: $isLoading, volumes: $volumes, categories: $categories, recents: $recents, quickAccess: $quickAccess)';
}


}

/// @nodoc
abstract mixin class _$HomeStateCopyWith<$Res> implements $HomeStateCopyWith<$Res> {
  factory _$HomeStateCopyWith(_HomeState value, $Res Function(_HomeState) _then) = __$HomeStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, List<StorageVolumeInfo> volumes, List<CategorySummary> categories, List<FileEntity> recents, List<QuickAccessItem> quickAccess
});




}
/// @nodoc
class __$HomeStateCopyWithImpl<$Res>
    implements _$HomeStateCopyWith<$Res> {
  __$HomeStateCopyWithImpl(this._self, this._then);

  final _HomeState _self;
  final $Res Function(_HomeState) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? volumes = null,Object? categories = null,Object? recents = null,Object? quickAccess = null,}) {
  return _then(_HomeState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,volumes: null == volumes ? _self._volumes : volumes // ignore: cast_nullable_to_non_nullable
as List<StorageVolumeInfo>,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<CategorySummary>,recents: null == recents ? _self._recents : recents // ignore: cast_nullable_to_non_nullable
as List<FileEntity>,quickAccess: null == quickAccess ? _self._quickAccess : quickAccess // ignore: cast_nullable_to_non_nullable
as List<QuickAccessItem>,
  ));
}


}

// dart format on
