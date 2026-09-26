// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CategoryDraft {

 String get name; String get fiscalTag; String get icon; String get color;
/// Create a copy of CategoryDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryDraftCopyWith<CategoryDraft> get copyWith => _$CategoryDraftCopyWithImpl<CategoryDraft>(this as CategoryDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryDraft&&(identical(other.name, name) || other.name == name)&&(identical(other.fiscalTag, fiscalTag) || other.fiscalTag == fiscalTag)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode => Object.hash(runtimeType,name,fiscalTag,icon,color);

@override
String toString() {
  return 'CategoryDraft(name: $name, fiscalTag: $fiscalTag, icon: $icon, color: $color)';
}


}

/// @nodoc
abstract mixin class $CategoryDraftCopyWith<$Res>  {
  factory $CategoryDraftCopyWith(CategoryDraft value, $Res Function(CategoryDraft) _then) = _$CategoryDraftCopyWithImpl;
@useResult
$Res call({
 String name, String fiscalTag, String icon, String color
});




}
/// @nodoc
class _$CategoryDraftCopyWithImpl<$Res>
    implements $CategoryDraftCopyWith<$Res> {
  _$CategoryDraftCopyWithImpl(this._self, this._then);

  final CategoryDraft _self;
  final $Res Function(CategoryDraft) _then;

/// Create a copy of CategoryDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? fiscalTag = null,Object? icon = null,Object? color = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fiscalTag: null == fiscalTag ? _self.fiscalTag : fiscalTag // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryDraft].
extension CategoryDraftPatterns on CategoryDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryDraft value)  $default,){
final _that = this;
switch (_that) {
case _CategoryDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryDraft value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String fiscalTag,  String icon,  String color)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryDraft() when $default != null:
return $default(_that.name,_that.fiscalTag,_that.icon,_that.color);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String fiscalTag,  String icon,  String color)  $default,) {final _that = this;
switch (_that) {
case _CategoryDraft():
return $default(_that.name,_that.fiscalTag,_that.icon,_that.color);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String fiscalTag,  String icon,  String color)?  $default,) {final _that = this;
switch (_that) {
case _CategoryDraft() when $default != null:
return $default(_that.name,_that.fiscalTag,_that.icon,_that.color);case _:
  return null;

}
}

}

/// @nodoc


class _CategoryDraft extends CategoryDraft {
  const _CategoryDraft({required this.name, this.fiscalTag = defaultFiscalTag, this.icon = 'label', this.color = '#0E4D3F'}): super._();
  

@override final  String name;
@override@JsonKey() final  String fiscalTag;
@override@JsonKey() final  String icon;
@override@JsonKey() final  String color;

/// Create a copy of CategoryDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryDraftCopyWith<_CategoryDraft> get copyWith => __$CategoryDraftCopyWithImpl<_CategoryDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryDraft&&(identical(other.name, name) || other.name == name)&&(identical(other.fiscalTag, fiscalTag) || other.fiscalTag == fiscalTag)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode => Object.hash(runtimeType,name,fiscalTag,icon,color);

@override
String toString() {
  return 'CategoryDraft(name: $name, fiscalTag: $fiscalTag, icon: $icon, color: $color)';
}


}

/// @nodoc
abstract mixin class _$CategoryDraftCopyWith<$Res> implements $CategoryDraftCopyWith<$Res> {
  factory _$CategoryDraftCopyWith(_CategoryDraft value, $Res Function(_CategoryDraft) _then) = __$CategoryDraftCopyWithImpl;
@override @useResult
$Res call({
 String name, String fiscalTag, String icon, String color
});




}
/// @nodoc
class __$CategoryDraftCopyWithImpl<$Res>
    implements _$CategoryDraftCopyWith<$Res> {
  __$CategoryDraftCopyWithImpl(this._self, this._then);

  final _CategoryDraft _self;
  final $Res Function(_CategoryDraft) _then;

/// Create a copy of CategoryDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? fiscalTag = null,Object? icon = null,Object? color = null,}) {
  return _then(_CategoryDraft(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fiscalTag: null == fiscalTag ? _self.fiscalTag : fiscalTag // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
