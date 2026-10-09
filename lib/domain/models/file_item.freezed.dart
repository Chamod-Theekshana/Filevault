// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FileItem {

 String get path; String get name; int get size; DateTime get modified; FileItemType get type; bool get isHidden;
/// Create a copy of FileItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileItemCopyWith<FileItem> get copyWith => _$FileItemCopyWithImpl<FileItem>(this as FileItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FileItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileItem&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.modified, _this.modified) || other.modified == _this.modified)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.isHidden, _this.isHidden) || other.isHidden == _this.isHidden));
}


@override
int get hashCode {
  final _this = this as FileItem;
  return Object.hash(runtimeType,_this.path,_this.name,_this.size,_this.modified,_this.type,_this.isHidden);
}

@override
String toString() {
  final _this = this as FileItem;
  return 'FileItem(path: ${_this.path}, name: ${_this.name}, size: ${_this.size}, modified: ${_this.modified}, type: ${_this.type}, isHidden: ${_this.isHidden})';
}


}

/// @nodoc
abstract mixin class $FileItemCopyWith<$Res>  {
  factory $FileItemCopyWith(FileItem value, $Res Function(FileItem) _then) = _$FileItemCopyWithImpl;
@useResult
$Res call({
 String path, String name, int size, DateTime modified, FileItemType type, bool isHidden
});




}
/// @nodoc
class _$FileItemCopyWithImpl<$Res>
    implements $FileItemCopyWith<$Res> {
  _$FileItemCopyWithImpl(this._self, this._then);

  final FileItem _self;
  final $Res Function(FileItem) _then;

/// Create a copy of FileItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? name = null,Object? size = null,Object? modified = null,Object? type = null,Object? isHidden = null,}) {
  return _then(FileItem(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,modified: null == modified ? _self.modified : modified // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as FileItemType,isHidden: null == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FileItem].
extension FileItemPatterns on FileItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileItem value)  $default,){
final _that = this;
switch (_that) {
case _FileItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileItem value)?  $default,){
final _that = this;
switch (_that) {
case _FileItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String name,  int size,  DateTime modified,  FileItemType type,  bool isHidden)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileItem() when $default != null:
return $default(_that.path,_that.name,_that.size,_that.modified,_that.type,_that.isHidden);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String name,  int size,  DateTime modified,  FileItemType type,  bool isHidden)  $default,) {final _that = this;
switch (_that) {
case _FileItem():
return $default(_that.path,_that.name,_that.size,_that.modified,_that.type,_that.isHidden);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String name,  int size,  DateTime modified,  FileItemType type,  bool isHidden)?  $default,) {final _that = this;
switch (_that) {
case _FileItem() when $default != null:
return $default(_that.path,_that.name,_that.size,_that.modified,_that.type,_that.isHidden);case _:
  return null;

}
}

}

/// @nodoc


class _FileItem extends FileItem {
  const _FileItem({required this.path, required this.name, required this.size, required this.modified, required this.type, this.isHidden = false}): super._();
  

@override final  String path;
@override final  String name;
@override final  int size;
@override final  DateTime modified;
@override final  FileItemType type;
@override@JsonKey() final  bool isHidden;

/// Create a copy of FileItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileItemCopyWith<_FileItem> get copyWith => __$FileItemCopyWithImpl<_FileItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileItem&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name)&&(identical(other.size, size) || other.size == size)&&(identical(other.modified, modified) || other.modified == modified)&&(identical(other.type, type) || other.type == type)&&(identical(other.isHidden, isHidden) || other.isHidden == isHidden));
}


@override
int get hashCode {
    return Object.hash(runtimeType,path,name,size,modified,type,isHidden);
}

@override
String toString() {
    return 'FileItem(path: $path, name: $name, size: $size, modified: $modified, type: $type, isHidden: $isHidden)';
}


}

/// @nodoc
abstract mixin class _$FileItemCopyWith<$Res> implements $FileItemCopyWith<$Res> {
  factory _$FileItemCopyWith(_FileItem value, $Res Function(_FileItem) _then) = __$FileItemCopyWithImpl;
@override @useResult
$Res call({
 String path, String name, int size, DateTime modified, FileItemType type, bool isHidden
});




}
/// @nodoc
class __$FileItemCopyWithImpl<$Res>
    implements _$FileItemCopyWith<$Res> {
  __$FileItemCopyWithImpl(this._self, this._then);

  final _FileItem _self;
  final $Res Function(_FileItem) _then;

/// Create a copy of FileItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? name = null,Object? size = null,Object? modified = null,Object? type = null,Object? isHidden = null,}) {
  return _then(_FileItem(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,modified: null == modified ? _self.modified : modified // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as FileItemType,isHidden: null == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
