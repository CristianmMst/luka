// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CategoryOption {

 String get id; String get name; bool get isSystem; String? get slug;
/// Create a copy of CategoryOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryOptionCopyWith<CategoryOption> get copyWith => _$CategoryOptionCopyWithImpl<CategoryOption>(this as CategoryOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.slug, slug) || other.slug == slug));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,isSystem,slug);

@override
String toString() {
  return 'CategoryOption(id: $id, name: $name, isSystem: $isSystem, slug: $slug)';
}


}

/// @nodoc
abstract mixin class $CategoryOptionCopyWith<$Res>  {
  factory $CategoryOptionCopyWith(CategoryOption value, $Res Function(CategoryOption) _then) = _$CategoryOptionCopyWithImpl;
@useResult
$Res call({
 String id, String name, bool isSystem, String? slug
});




}
/// @nodoc
class _$CategoryOptionCopyWithImpl<$Res>
    implements $CategoryOptionCopyWith<$Res> {
  _$CategoryOptionCopyWithImpl(this._self, this._then);

  final CategoryOption _self;
  final $Res Function(CategoryOption) _then;

/// Create a copy of CategoryOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? isSystem = null,Object? slug = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isSystem: null == isSystem ? _self.isSystem : isSystem // ignore: cast_nullable_to_non_nullable
as bool,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryOption].
extension CategoryOptionPatterns on CategoryOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryOption value)  $default,){
final _that = this;
switch (_that) {
case _CategoryOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryOption value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  bool isSystem,  String? slug)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryOption() when $default != null:
return $default(_that.id,_that.name,_that.isSystem,_that.slug);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  bool isSystem,  String? slug)  $default,) {final _that = this;
switch (_that) {
case _CategoryOption():
return $default(_that.id,_that.name,_that.isSystem,_that.slug);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  bool isSystem,  String? slug)?  $default,) {final _that = this;
switch (_that) {
case _CategoryOption() when $default != null:
return $default(_that.id,_that.name,_that.isSystem,_that.slug);case _:
  return null;

}
}

}

/// @nodoc


class _CategoryOption implements CategoryOption {
  const _CategoryOption({required this.id, required this.name, required this.isSystem, this.slug});
  

@override final  String id;
@override final  String name;
@override final  bool isSystem;
@override final  String? slug;

/// Create a copy of CategoryOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryOptionCopyWith<_CategoryOption> get copyWith => __$CategoryOptionCopyWithImpl<_CategoryOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.slug, slug) || other.slug == slug));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,isSystem,slug);

@override
String toString() {
  return 'CategoryOption(id: $id, name: $name, isSystem: $isSystem, slug: $slug)';
}


}

/// @nodoc
abstract mixin class _$CategoryOptionCopyWith<$Res> implements $CategoryOptionCopyWith<$Res> {
  factory _$CategoryOptionCopyWith(_CategoryOption value, $Res Function(_CategoryOption) _then) = __$CategoryOptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, bool isSystem, String? slug
});




}
/// @nodoc
class __$CategoryOptionCopyWithImpl<$Res>
    implements _$CategoryOptionCopyWith<$Res> {
  __$CategoryOptionCopyWithImpl(this._self, this._then);

  final _CategoryOption _self;
  final $Res Function(_CategoryOption) _then;

/// Create a copy of CategoryOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? isSystem = null,Object? slug = freezed,}) {
  return _then(_CategoryOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isSystem: null == isSystem ? _self.isSystem : isSystem // ignore: cast_nullable_to_non_nullable
as bool,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
