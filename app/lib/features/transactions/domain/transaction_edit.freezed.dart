// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_edit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransactionEdit {

 Cop? get amount; TxDirection get direction; DateTime get occurredAt; String? get merchant; String? get categoryId; String? get accountId;
/// Create a copy of TransactionEdit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionEditCopyWith<TransactionEdit> get copyWith => _$TransactionEditCopyWithImpl<TransactionEdit>(this as TransactionEdit, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionEdit&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.accountId, accountId) || other.accountId == accountId));
}


@override
int get hashCode => Object.hash(runtimeType,amount,direction,occurredAt,merchant,categoryId,accountId);

@override
String toString() {
  return 'TransactionEdit(amount: $amount, direction: $direction, occurredAt: $occurredAt, merchant: $merchant, categoryId: $categoryId, accountId: $accountId)';
}


}

/// @nodoc
abstract mixin class $TransactionEditCopyWith<$Res>  {
  factory $TransactionEditCopyWith(TransactionEdit value, $Res Function(TransactionEdit) _then) = _$TransactionEditCopyWithImpl;
@useResult
$Res call({
 Cop? amount, TxDirection direction, DateTime occurredAt, String? merchant, String? categoryId, String? accountId
});




}
/// @nodoc
class _$TransactionEditCopyWithImpl<$Res>
    implements $TransactionEditCopyWith<$Res> {
  _$TransactionEditCopyWithImpl(this._self, this._then);

  final TransactionEdit _self;
  final $Res Function(TransactionEdit) _then;

/// Create a copy of TransactionEdit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = freezed,Object? direction = null,Object? occurredAt = null,Object? merchant = freezed,Object? categoryId = freezed,Object? accountId = freezed,}) {
  return _then(_self.copyWith(
amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Cop?,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as TxDirection,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TransactionEdit].
extension TransactionEditPatterns on TransactionEdit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionEdit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionEdit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionEdit value)  $default,){
final _that = this;
switch (_that) {
case _TransactionEdit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionEdit value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionEdit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Cop? amount,  TxDirection direction,  DateTime occurredAt,  String? merchant,  String? categoryId,  String? accountId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionEdit() when $default != null:
return $default(_that.amount,_that.direction,_that.occurredAt,_that.merchant,_that.categoryId,_that.accountId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Cop? amount,  TxDirection direction,  DateTime occurredAt,  String? merchant,  String? categoryId,  String? accountId)  $default,) {final _that = this;
switch (_that) {
case _TransactionEdit():
return $default(_that.amount,_that.direction,_that.occurredAt,_that.merchant,_that.categoryId,_that.accountId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Cop? amount,  TxDirection direction,  DateTime occurredAt,  String? merchant,  String? categoryId,  String? accountId)?  $default,) {final _that = this;
switch (_that) {
case _TransactionEdit() when $default != null:
return $default(_that.amount,_that.direction,_that.occurredAt,_that.merchant,_that.categoryId,_that.accountId);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionEdit extends TransactionEdit {
  const _TransactionEdit({required this.amount, required this.direction, required this.occurredAt, this.merchant, this.categoryId, this.accountId}): super._();
  

@override final  Cop? amount;
@override final  TxDirection direction;
@override final  DateTime occurredAt;
@override final  String? merchant;
@override final  String? categoryId;
@override final  String? accountId;

/// Create a copy of TransactionEdit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionEditCopyWith<_TransactionEdit> get copyWith => __$TransactionEditCopyWithImpl<_TransactionEdit>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionEdit&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.accountId, accountId) || other.accountId == accountId));
}


@override
int get hashCode => Object.hash(runtimeType,amount,direction,occurredAt,merchant,categoryId,accountId);

@override
String toString() {
  return 'TransactionEdit(amount: $amount, direction: $direction, occurredAt: $occurredAt, merchant: $merchant, categoryId: $categoryId, accountId: $accountId)';
}


}

/// @nodoc
abstract mixin class _$TransactionEditCopyWith<$Res> implements $TransactionEditCopyWith<$Res> {
  factory _$TransactionEditCopyWith(_TransactionEdit value, $Res Function(_TransactionEdit) _then) = __$TransactionEditCopyWithImpl;
@override @useResult
$Res call({
 Cop? amount, TxDirection direction, DateTime occurredAt, String? merchant, String? categoryId, String? accountId
});




}
/// @nodoc
class __$TransactionEditCopyWithImpl<$Res>
    implements _$TransactionEditCopyWith<$Res> {
  __$TransactionEditCopyWithImpl(this._self, this._then);

  final _TransactionEdit _self;
  final $Res Function(_TransactionEdit) _then;

/// Create a copy of TransactionEdit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = freezed,Object? direction = null,Object? occurredAt = null,Object? merchant = freezed,Object? categoryId = freezed,Object? accountId = freezed,}) {
  return _then(_TransactionEdit(
amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Cop?,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as TxDirection,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
