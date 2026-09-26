// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'categories_ports.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OwnCategory {

 String get id; String get name; String get fiscalTag; int get transactionCount; String? get icon; String? get color;
/// Create a copy of OwnCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OwnCategoryCopyWith<OwnCategory> get copyWith => _$OwnCategoryCopyWithImpl<OwnCategory>(this as OwnCategory, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OwnCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.fiscalTag, fiscalTag) || other.fiscalTag == fiscalTag)&&(identical(other.transactionCount, transactionCount) || other.transactionCount == transactionCount)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,fiscalTag,transactionCount,icon,color);

@override
String toString() {
  return 'OwnCategory(id: $id, name: $name, fiscalTag: $fiscalTag, transactionCount: $transactionCount, icon: $icon, color: $color)';
}


}

/// @nodoc
abstract mixin class $OwnCategoryCopyWith<$Res>  {
  factory $OwnCategoryCopyWith(OwnCategory value, $Res Function(OwnCategory) _then) = _$OwnCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String fiscalTag, int transactionCount, String? icon, String? color
});




}
/// @nodoc
class _$OwnCategoryCopyWithImpl<$Res>
    implements $OwnCategoryCopyWith<$Res> {
  _$OwnCategoryCopyWithImpl(this._self, this._then);

  final OwnCategory _self;
  final $Res Function(OwnCategory) _then;

/// Create a copy of OwnCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? fiscalTag = null,Object? transactionCount = null,Object? icon = freezed,Object? color = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fiscalTag: null == fiscalTag ? _self.fiscalTag : fiscalTag // ignore: cast_nullable_to_non_nullable
as String,transactionCount: null == transactionCount ? _self.transactionCount : transactionCount // ignore: cast_nullable_to_non_nullable
as int,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OwnCategory].
extension OwnCategoryPatterns on OwnCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OwnCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OwnCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OwnCategory value)  $default,){
final _that = this;
switch (_that) {
case _OwnCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OwnCategory value)?  $default,){
final _that = this;
switch (_that) {
case _OwnCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String fiscalTag,  int transactionCount,  String? icon,  String? color)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OwnCategory() when $default != null:
return $default(_that.id,_that.name,_that.fiscalTag,_that.transactionCount,_that.icon,_that.color);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String fiscalTag,  int transactionCount,  String? icon,  String? color)  $default,) {final _that = this;
switch (_that) {
case _OwnCategory():
return $default(_that.id,_that.name,_that.fiscalTag,_that.transactionCount,_that.icon,_that.color);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String fiscalTag,  int transactionCount,  String? icon,  String? color)?  $default,) {final _that = this;
switch (_that) {
case _OwnCategory() when $default != null:
return $default(_that.id,_that.name,_that.fiscalTag,_that.transactionCount,_that.icon,_that.color);case _:
  return null;

}
}

}

/// @nodoc


class _OwnCategory implements OwnCategory {
  const _OwnCategory({required this.id, required this.name, required this.fiscalTag, required this.transactionCount, this.icon, this.color});
  

@override final  String id;
@override final  String name;
@override final  String fiscalTag;
@override final  int transactionCount;
@override final  String? icon;
@override final  String? color;

/// Create a copy of OwnCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OwnCategoryCopyWith<_OwnCategory> get copyWith => __$OwnCategoryCopyWithImpl<_OwnCategory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OwnCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.fiscalTag, fiscalTag) || other.fiscalTag == fiscalTag)&&(identical(other.transactionCount, transactionCount) || other.transactionCount == transactionCount)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,fiscalTag,transactionCount,icon,color);

@override
String toString() {
  return 'OwnCategory(id: $id, name: $name, fiscalTag: $fiscalTag, transactionCount: $transactionCount, icon: $icon, color: $color)';
}


}

/// @nodoc
abstract mixin class _$OwnCategoryCopyWith<$Res> implements $OwnCategoryCopyWith<$Res> {
  factory _$OwnCategoryCopyWith(_OwnCategory value, $Res Function(_OwnCategory) _then) = __$OwnCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String fiscalTag, int transactionCount, String? icon, String? color
});




}
/// @nodoc
class __$OwnCategoryCopyWithImpl<$Res>
    implements _$OwnCategoryCopyWith<$Res> {
  __$OwnCategoryCopyWithImpl(this._self, this._then);

  final _OwnCategory _self;
  final $Res Function(_OwnCategory) _then;

/// Create a copy of OwnCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? fiscalTag = null,Object? transactionCount = null,Object? icon = freezed,Object? color = freezed,}) {
  return _then(_OwnCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fiscalTag: null == fiscalTag ? _self.fiscalTag : fiscalTag // ignore: cast_nullable_to_non_nullable
as String,transactionCount: null == transactionCount ? _self.transactionCount : transactionCount // ignore: cast_nullable_to_non_nullable
as int,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
