// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nfc_ports.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NfcTagTemplate {

 String get id; String get name; String? get categoryId; String? get accountId; String? get note;
/// Create a copy of NfcTagTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NfcTagTemplateCopyWith<NfcTagTemplate> get copyWith => _$NfcTagTemplateCopyWithImpl<NfcTagTemplate>(this as NfcTagTemplate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NfcTagTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,categoryId,accountId,note);

@override
String toString() {
  return 'NfcTagTemplate(id: $id, name: $name, categoryId: $categoryId, accountId: $accountId, note: $note)';
}


}

/// @nodoc
abstract mixin class $NfcTagTemplateCopyWith<$Res>  {
  factory $NfcTagTemplateCopyWith(NfcTagTemplate value, $Res Function(NfcTagTemplate) _then) = _$NfcTagTemplateCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? categoryId, String? accountId, String? note
});




}
/// @nodoc
class _$NfcTagTemplateCopyWithImpl<$Res>
    implements $NfcTagTemplateCopyWith<$Res> {
  _$NfcTagTemplateCopyWithImpl(this._self, this._then);

  final NfcTagTemplate _self;
  final $Res Function(NfcTagTemplate) _then;

/// Create a copy of NfcTagTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? categoryId = freezed,Object? accountId = freezed,Object? note = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NfcTagTemplate].
extension NfcTagTemplatePatterns on NfcTagTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NfcTagTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NfcTagTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NfcTagTemplate value)  $default,){
final _that = this;
switch (_that) {
case _NfcTagTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NfcTagTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _NfcTagTemplate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? categoryId,  String? accountId,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NfcTagTemplate() when $default != null:
return $default(_that.id,_that.name,_that.categoryId,_that.accountId,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? categoryId,  String? accountId,  String? note)  $default,) {final _that = this;
switch (_that) {
case _NfcTagTemplate():
return $default(_that.id,_that.name,_that.categoryId,_that.accountId,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? categoryId,  String? accountId,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _NfcTagTemplate() when $default != null:
return $default(_that.id,_that.name,_that.categoryId,_that.accountId,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _NfcTagTemplate extends NfcTagTemplate {
  const _NfcTagTemplate({required this.id, required this.name, this.categoryId, this.accountId, this.note}): super._();
  

@override final  String id;
@override final  String name;
@override final  String? categoryId;
@override final  String? accountId;
@override final  String? note;

/// Create a copy of NfcTagTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NfcTagTemplateCopyWith<_NfcTagTemplate> get copyWith => __$NfcTagTemplateCopyWithImpl<_NfcTagTemplate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NfcTagTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,categoryId,accountId,note);

@override
String toString() {
  return 'NfcTagTemplate(id: $id, name: $name, categoryId: $categoryId, accountId: $accountId, note: $note)';
}


}

/// @nodoc
abstract mixin class _$NfcTagTemplateCopyWith<$Res> implements $NfcTagTemplateCopyWith<$Res> {
  factory _$NfcTagTemplateCopyWith(_NfcTagTemplate value, $Res Function(_NfcTagTemplate) _then) = __$NfcTagTemplateCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? categoryId, String? accountId, String? note
});




}
/// @nodoc
class __$NfcTagTemplateCopyWithImpl<$Res>
    implements _$NfcTagTemplateCopyWith<$Res> {
  __$NfcTagTemplateCopyWithImpl(this._self, this._then);

  final _NfcTagTemplate _self;
  final $Res Function(_NfcTagTemplate) _then;

/// Create a copy of NfcTagTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? categoryId = freezed,Object? accountId = freezed,Object? note = freezed,}) {
  return _then(_NfcTagTemplate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
