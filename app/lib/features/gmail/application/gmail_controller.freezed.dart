// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gmail_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GmailState {

 GmailConnectionInfo get info;/// El usuario eligió "Ahora no" (o no hay sesión a quién preguntarle).
 bool get promptDismissed;/// Hay un connect o disconnect en curso: la pantalla bloquea el botón.
 bool get busy;/// Último fallo de una acción, para el aviso de la pantalla. `null` tras
/// un éxito o una cancelación.
 GmailFailure? get failure;
/// Create a copy of GmailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GmailStateCopyWith<GmailState> get copyWith => _$GmailStateCopyWithImpl<GmailState>(this as GmailState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GmailState&&(identical(other.info, info) || other.info == info)&&(identical(other.promptDismissed, promptDismissed) || other.promptDismissed == promptDismissed)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,info,promptDismissed,busy,failure);

@override
String toString() {
  return 'GmailState(info: $info, promptDismissed: $promptDismissed, busy: $busy, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $GmailStateCopyWith<$Res>  {
  factory $GmailStateCopyWith(GmailState value, $Res Function(GmailState) _then) = _$GmailStateCopyWithImpl;
@useResult
$Res call({
 GmailConnectionInfo info, bool promptDismissed, bool busy, GmailFailure? failure
});


$GmailConnectionInfoCopyWith<$Res> get info;

}
/// @nodoc
class _$GmailStateCopyWithImpl<$Res>
    implements $GmailStateCopyWith<$Res> {
  _$GmailStateCopyWithImpl(this._self, this._then);

  final GmailState _self;
  final $Res Function(GmailState) _then;

/// Create a copy of GmailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? info = null,Object? promptDismissed = null,Object? busy = null,Object? failure = freezed,}) {
  return _then(_self.copyWith(
info: null == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as GmailConnectionInfo,promptDismissed: null == promptDismissed ? _self.promptDismissed : promptDismissed // ignore: cast_nullable_to_non_nullable
as bool,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as GmailFailure?,
  ));
}
/// Create a copy of GmailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GmailConnectionInfoCopyWith<$Res> get info {
  
  return $GmailConnectionInfoCopyWith<$Res>(_self.info, (value) {
    return _then(_self.copyWith(info: value));
  });
}
}


/// Adds pattern-matching-related methods to [GmailState].
extension GmailStatePatterns on GmailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GmailState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GmailState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GmailState value)  $default,){
final _that = this;
switch (_that) {
case _GmailState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GmailState value)?  $default,){
final _that = this;
switch (_that) {
case _GmailState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GmailConnectionInfo info,  bool promptDismissed,  bool busy,  GmailFailure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GmailState() when $default != null:
return $default(_that.info,_that.promptDismissed,_that.busy,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GmailConnectionInfo info,  bool promptDismissed,  bool busy,  GmailFailure? failure)  $default,) {final _that = this;
switch (_that) {
case _GmailState():
return $default(_that.info,_that.promptDismissed,_that.busy,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GmailConnectionInfo info,  bool promptDismissed,  bool busy,  GmailFailure? failure)?  $default,) {final _that = this;
switch (_that) {
case _GmailState() when $default != null:
return $default(_that.info,_that.promptDismissed,_that.busy,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _GmailState extends GmailState {
  const _GmailState({required this.info, required this.promptDismissed, this.busy = false, this.failure}): super._();
  

@override final  GmailConnectionInfo info;
/// El usuario eligió "Ahora no" (o no hay sesión a quién preguntarle).
@override final  bool promptDismissed;
/// Hay un connect o disconnect en curso: la pantalla bloquea el botón.
@override@JsonKey() final  bool busy;
/// Último fallo de una acción, para el aviso de la pantalla. `null` tras
/// un éxito o una cancelación.
@override final  GmailFailure? failure;

/// Create a copy of GmailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GmailStateCopyWith<_GmailState> get copyWith => __$GmailStateCopyWithImpl<_GmailState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GmailState&&(identical(other.info, info) || other.info == info)&&(identical(other.promptDismissed, promptDismissed) || other.promptDismissed == promptDismissed)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,info,promptDismissed,busy,failure);

@override
String toString() {
  return 'GmailState(info: $info, promptDismissed: $promptDismissed, busy: $busy, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$GmailStateCopyWith<$Res> implements $GmailStateCopyWith<$Res> {
  factory _$GmailStateCopyWith(_GmailState value, $Res Function(_GmailState) _then) = __$GmailStateCopyWithImpl;
@override @useResult
$Res call({
 GmailConnectionInfo info, bool promptDismissed, bool busy, GmailFailure? failure
});


@override $GmailConnectionInfoCopyWith<$Res> get info;

}
/// @nodoc
class __$GmailStateCopyWithImpl<$Res>
    implements _$GmailStateCopyWith<$Res> {
  __$GmailStateCopyWithImpl(this._self, this._then);

  final _GmailState _self;
  final $Res Function(_GmailState) _then;

/// Create a copy of GmailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? info = null,Object? promptDismissed = null,Object? busy = null,Object? failure = freezed,}) {
  return _then(_GmailState(
info: null == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as GmailConnectionInfo,promptDismissed: null == promptDismissed ? _self.promptDismissed : promptDismissed // ignore: cast_nullable_to_non_nullable
as bool,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as GmailFailure?,
  ));
}

/// Create a copy of GmailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GmailConnectionInfoCopyWith<$Res> get info {
  
  return $GmailConnectionInfoCopyWith<$Res>(_self.info, (value) {
    return _then(_self.copyWith(info: value));
  });
}
}

// dart format on
