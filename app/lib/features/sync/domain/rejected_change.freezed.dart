// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rejected_change.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RejectedChange {

 int get seq; OutboxOperation get op;/// Código del rechazo: el `code` del sobre de error (`not_found`,
/// `validation_error`…), el status HTTP si no había sobre (`'404'`) o
/// `dependency_rejected`; `null` si no se guardó.
 String? get reason;/// Datos del movimiento local afectado, si todavía existe.
 String? get merchant; int? get amountCents; String? get direction;
/// Create a copy of RejectedChange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RejectedChangeCopyWith<RejectedChange> get copyWith => _$RejectedChangeCopyWithImpl<RejectedChange>(this as RejectedChange, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RejectedChange&&(identical(other.seq, seq) || other.seq == seq)&&(identical(other.op, op) || other.op == op)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.direction, direction) || other.direction == direction));
}


@override
int get hashCode => Object.hash(runtimeType,seq,op,reason,merchant,amountCents,direction);

@override
String toString() {
  return 'RejectedChange(seq: $seq, op: $op, reason: $reason, merchant: $merchant, amountCents: $amountCents, direction: $direction)';
}


}

/// @nodoc
abstract mixin class $RejectedChangeCopyWith<$Res>  {
  factory $RejectedChangeCopyWith(RejectedChange value, $Res Function(RejectedChange) _then) = _$RejectedChangeCopyWithImpl;
@useResult
$Res call({
 int seq, OutboxOperation op, String? reason, String? merchant, int? amountCents, String? direction
});


$OutboxOperationCopyWith<$Res> get op;

}
/// @nodoc
class _$RejectedChangeCopyWithImpl<$Res>
    implements $RejectedChangeCopyWith<$Res> {
  _$RejectedChangeCopyWithImpl(this._self, this._then);

  final RejectedChange _self;
  final $Res Function(RejectedChange) _then;

/// Create a copy of RejectedChange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seq = null,Object? op = null,Object? reason = freezed,Object? merchant = freezed,Object? amountCents = freezed,Object? direction = freezed,}) {
  return _then(_self.copyWith(
seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,op: null == op ? _self.op : op // ignore: cast_nullable_to_non_nullable
as OutboxOperation,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,amountCents: freezed == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int?,direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of RejectedChange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OutboxOperationCopyWith<$Res> get op {
  
  return $OutboxOperationCopyWith<$Res>(_self.op, (value) {
    return _then(_self.copyWith(op: value));
  });
}
}


/// Adds pattern-matching-related methods to [RejectedChange].
extension RejectedChangePatterns on RejectedChange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RejectedChange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RejectedChange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RejectedChange value)  $default,){
final _that = this;
switch (_that) {
case _RejectedChange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RejectedChange value)?  $default,){
final _that = this;
switch (_that) {
case _RejectedChange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int seq,  OutboxOperation op,  String? reason,  String? merchant,  int? amountCents,  String? direction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RejectedChange() when $default != null:
return $default(_that.seq,_that.op,_that.reason,_that.merchant,_that.amountCents,_that.direction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int seq,  OutboxOperation op,  String? reason,  String? merchant,  int? amountCents,  String? direction)  $default,) {final _that = this;
switch (_that) {
case _RejectedChange():
return $default(_that.seq,_that.op,_that.reason,_that.merchant,_that.amountCents,_that.direction);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int seq,  OutboxOperation op,  String? reason,  String? merchant,  int? amountCents,  String? direction)?  $default,) {final _that = this;
switch (_that) {
case _RejectedChange() when $default != null:
return $default(_that.seq,_that.op,_that.reason,_that.merchant,_that.amountCents,_that.direction);case _:
  return null;

}
}

}

/// @nodoc


class _RejectedChange implements RejectedChange {
  const _RejectedChange({required this.seq, required this.op, this.reason, this.merchant, this.amountCents, this.direction});
  

@override final  int seq;
@override final  OutboxOperation op;
/// Código del rechazo: el `code` del sobre de error (`not_found`,
/// `validation_error`…), el status HTTP si no había sobre (`'404'`) o
/// `dependency_rejected`; `null` si no se guardó.
@override final  String? reason;
/// Datos del movimiento local afectado, si todavía existe.
@override final  String? merchant;
@override final  int? amountCents;
@override final  String? direction;

/// Create a copy of RejectedChange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RejectedChangeCopyWith<_RejectedChange> get copyWith => __$RejectedChangeCopyWithImpl<_RejectedChange>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RejectedChange&&(identical(other.seq, seq) || other.seq == seq)&&(identical(other.op, op) || other.op == op)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.direction, direction) || other.direction == direction));
}


@override
int get hashCode => Object.hash(runtimeType,seq,op,reason,merchant,amountCents,direction);

@override
String toString() {
  return 'RejectedChange(seq: $seq, op: $op, reason: $reason, merchant: $merchant, amountCents: $amountCents, direction: $direction)';
}


}

/// @nodoc
abstract mixin class _$RejectedChangeCopyWith<$Res> implements $RejectedChangeCopyWith<$Res> {
  factory _$RejectedChangeCopyWith(_RejectedChange value, $Res Function(_RejectedChange) _then) = __$RejectedChangeCopyWithImpl;
@override @useResult
$Res call({
 int seq, OutboxOperation op, String? reason, String? merchant, int? amountCents, String? direction
});


@override $OutboxOperationCopyWith<$Res> get op;

}
/// @nodoc
class __$RejectedChangeCopyWithImpl<$Res>
    implements _$RejectedChangeCopyWith<$Res> {
  __$RejectedChangeCopyWithImpl(this._self, this._then);

  final _RejectedChange _self;
  final $Res Function(_RejectedChange) _then;

/// Create a copy of RejectedChange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seq = null,Object? op = null,Object? reason = freezed,Object? merchant = freezed,Object? amountCents = freezed,Object? direction = freezed,}) {
  return _then(_RejectedChange(
seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,op: null == op ? _self.op : op // ignore: cast_nullable_to_non_nullable
as OutboxOperation,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,amountCents: freezed == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int?,direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of RejectedChange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OutboxOperationCopyWith<$Res> get op {
  
  return $OutboxOperationCopyWith<$Res>(_self.op, (value) {
    return _then(_self.copyWith(op: value));
  });
}
}

// dart format on
