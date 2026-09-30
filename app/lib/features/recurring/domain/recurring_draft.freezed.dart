// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurring_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecurringDraft {

 String get name; String get merchantKeyword; Cop? get expectedAmount; int get dayOfMonth; int get tolerancePct; int get remindDaysBefore; String? get categoryId; String? get accountId;
/// Create a copy of RecurringDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurringDraftCopyWith<RecurringDraft> get copyWith => _$RecurringDraftCopyWithImpl<RecurringDraft>(this as RecurringDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringDraft&&(identical(other.name, name) || other.name == name)&&(identical(other.merchantKeyword, merchantKeyword) || other.merchantKeyword == merchantKeyword)&&(identical(other.expectedAmount, expectedAmount) || other.expectedAmount == expectedAmount)&&(identical(other.dayOfMonth, dayOfMonth) || other.dayOfMonth == dayOfMonth)&&(identical(other.tolerancePct, tolerancePct) || other.tolerancePct == tolerancePct)&&(identical(other.remindDaysBefore, remindDaysBefore) || other.remindDaysBefore == remindDaysBefore)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.accountId, accountId) || other.accountId == accountId));
}


@override
int get hashCode => Object.hash(runtimeType,name,merchantKeyword,expectedAmount,dayOfMonth,tolerancePct,remindDaysBefore,categoryId,accountId);

@override
String toString() {
  return 'RecurringDraft(name: $name, merchantKeyword: $merchantKeyword, expectedAmount: $expectedAmount, dayOfMonth: $dayOfMonth, tolerancePct: $tolerancePct, remindDaysBefore: $remindDaysBefore, categoryId: $categoryId, accountId: $accountId)';
}


}

/// @nodoc
abstract mixin class $RecurringDraftCopyWith<$Res>  {
  factory $RecurringDraftCopyWith(RecurringDraft value, $Res Function(RecurringDraft) _then) = _$RecurringDraftCopyWithImpl;
@useResult
$Res call({
 String name, String merchantKeyword, Cop? expectedAmount, int dayOfMonth, int tolerancePct, int remindDaysBefore, String? categoryId, String? accountId
});




}
/// @nodoc
class _$RecurringDraftCopyWithImpl<$Res>
    implements $RecurringDraftCopyWith<$Res> {
  _$RecurringDraftCopyWithImpl(this._self, this._then);

  final RecurringDraft _self;
  final $Res Function(RecurringDraft) _then;

/// Create a copy of RecurringDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? merchantKeyword = null,Object? expectedAmount = freezed,Object? dayOfMonth = null,Object? tolerancePct = null,Object? remindDaysBefore = null,Object? categoryId = freezed,Object? accountId = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,merchantKeyword: null == merchantKeyword ? _self.merchantKeyword : merchantKeyword // ignore: cast_nullable_to_non_nullable
as String,expectedAmount: freezed == expectedAmount ? _self.expectedAmount : expectedAmount // ignore: cast_nullable_to_non_nullable
as Cop?,dayOfMonth: null == dayOfMonth ? _self.dayOfMonth : dayOfMonth // ignore: cast_nullable_to_non_nullable
as int,tolerancePct: null == tolerancePct ? _self.tolerancePct : tolerancePct // ignore: cast_nullable_to_non_nullable
as int,remindDaysBefore: null == remindDaysBefore ? _self.remindDaysBefore : remindDaysBefore // ignore: cast_nullable_to_non_nullable
as int,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecurringDraft].
extension RecurringDraftPatterns on RecurringDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecurringDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecurringDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecurringDraft value)  $default,){
final _that = this;
switch (_that) {
case _RecurringDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecurringDraft value)?  $default,){
final _that = this;
switch (_that) {
case _RecurringDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String merchantKeyword,  Cop? expectedAmount,  int dayOfMonth,  int tolerancePct,  int remindDaysBefore,  String? categoryId,  String? accountId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurringDraft() when $default != null:
return $default(_that.name,_that.merchantKeyword,_that.expectedAmount,_that.dayOfMonth,_that.tolerancePct,_that.remindDaysBefore,_that.categoryId,_that.accountId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String merchantKeyword,  Cop? expectedAmount,  int dayOfMonth,  int tolerancePct,  int remindDaysBefore,  String? categoryId,  String? accountId)  $default,) {final _that = this;
switch (_that) {
case _RecurringDraft():
return $default(_that.name,_that.merchantKeyword,_that.expectedAmount,_that.dayOfMonth,_that.tolerancePct,_that.remindDaysBefore,_that.categoryId,_that.accountId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String merchantKeyword,  Cop? expectedAmount,  int dayOfMonth,  int tolerancePct,  int remindDaysBefore,  String? categoryId,  String? accountId)?  $default,) {final _that = this;
switch (_that) {
case _RecurringDraft() when $default != null:
return $default(_that.name,_that.merchantKeyword,_that.expectedAmount,_that.dayOfMonth,_that.tolerancePct,_that.remindDaysBefore,_that.categoryId,_that.accountId);case _:
  return null;

}
}

}

/// @nodoc


class _RecurringDraft extends RecurringDraft {
  const _RecurringDraft({required this.name, required this.merchantKeyword, this.expectedAmount, this.dayOfMonth = 0, this.tolerancePct = 10, this.remindDaysBefore = 1, this.categoryId, this.accountId}): super._();
  

@override final  String name;
@override final  String merchantKeyword;
@override final  Cop? expectedAmount;
@override@JsonKey() final  int dayOfMonth;
@override@JsonKey() final  int tolerancePct;
@override@JsonKey() final  int remindDaysBefore;
@override final  String? categoryId;
@override final  String? accountId;

/// Create a copy of RecurringDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurringDraftCopyWith<_RecurringDraft> get copyWith => __$RecurringDraftCopyWithImpl<_RecurringDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurringDraft&&(identical(other.name, name) || other.name == name)&&(identical(other.merchantKeyword, merchantKeyword) || other.merchantKeyword == merchantKeyword)&&(identical(other.expectedAmount, expectedAmount) || other.expectedAmount == expectedAmount)&&(identical(other.dayOfMonth, dayOfMonth) || other.dayOfMonth == dayOfMonth)&&(identical(other.tolerancePct, tolerancePct) || other.tolerancePct == tolerancePct)&&(identical(other.remindDaysBefore, remindDaysBefore) || other.remindDaysBefore == remindDaysBefore)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.accountId, accountId) || other.accountId == accountId));
}


@override
int get hashCode => Object.hash(runtimeType,name,merchantKeyword,expectedAmount,dayOfMonth,tolerancePct,remindDaysBefore,categoryId,accountId);

@override
String toString() {
  return 'RecurringDraft(name: $name, merchantKeyword: $merchantKeyword, expectedAmount: $expectedAmount, dayOfMonth: $dayOfMonth, tolerancePct: $tolerancePct, remindDaysBefore: $remindDaysBefore, categoryId: $categoryId, accountId: $accountId)';
}


}

