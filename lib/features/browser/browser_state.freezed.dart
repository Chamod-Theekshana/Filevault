// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'browser_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BrowserState {

 List<String> get breadcrumbs; FileViewMode get viewMode; FileSortField get sortField; SortDirection get sortDirection; bool get foldersFirst; bool get showHidden; Set<String> get selectedPaths; bool get isLoading;
/// Create a copy of BrowserState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BrowserStateCopyWith<BrowserState> get copyWith => _$BrowserStateCopyWithImpl<BrowserState>(this as BrowserState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BrowserState&&const DeepCollectionEquality().equals(other.breadcrumbs, breadcrumbs)&&(identical(other.viewMode, viewMode) || other.viewMode == viewMode)&&(identical(other.sortField, sortField) || other.sortField == sortField)&&(identical(other.sortDirection, sortDirection) || other.sortDirection == sortDirection)&&(identical(other.foldersFirst, foldersFirst) || other.foldersFirst == foldersFirst)&&(identical(other.showHidden, showHidden) || other.showHidden == showHidden)&&const DeepCollectionEquality().equals(other.selectedPaths, selectedPaths)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(breadcrumbs),viewMode,sortField,sortDirection,foldersFirst,showHidden,const DeepCollectionEquality().hash(selectedPaths),isLoading);

