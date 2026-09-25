// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'review_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReviewDraft {

 Cop? get amount; TxDirection? get direction; DateTime? get occurredAt; String? get merchant; String? get categoryId;
/// Create a copy of ReviewDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewDraftCopyWith<ReviewDraft> get copyWith => _$ReviewDraftCopyWithImpl<ReviewDraft>(this as ReviewDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewDraft&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId));
}


@override
int get hashCode => Object.hash(runtimeType,amount,direction,occurredAt,merchant,categoryId);

@override
String toString() {
  return 'ReviewDraft(amount: $amount, direction: $direction, occurredAt: $occurredAt, merchant: $merchant, categoryId: $categoryId)';
}


}

/// @nodoc
abstract mixin class $ReviewDraftCopyWith<$Res>  {
  factory $ReviewDraftCopyWith(ReviewDraft value, $Res Function(ReviewDraft) _then) = _$ReviewDraftCopyWithImpl;
@useResult
$Res call({
 Cop? amount, TxDirection? direction, DateTime? occurredAt, String? merchant, String? categoryId
});




}
/// @nodoc
class _$ReviewDraftCopyWithImpl<$Res>
    implements $ReviewDraftCopyWith<$Res> {
  _$ReviewDraftCopyWithImpl(this._self, this._then);

  final ReviewDraft _self;
  final $Res Function(ReviewDraft) _then;

/// Create a copy of ReviewDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = freezed,Object? direction = freezed,Object? occurredAt = freezed,Object? merchant = freezed,Object? categoryId = freezed,}) {
  return _then(_self.copyWith(
amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Cop?,direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as TxDirection?,occurredAt: freezed == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReviewDraft].
extension ReviewDraftPatterns on ReviewDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReviewDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReviewDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReviewDraft value)  $default,){
final _that = this;
switch (_that) {
case _ReviewDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReviewDraft value)?  $default,){
final _that = this;
switch (_that) {
case _ReviewDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Cop? amount,  TxDirection? direction,  DateTime? occurredAt,  String? merchant,  String? categoryId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReviewDraft() when $default != null:
return $default(_that.amount,_that.direction,_that.occurredAt,_that.merchant,_that.categoryId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Cop? amount,  TxDirection? direction,  DateTime? occurredAt,  String? merchant,  String? categoryId)  $default,) {final _that = this;
switch (_that) {
case _ReviewDraft():
return $default(_that.amount,_that.direction,_that.occurredAt,_that.merchant,_that.categoryId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Cop? amount,  TxDirection? direction,  DateTime? occurredAt,  String? merchant,  String? categoryId)?  $default,) {final _that = this;
switch (_that) {
case _ReviewDraft() when $default != null:
return $default(_that.amount,_that.direction,_that.occurredAt,_that.merchant,_that.categoryId);case _:
  return null;

}
}

}

/// @nodoc


class _ReviewDraft extends ReviewDraft {
  const _ReviewDraft({this.amount, this.direction, this.occurredAt, this.merchant, this.categoryId}): super._();
  

@override final  Cop? amount;
@override final  TxDirection? direction;
@override final  DateTime? occurredAt;
@override final  String? merchant;
@override final  String? categoryId;

/// Create a copy of ReviewDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewDraftCopyWith<_ReviewDraft> get copyWith => __$ReviewDraftCopyWithImpl<_ReviewDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewDraft&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId));
}


@override
int get hashCode => Object.hash(runtimeType,amount,direction,occurredAt,merchant,categoryId);

@override
String toString() {
  return 'ReviewDraft(amount: $amount, direction: $direction, occurredAt: $occurredAt, merchant: $merchant, categoryId: $categoryId)';
}


}

/// @nodoc
abstract mixin class _$ReviewDraftCopyWith<$Res> implements $ReviewDraftCopyWith<$Res> {
  factory _$ReviewDraftCopyWith(_ReviewDraft value, $Res Function(_ReviewDraft) _then) = __$ReviewDraftCopyWithImpl;
@override @useResult
$Res call({
 Cop? amount, TxDirection? direction, DateTime? occurredAt, String? merchant, String? categoryId
});




}
/// @nodoc
class __$ReviewDraftCopyWithImpl<$Res>
    implements _$ReviewDraftCopyWith<$Res> {
  __$ReviewDraftCopyWithImpl(this._self, this._then);

  final _ReviewDraft _self;
  final $Res Function(_ReviewDraft) _then;

/// Create a copy of ReviewDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = freezed,Object? direction = freezed,Object? occurredAt = freezed,Object? merchant = freezed,Object? categoryId = freezed,}) {
  return _then(_ReviewDraft(
amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Cop?,direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as TxDirection?,occurredAt: freezed == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
