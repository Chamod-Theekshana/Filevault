// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FileEntity {

 String get path; String get name; bool get isDirectory; int get size; DateTime get modified; String? get mimeType; String? get extension; bool get isHidden; FileCategory get category;
/// Create a copy of FileEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileEntityCopyWith<FileEntity> get copyWith => _$FileEntityCopyWithImpl<FileEntity>(this as FileEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileEntity&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name)&&(identical(other.isDirectory, isDirectory) || other.isDirectory == isDirectory)&&(identical(other.size, size) || other.size == size)&&(identical(other.modified, modified) || other.modified == modified)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.extension, extension) || other.extension == extension)&&(identical(other.isHidden, isHidden) || other.isHidden == isHidden)&&(identical(other.category, category) || other.category == category));
}


@override
int get hashCode => Object.hash(runtimeType,path,name,isDirectory,size,modified,mimeType,extension,isHidden,category);

@override
String toString() {
  return 'FileEntity(path: $path, name: $name, isDirectory: $isDirectory, size: $size, modified: $modified, mimeType: $mimeType, extension: $extension, isHidden: $isHidden, category: $category)';
}


}

/// @nodoc
abstract mixin class $FileEntityCopyWith<$Res>  {
  factory $FileEntityCopyWith(FileEntity value, $Res Function(FileEntity) _then) = _$FileEntityCopyWithImpl;
@useResult
$Res call({
 String path, String name, bool isDirectory, int size, DateTime modified, String? mimeType, String? extension, bool isHidden, FileCategory category
});




}
/// @nodoc
class _$FileEntityCopyWithImpl<$Res>
    implements $FileEntityCopyWith<$Res> {
  _$FileEntityCopyWithImpl(this._self, this._then);

  final FileEntity _self;
  final $Res Function(FileEntity) _then;

/// Create a copy of FileEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? name = null,Object? isDirectory = null,Object? size = null,Object? modified = null,Object? mimeType = freezed,Object? extension = freezed,Object? isHidden = null,Object? category = null,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isDirectory: null == isDirectory ? _self.isDirectory : isDirectory // ignore: cast_nullable_to_non_nullable
as bool,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,modified: null == modified ? _self.modified : modified // ignore: cast_nullable_to_non_nullable
as DateTime,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,extension: freezed == extension ? _self.extension : extension // ignore: cast_nullable_to_non_nullable
as String?,isHidden: null == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as FileCategory,
  ));
}

}


/// Adds pattern-matching-related methods to [FileEntity].
extension FileEntityPatterns on FileEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileEntity value)  $default,){
final _that = this;
switch (_that) {
case _FileEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileEntity value)?  $default,){
final _that = this;
switch (_that) {
case _FileEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String name,  bool isDirectory,  int size,  DateTime modified,  String? mimeType,  String? extension,  bool isHidden,  FileCategory category)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileEntity() when $default != null:
return $default(_that.path,_that.name,_that.isDirectory,_that.size,_that.modified,_that.mimeType,_that.extension,_that.isHidden,_that.category);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String name,  bool isDirectory,  int size,  DateTime modified,  String? mimeType,  String? extension,  bool isHidden,  FileCategory category)  $default,) {final _that = this;
switch (_that) {
case _FileEntity():
return $default(_that.path,_that.name,_that.isDirectory,_that.size,_that.modified,_that.mimeType,_that.extension,_that.isHidden,_that.category);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String name,  bool isDirectory,  int size,  DateTime modified,  String? mimeType,  String? extension,  bool isHidden,  FileCategory category)?  $default,) {final _that = this;
switch (_that) {
case _FileEntity() when $default != null:
return $default(_that.path,_that.name,_that.isDirectory,_that.size,_that.modified,_that.mimeType,_that.extension,_that.isHidden,_that.category);case _:
  return null;

}
}

}

/// @nodoc


class _FileEntity extends FileEntity {
  const _FileEntity({required this.path, required this.name, required this.isDirectory, required this.size, required this.modified, this.mimeType, this.extension, this.isHidden = false, this.category = FileCategory.other}): super._();
  

@override final  String path;
@override final  String name;
@override final  bool isDirectory;
@override final  int size;
@override final  DateTime modified;
@override final  String? mimeType;
@override final  String? extension;
@override@JsonKey() final  bool isHidden;
@override@JsonKey() final  FileCategory category;

/// Create a copy of FileEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileEntityCopyWith<_FileEntity> get copyWith => __$FileEntityCopyWithImpl<_FileEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileEntity&&(identical(other.path, path) || other.path == path)&&(identical(other.name, name) || other.name == name)&&(identical(other.isDirectory, isDirectory) || other.isDirectory == isDirectory)&&(identical(other.size, size) || other.size == size)&&(identical(other.modified, modified) || other.modified == modified)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.extension, extension) || other.extension == extension)&&(identical(other.isHidden, isHidden) || other.isHidden == isHidden)&&(identical(other.category, category) || other.category == category));
}


@override
int get hashCode => Object.hash(runtimeType,path,name,isDirectory,size,modified,mimeType,extension,isHidden,category);

@override
String toString() {
  return 'FileEntity(path: $path, name: $name, isDirectory: $isDirectory, size: $size, modified: $modified, mimeType: $mimeType, extension: $extension, isHidden: $isHidden, category: $category)';
}


}

/// @nodoc
abstract mixin class _$FileEntityCopyWith<$Res> implements $FileEntityCopyWith<$Res> {
  factory _$FileEntityCopyWith(_FileEntity value, $Res Function(_FileEntity) _then) = __$FileEntityCopyWithImpl;
@override @useResult
$Res call({
 String path, String name, bool isDirectory, int size, DateTime modified, String? mimeType, String? extension, bool isHidden, FileCategory category
});




}
/// @nodoc
class __$FileEntityCopyWithImpl<$Res>
    implements _$FileEntityCopyWith<$Res> {
  __$FileEntityCopyWithImpl(this._self, this._then);

  final _FileEntity _self;
  final $Res Function(_FileEntity) _then;

/// Create a copy of FileEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? name = null,Object? isDirectory = null,Object? size = null,Object? modified = null,Object? mimeType = freezed,Object? extension = freezed,Object? isHidden = null,Object? category = null,}) {
  return _then(_FileEntity(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isDirectory: null == isDirectory ? _self.isDirectory : isDirectory // ignore: cast_nullable_to_non_nullable
as bool,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,modified: null == modified ? _self.modified : modified // ignore: cast_nullable_to_non_nullable
as DateTime,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,extension: freezed == extension ? _self.extension : extension // ignore: cast_nullable_to_non_nullable
as String?,isHidden: null == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as FileCategory,
  ));
}


}

// dart format on