@override
String toString() {
  return 'BrowserState(breadcrumbs: $breadcrumbs, viewMode: $viewMode, sortField: $sortField, sortDirection: $sortDirection, foldersFirst: $foldersFirst, showHidden: $showHidden, selectedPaths: $selectedPaths, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class $BrowserStateCopyWith<$Res>  {
  factory $BrowserStateCopyWith(BrowserState value, $Res Function(BrowserState) _then) = _$BrowserStateCopyWithImpl;
@useResult
$Res call({
 List<String> breadcrumbs, FileViewMode viewMode, FileSortField sortField, SortDirection sortDirection, bool foldersFirst, bool showHidden, Set<String> selectedPaths, bool isLoading
});




}
/// @nodoc
class _$BrowserStateCopyWithImpl<$Res>
    implements $BrowserStateCopyWith<$Res> {
  _$BrowserStateCopyWithImpl(this._self, this._then);

  final BrowserState _self;
  final $Res Function(BrowserState) _then;

/// Create a copy of BrowserState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? breadcrumbs = null,Object? viewMode = null,Object? sortField = null,Object? sortDirection = null,Object? foldersFirst = null,Object? showHidden = null,Object? selectedPaths = null,Object? isLoading = null,}) {
  return _then(_self.copyWith(
breadcrumbs: null == breadcrumbs ? _self.breadcrumbs : breadcrumbs // ignore: cast_nullable_to_non_nullable
as List<String>,viewMode: null == viewMode ? _self.viewMode : viewMode // ignore: cast_nullable_to_non_nullable
as FileViewMode,sortField: null == sortField ? _self.sortField : sortField // ignore: cast_nullable_to_non_nullable
as FileSortField,sortDirection: null == sortDirection ? _self.sortDirection : sortDirection // ignore: cast_nullable_to_non_nullable
as SortDirection,foldersFirst: null == foldersFirst ? _self.foldersFirst : foldersFirst // ignore: cast_nullable_to_non_nullable
as bool,showHidden: null == showHidden ? _self.showHidden : showHidden // ignore: cast_nullable_to_non_nullable
as bool,selectedPaths: null == selectedPaths ? _self.selectedPaths : selectedPaths // ignore: cast_nullable_to_non_nullable
as Set<String>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [BrowserState].
extension BrowserStatePatterns on BrowserState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BrowserState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BrowserState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BrowserState value)  $default,){
final _that = this;
switch (_that) {
case _BrowserState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BrowserState value)?  $default,){
final _that = this;
switch (_that) {
case _BrowserState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> breadcrumbs,  FileViewMode viewMode,  FileSortField sortField,  SortDirection sortDirection,  bool foldersFirst,  bool showHidden,  Set<String> selectedPaths,  bool isLoading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BrowserState() when $default != null:
return $default(_that.breadcrumbs,_that.viewMode,_that.sortField,_that.sortDirection,_that.foldersFirst,_that.showHidden,_that.selectedPaths,_that.isLoading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> breadcrumbs,  FileViewMode viewMode,  FileSortField sortField,  SortDirection sortDirection,  bool foldersFirst,  bool showHidden,  Set<String> selectedPaths,  bool isLoading)  $default,) {final _that = this;
switch (_that) {
case _BrowserState():
return $default(_that.breadcrumbs,_that.viewMode,_that.sortField,_that.sortDirection,_that.foldersFirst,_that.showHidden,_that.selectedPaths,_that.isLoading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> breadcrumbs,  FileViewMode viewMode,  FileSortField sortField,  SortDirection sortDirection,  bool foldersFirst,  bool showHidden,  Set<String> selectedPaths,  bool isLoading)?  $default,) {final _that = this;
switch (_that) {
case _BrowserState() when $default != null:
return $default(_that.breadcrumbs,_that.viewMode,_that.sortField,_that.sortDirection,_that.foldersFirst,_that.showHidden,_that.selectedPaths,_that.isLoading);case _:
  return null;

}
}

}

/// @nodoc


class _BrowserState implements BrowserState {
  const _BrowserState({final  List<String> breadcrumbs = const <String>['Internal storage'], this.viewMode = FileViewMode.list, this.sortField = FileSortField.name, this.sortDirection = SortDirection.asc, this.foldersFirst = true, this.showHidden = false, final  Set<String> selectedPaths = const <String>{}, this.isLoading = false}): _breadcrumbs = breadcrumbs,_selectedPaths = selectedPaths;
  

 final  List<String> _breadcrumbs;
@override@JsonKey() List<String> get breadcrumbs {
  if (_breadcrumbs is EqualUnmodifiableListView) return _breadcrumbs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_breadcrumbs);
}

@override@JsonKey() final  FileViewMode viewMode;
@override@JsonKey() final  FileSortField sortField;
@override@JsonKey() final  SortDirection sortDirection;
@override@JsonKey() final  bool foldersFirst;
@override@JsonKey() final  bool showHidden;
 final  Set<String> _selectedPaths;
@override@JsonKey() Set<String> get selectedPaths {
  if (_selectedPaths is EqualUnmodifiableSetView) return _selectedPaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selectedPaths);
}

@override@JsonKey() final  bool isLoading;

/// Create a copy of BrowserState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BrowserStateCopyWith<_BrowserState> get copyWith => __$BrowserStateCopyWithImpl<_BrowserState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BrowserState&&const DeepCollectionEquality().equals(other._breadcrumbs, _breadcrumbs)&&(identical(other.viewMode, viewMode) || other.viewMode == viewMode)&&(identical(other.sortField, sortField) || other.sortField == sortField)&&(identical(other.sortDirection, sortDirection) || other.sortDirection == sortDirection)&&(identical(other.foldersFirst, foldersFirst) || other.foldersFirst == foldersFirst)&&(identical(other.showHidden, showHidden) || other.showHidden == showHidden)&&const DeepCollectionEquality().equals(other._selectedPaths, _selectedPaths)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_breadcrumbs),viewMode,sortField,sortDirection,foldersFirst,showHidden,const DeepCollectionEquality().hash(_selectedPaths),isLoading);

@override
String toString() {
  return 'BrowserState(breadcrumbs: $breadcrumbs, viewMode: $viewMode, sortField: $sortField, sortDirection: $sortDirection, foldersFirst: $foldersFirst, showHidden: $showHidden, selectedPaths: $selectedPaths, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class _$BrowserStateCopyWith<$Res> implements $BrowserStateCopyWith<$Res> {
  factory _$BrowserStateCopyWith(_BrowserState value, $Res Function(_BrowserState) _then) = __$BrowserStateCopyWithImpl;
@override @useResult
$Res call({
 List<String> breadcrumbs, FileViewMode viewMode, FileSortField sortField, SortDirection sortDirection, bool foldersFirst, bool showHidden, Set<String> selectedPaths, bool isLoading
});




}
/// @nodoc
class __$BrowserStateCopyWithImpl<$Res>
    implements _$BrowserStateCopyWith<$Res> {
  __$BrowserStateCopyWithImpl(this._self, this._then);

  final _BrowserState _self;
  final $Res Function(_BrowserState) _then;

/// Create a copy of BrowserState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? breadcrumbs = null,Object? viewMode = null,Object? sortField = null,Object? sortDirection = null,Object? foldersFirst = null,Object? showHidden = null,Object? selectedPaths = null,Object? isLoading = null,}) {
  return _then(_BrowserState(
breadcrumbs: null == breadcrumbs ? _self._breadcrumbs : breadcrumbs // ignore: cast_nullable_to_non_nullable
as List<String>,viewMode: null == viewMode ? _self.viewMode : viewMode // ignore: cast_nullable_to_non_nullable
as FileViewMode,sortField: null == sortField ? _self.sortField : sortField // ignore: cast_nullable_to_non_nullable
as FileSortField,sortDirection: null == sortDirection ? _self.sortDirection : sortDirection // ignore: cast_nullable_to_non_nullable
as SortDirection,foldersFirst: null == foldersFirst ? _self.foldersFirst : foldersFirst // ignore: cast_nullable_to_non_nullable
as bool,showHidden: null == showHidden ? _self.showHidden : showHidden // ignore: cast_nullable_to_non_nullable
as bool,selectedPaths: null == selectedPaths ? _self._selectedPaths : selectedPaths // ignore: cast_nullable_to_non_nullable
as Set<String>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
