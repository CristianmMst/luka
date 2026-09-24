// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gmail_connection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GmailConnectionInfo {

 GmailStatus get status; String? get email; DateTime? get lastSyncAt; DateTime? get watchExpiresAt;
/// Create a copy of GmailConnectionInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GmailConnectionInfoCopyWith<GmailConnectionInfo> get copyWith => _$GmailConnectionInfoCopyWithImpl<GmailConnectionInfo>(this as GmailConnectionInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GmailConnectionInfo&&(identical(other.status, status) || other.status == status)&&(identical(other.email, email) || other.email == email)&&(identical(other.lastSyncAt, lastSyncAt) || other.lastSyncAt == lastSyncAt)&&(identical(other.watchExpiresAt, watchExpiresAt) || other.watchExpiresAt == watchExpiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,status,email,lastSyncAt,watchExpiresAt);

@override
String toString() {
  return 'GmailConnectionInfo(status: $status, email: $email, lastSyncAt: $lastSyncAt, watchExpiresAt: $watchExpiresAt)';
}


}

/// @nodoc
abstract mixin class $GmailConnectionInfoCopyWith<$Res>  {
  factory $GmailConnectionInfoCopyWith(GmailConnectionInfo value, $Res Function(GmailConnectionInfo) _then) = _$GmailConnectionInfoCopyWithImpl;
@useResult
$Res call({
 GmailStatus status, String? email, DateTime? lastSyncAt, DateTime? watchExpiresAt
});




}
/// @nodoc
class _$GmailConnectionInfoCopyWithImpl<$Res>
    implements $GmailConnectionInfoCopyWith<$Res> {
  _$GmailConnectionInfoCopyWithImpl(this._self, this._then);

  final GmailConnectionInfo _self;
  final $Res Function(GmailConnectionInfo) _then;

/// Create a copy of GmailConnectionInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? email = freezed,Object? lastSyncAt = freezed,Object? watchExpiresAt = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GmailStatus,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,lastSyncAt: freezed == lastSyncAt ? _self.lastSyncAt : lastSyncAt // ignore: cast_nullable_to_non_nullable
as DateTime?,watchExpiresAt: freezed == watchExpiresAt ? _self.watchExpiresAt : watchExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [GmailConnectionInfo].
extension GmailConnectionInfoPatterns on GmailConnectionInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GmailConnectionInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GmailConnectionInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GmailConnectionInfo value)  $default,){
final _that = this;
switch (_that) {
case _GmailConnectionInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GmailConnectionInfo value)?  $default,){
final _that = this;
switch (_that) {
case _GmailConnectionInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GmailStatus status,  String? email,  DateTime? lastSyncAt,  DateTime? watchExpiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GmailConnectionInfo() when $default != null:
return $default(_that.status,_that.email,_that.lastSyncAt,_that.watchExpiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GmailStatus status,  String? email,  DateTime? lastSyncAt,  DateTime? watchExpiresAt)  $default,) {final _that = this;
switch (_that) {
case _GmailConnectionInfo():
return $default(_that.status,_that.email,_that.lastSyncAt,_that.watchExpiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GmailStatus status,  String? email,  DateTime? lastSyncAt,  DateTime? watchExpiresAt)?  $default,) {final _that = this;
switch (_that) {
case _GmailConnectionInfo() when $default != null:
return $default(_that.status,_that.email,_that.lastSyncAt,_that.watchExpiresAt);case _:
  return null;

}
}

}

/// @nodoc


class _GmailConnectionInfo extends GmailConnectionInfo {
  const _GmailConnectionInfo({required this.status, this.email, this.lastSyncAt, this.watchExpiresAt}): super._();
  

@override final  GmailStatus status;
@override final  String? email;
@override final  DateTime? lastSyncAt;
@override final  DateTime? watchExpiresAt;

/// Create a copy of GmailConnectionInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GmailConnectionInfoCopyWith<_GmailConnectionInfo> get copyWith => __$GmailConnectionInfoCopyWithImpl<_GmailConnectionInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GmailConnectionInfo&&(identical(other.status, status) || other.status == status)&&(identical(other.email, email) || other.email == email)&&(identical(other.lastSyncAt, lastSyncAt) || other.lastSyncAt == lastSyncAt)&&(identical(other.watchExpiresAt, watchExpiresAt) || other.watchExpiresAt == watchExpiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,status,email,lastSyncAt,watchExpiresAt);

@override
String toString() {
  return 'GmailConnectionInfo(status: $status, email: $email, lastSyncAt: $lastSyncAt, watchExpiresAt: $watchExpiresAt)';
}


}

/// @nodoc
abstract mixin class _$GmailConnectionInfoCopyWith<$Res> implements $GmailConnectionInfoCopyWith<$Res> {
  factory _$GmailConnectionInfoCopyWith(_GmailConnectionInfo value, $Res Function(_GmailConnectionInfo) _then) = __$GmailConnectionInfoCopyWithImpl;
@override @useResult
$Res call({
 GmailStatus status, String? email, DateTime? lastSyncAt, DateTime? watchExpiresAt
});




}
/// @nodoc
class __$GmailConnectionInfoCopyWithImpl<$Res>
    implements _$GmailConnectionInfoCopyWith<$Res> {
  __$GmailConnectionInfoCopyWithImpl(this._self, this._then);

  final _GmailConnectionInfo _self;
  final $Res Function(_GmailConnectionInfo) _then;

/// Create a copy of GmailConnectionInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? email = freezed,Object? lastSyncAt = freezed,Object? watchExpiresAt = freezed,}) {
  return _then(_GmailConnectionInfo(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GmailStatus,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,lastSyncAt: freezed == lastSyncAt ? _self.lastSyncAt : lastSyncAt // ignore: cast_nullable_to_non_nullable
as DateTime?,watchExpiresAt: freezed == watchExpiresAt ? _self.watchExpiresAt : watchExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