/// @nodoc
abstract mixin class _$RecurringDraftCopyWith<$Res> implements $RecurringDraftCopyWith<$Res> {
  factory _$RecurringDraftCopyWith(_RecurringDraft value, $Res Function(_RecurringDraft) _then) = __$RecurringDraftCopyWithImpl;
@override @useResult
$Res call({
 String name, String merchantKeyword, Cop? expectedAmount, int dayOfMonth, int tolerancePct, int remindDaysBefore, String? categoryId, String? accountId
});




}
/// @nodoc
class __$RecurringDraftCopyWithImpl<$Res>
    implements _$RecurringDraftCopyWith<$Res> {
  __$RecurringDraftCopyWithImpl(this._self, this._then);

  final _RecurringDraft _self;
  final $Res Function(_RecurringDraft) _then;

/// Create a copy of RecurringDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? merchantKeyword = null,Object? expectedAmount = freezed,Object? dayOfMonth = null,Object? tolerancePct = null,Object? remindDaysBefore = null,Object? categoryId = freezed,Object? accountId = freezed,}) {
  return _then(_RecurringDraft(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,merchantKeyword: null == merchantKeyword ? _self.merchantKeyword : merchantKeyword // ignore: cast_nullable_to_non_nullable
as String,expectedAmount: freezed == expectedAmount ? _self.expectedAmount : expectedAmount // ignore: cast_nullable_to_non_nullable
as Cop?,dayOfMonth: null == dayOfMonth ? _self.dayOfMonth : dayOfMonth // ignore: cast_nullable_to_non_nullable
as int,tolerancePct: null == tolerancePct ? _self.tolerancePct : tolerancePct // ignore: cast_nullable_to_non_nullable
as int,remindDaysBefore: null == remindDaysBefore ? _self.remindDaysBefore : remindDaysBefore // ignore: cast_nullable_to_non_nullable
as int,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
