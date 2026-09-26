// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'manual_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ManualDraft {

 DateTime get occurredAt; Cop? get amount; TxDirection get direction; String? get merchant; String? get categoryId; String? get notes;
/// Create a copy of ManualDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ManualDraftCopyWith<ManualDraft> get copyWith => _$ManualDraftCopyWithImpl<ManualDraft>(this as ManualDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ManualDraft&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,occurredAt,amount,direction,merchant,categoryId,notes);

@override
String toString() {
  return 'ManualDraft(occurredAt: $occurredAt, amount: $amount, direction: $direction, merchant: $merchant, categoryId: $categoryId, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $ManualDraftCopyWith<$Res>  {
  factory $ManualDraftCopyWith(ManualDraft value, $Res Function(ManualDraft) _then) = _$ManualDraftCopyWithImpl;
@useResult
$Res call({
 DateTime occurredAt, Cop? amount, TxDirection direction, String? merchant, String? categoryId, String? notes
});




}
/// @nodoc
class _$ManualDraftCopyWithImpl<$Res>
    implements $ManualDraftCopyWith<$Res> {
  _$ManualDraftCopyWithImpl(this._self, this._then);

  final ManualDraft _self;
  final $Res Function(ManualDraft) _then;

/// Create a copy of ManualDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? occurredAt = null,Object? amount = freezed,Object? direction = null,Object? merchant = freezed,Object? categoryId = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Cop?,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as TxDirection,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ManualDraft].
extension ManualDraftPatterns on ManualDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ManualDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ManualDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ManualDraft value)  $default,){
final _that = this;
switch (_that) {
case _ManualDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ManualDraft value)?  $default,){
final _that = this;
switch (_that) {
case _ManualDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime occurredAt,  Cop? amount,  TxDirection direction,  String? merchant,  String? categoryId,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ManualDraft() when $default != null:
return $default(_that.occurredAt,_that.amount,_that.direction,_that.merchant,_that.categoryId,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime occurredAt,  Cop? amount,  TxDirection direction,  String? merchant,  String? categoryId,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _ManualDraft():
return $default(_that.occurredAt,_that.amount,_that.direction,_that.merchant,_that.categoryId,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime occurredAt,  Cop? amount,  TxDirection direction,  String? merchant,  String? categoryId,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _ManualDraft() when $default != null:
return $default(_that.occurredAt,_that.amount,_that.direction,_that.merchant,_that.categoryId,_that.notes);case _:
  return null;

}
}

}

/// @nodoc


class _ManualDraft extends ManualDraft {
  const _ManualDraft({required this.occurredAt, this.amount, this.direction = TxDirection.debit, this.merchant, this.categoryId, this.notes}): super._();
  

@override final  DateTime occurredAt;
@override final  Cop? amount;
@override@JsonKey() final  TxDirection direction;
@override final  String? merchant;
@override final  String? categoryId;
@override final  String? notes;

/// Create a copy of ManualDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ManualDraftCopyWith<_ManualDraft> get copyWith => __$ManualDraftCopyWithImpl<_ManualDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ManualDraft&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,occurredAt,amount,direction,merchant,categoryId,notes);

@override
String toString() {
  return 'ManualDraft(occurredAt: $occurredAt, amount: $amount, direction: $direction, merchant: $merchant, categoryId: $categoryId, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$ManualDraftCopyWith<$Res> implements $ManualDraftCopyWith<$Res> {
  factory _$ManualDraftCopyWith(_ManualDraft value, $Res Function(_ManualDraft) _then) = __$ManualDraftCopyWithImpl;
@override @useResult
$Res call({
 DateTime occurredAt, Cop? amount, TxDirection direction, String? merchant, String? categoryId, String? notes
});




}
/// @nodoc
class __$ManualDraftCopyWithImpl<$Res>
    implements _$ManualDraftCopyWith<$Res> {
  __$ManualDraftCopyWithImpl(this._self, this._then);

  final _ManualDraft _self;
  final $Res Function(_ManualDraft) _then;

/// Create a copy of ManualDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? occurredAt = null,Object? amount = freezed,Object? direction = null,Object? merchant = freezed,Object? categoryId = freezed,Object? notes = freezed,}) {
  return _then(_ManualDraft(
occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Cop?,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as TxDirection,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
