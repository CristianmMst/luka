// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurring_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecurringExpense {

 String get id; String get name; String get merchantKeyword; Cop get expectedAmount; int get tolerancePct; int get dayOfMonth; int get remindDaysBefore; bool get active; String? get categoryId; String? get accountId;
/// Create a copy of RecurringExpense
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurringExpenseCopyWith<RecurringExpense> get copyWith => _$RecurringExpenseCopyWithImpl<RecurringExpense>(this as RecurringExpense, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringExpense&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.merchantKeyword, merchantKeyword) || other.merchantKeyword == merchantKeyword)&&(identical(other.expectedAmount, expectedAmount) || other.expectedAmount == expectedAmount)&&(identical(other.tolerancePct, tolerancePct) || other.tolerancePct == tolerancePct)&&(identical(other.dayOfMonth, dayOfMonth) || other.dayOfMonth == dayOfMonth)&&(identical(other.remindDaysBefore, remindDaysBefore) || other.remindDaysBefore == remindDaysBefore)&&(identical(other.active, active) || other.active == active)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.accountId, accountId) || other.accountId == accountId));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,merchantKeyword,expectedAmount,tolerancePct,dayOfMonth,remindDaysBefore,active,categoryId,accountId);

@override
String toString() {
  return 'RecurringExpense(id: $id, name: $name, merchantKeyword: $merchantKeyword, expectedAmount: $expectedAmount, tolerancePct: $tolerancePct, dayOfMonth: $dayOfMonth, remindDaysBefore: $remindDaysBefore, active: $active, categoryId: $categoryId, accountId: $accountId)';
}


}

/// @nodoc
abstract mixin class $RecurringExpenseCopyWith<$Res>  {
  factory $RecurringExpenseCopyWith(RecurringExpense value, $Res Function(RecurringExpense) _then) = _$RecurringExpenseCopyWithImpl;
@useResult
$Res call({
 String id, String name, String merchantKeyword, Cop expectedAmount, int tolerancePct, int dayOfMonth, int remindDaysBefore, bool active, String? categoryId, String? accountId
});




}
/// @nodoc
class _$RecurringExpenseCopyWithImpl<$Res>
    implements $RecurringExpenseCopyWith<$Res> {
  _$RecurringExpenseCopyWithImpl(this._self, this._then);

  final RecurringExpense _self;
  final $Res Function(RecurringExpense) _then;

/// Create a copy of RecurringExpense
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? merchantKeyword = null,Object? expectedAmount = null,Object? tolerancePct = null,Object? dayOfMonth = null,Object? remindDaysBefore = null,Object? active = null,Object? categoryId = freezed,Object? accountId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,merchantKeyword: null == merchantKeyword ? _self.merchantKeyword : merchantKeyword // ignore: cast_nullable_to_non_nullable
as String,expectedAmount: null == expectedAmount ? _self.expectedAmount : expectedAmount // ignore: cast_nullable_to_non_nullable
as Cop,tolerancePct: null == tolerancePct ? _self.tolerancePct : tolerancePct // ignore: cast_nullable_to_non_nullable
as int,dayOfMonth: null == dayOfMonth ? _self.dayOfMonth : dayOfMonth // ignore: cast_nullable_to_non_nullable
as int,remindDaysBefore: null == remindDaysBefore ? _self.remindDaysBefore : remindDaysBefore // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecurringExpense].
extension RecurringExpensePatterns on RecurringExpense {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecurringExpense value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecurringExpense() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecurringExpense value)  $default,){
final _that = this;
switch (_that) {
case _RecurringExpense():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecurringExpense value)?  $default,){
final _that = this;
switch (_that) {
case _RecurringExpense() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String merchantKeyword,  Cop expectedAmount,  int tolerancePct,  int dayOfMonth,  int remindDaysBefore,  bool active,  String? categoryId,  String? accountId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurringExpense() when $default != null:
return $default(_that.id,_that.name,_that.merchantKeyword,_that.expectedAmount,_that.tolerancePct,_that.dayOfMonth,_that.remindDaysBefore,_that.active,_that.categoryId,_that.accountId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String merchantKeyword,  Cop expectedAmount,  int tolerancePct,  int dayOfMonth,  int remindDaysBefore,  bool active,  String? categoryId,  String? accountId)  $default,) {final _that = this;
switch (_that) {
case _RecurringExpense():
return $default(_that.id,_that.name,_that.merchantKeyword,_that.expectedAmount,_that.tolerancePct,_that.dayOfMonth,_that.remindDaysBefore,_that.active,_that.categoryId,_that.accountId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String merchantKeyword,  Cop expectedAmount,  int tolerancePct,  int dayOfMonth,  int remindDaysBefore,  bool active,  String? categoryId,  String? accountId)?  $default,) {final _that = this;
switch (_that) {
case _RecurringExpense() when $default != null:
return $default(_that.id,_that.name,_that.merchantKeyword,_that.expectedAmount,_that.tolerancePct,_that.dayOfMonth,_that.remindDaysBefore,_that.active,_that.categoryId,_that.accountId);case _:
  return null;

}
}

}

/// @nodoc


class _RecurringExpense implements RecurringExpense {
  const _RecurringExpense({required this.id, required this.name, required this.merchantKeyword, required this.expectedAmount, required this.tolerancePct, required this.dayOfMonth, required this.remindDaysBefore, required this.active, this.categoryId, this.accountId});
  

@override final  String id;
@override final  String name;
@override final  String merchantKeyword;
@override final  Cop expectedAmount;
@override final  int tolerancePct;
@override final  int dayOfMonth;
@override final  int remindDaysBefore;
@override final  bool active;
@override final  String? categoryId;
@override final  String? accountId;

/// Create a copy of RecurringExpense
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurringExpenseCopyWith<_RecurringExpense> get copyWith => __$RecurringExpenseCopyWithImpl<_RecurringExpense>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurringExpense&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.merchantKeyword, merchantKeyword) || other.merchantKeyword == merchantKeyword)&&(identical(other.expectedAmount, expectedAmount) || other.expectedAmount == expectedAmount)&&(identical(other.tolerancePct, tolerancePct) || other.tolerancePct == tolerancePct)&&(identical(other.dayOfMonth, dayOfMonth) || other.dayOfMonth == dayOfMonth)&&(identical(other.remindDaysBefore, remindDaysBefore) || other.remindDaysBefore == remindDaysBefore)&&(identical(other.active, active) || other.active == active)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.accountId, accountId) || other.accountId == accountId));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,merchantKeyword,expectedAmount,tolerancePct,dayOfMonth,remindDaysBefore,active,categoryId,accountId);

@override
String toString() {
  return 'RecurringExpense(id: $id, name: $name, merchantKeyword: $merchantKeyword, expectedAmount: $expectedAmount, tolerancePct: $tolerancePct, dayOfMonth: $dayOfMonth, remindDaysBefore: $remindDaysBefore, active: $active, categoryId: $categoryId, accountId: $accountId)';
}


}

/// @nodoc
abstract mixin class _$RecurringExpenseCopyWith<$Res> implements $RecurringExpenseCopyWith<$Res> {
  factory _$RecurringExpenseCopyWith(_RecurringExpense value, $Res Function(_RecurringExpense) _then) = __$RecurringExpenseCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String merchantKeyword, Cop expectedAmount, int tolerancePct, int dayOfMonth, int remindDaysBefore, bool active, String? categoryId, String? accountId
});




}
/// @nodoc
class __$RecurringExpenseCopyWithImpl<$Res>
    implements _$RecurringExpenseCopyWith<$Res> {
  __$RecurringExpenseCopyWithImpl(this._self, this._then);

  final _RecurringExpense _self;
  final $Res Function(_RecurringExpense) _then;

/// Create a copy of RecurringExpense
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? merchantKeyword = null,Object? expectedAmount = null,Object? tolerancePct = null,Object? dayOfMonth = null,Object? remindDaysBefore = null,Object? active = null,Object? categoryId = freezed,Object? accountId = freezed,}) {
  return _then(_RecurringExpense(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,merchantKeyword: null == merchantKeyword ? _self.merchantKeyword : merchantKeyword // ignore: cast_nullable_to_non_nullable
as String,expectedAmount: null == expectedAmount ? _self.expectedAmount : expectedAmount // ignore: cast_nullable_to_non_nullable
as Cop,tolerancePct: null == tolerancePct ? _self.tolerancePct : tolerancePct // ignore: cast_nullable_to_non_nullable
as int,dayOfMonth: null == dayOfMonth ? _self.dayOfMonth : dayOfMonth // ignore: cast_nullable_to_non_nullable
as int,remindDaysBefore: null == remindDaysBefore ? _self.remindDaysBefore : remindDaysBefore // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$RecurringOccurrence {

 String get id; String get expenseId; String get name; Cop get expectedAmount; String get period; DateTime get dueDate; OccurrenceStatus get status; String? get categoryId; String? get matchedBy; DateTime? get paidAt; String? get transactionId; String? get transactionMerchant; Cop? get transactionAmount; DateTime? get transactionOccurredAt;
/// Create a copy of RecurringOccurrence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurringOccurrenceCopyWith<RecurringOccurrence> get copyWith => _$RecurringOccurrenceCopyWithImpl<RecurringOccurrence>(this as RecurringOccurrence, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringOccurrence&&(identical(other.id, id) || other.id == id)&&(identical(other.expenseId, expenseId) || other.expenseId == expenseId)&&(identical(other.name, name) || other.name == name)&&(identical(other.expectedAmount, expectedAmount) || other.expectedAmount == expectedAmount)&&(identical(other.period, period) || other.period == period)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.matchedBy, matchedBy) || other.matchedBy == matchedBy)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.transactionId, transactionId) || other.transactionId == transactionId)&&(identical(other.transactionMerchant, transactionMerchant) || other.transactionMerchant == transactionMerchant)&&(identical(other.transactionAmount, transactionAmount) || other.transactionAmount == transactionAmount)&&(identical(other.transactionOccurredAt, transactionOccurredAt) || other.transactionOccurredAt == transactionOccurredAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,expenseId,name,expectedAmount,period,dueDate,status,categoryId,matchedBy,paidAt,transactionId,transactionMerchant,transactionAmount,transactionOccurredAt);

@override
String toString() {
  return 'RecurringOccurrence(id: $id, expenseId: $expenseId, name: $name, expectedAmount: $expectedAmount, period: $period, dueDate: $dueDate, status: $status, categoryId: $categoryId, matchedBy: $matchedBy, paidAt: $paidAt, transactionId: $transactionId, transactionMerchant: $transactionMerchant, transactionAmount: $transactionAmount, transactionOccurredAt: $transactionOccurredAt)';
}


}

/// @nodoc
abstract mixin class $RecurringOccurrenceCopyWith<$Res>  {
  factory $RecurringOccurrenceCopyWith(RecurringOccurrence value, $Res Function(RecurringOccurrence) _then) = _$RecurringOccurrenceCopyWithImpl;
@useResult
$Res call({
 String id, String expenseId, String name, Cop expectedAmount, String period, DateTime dueDate, OccurrenceStatus status, String? categoryId, String? matchedBy, DateTime? paidAt, String? transactionId, String? transactionMerchant, Cop? transactionAmount, DateTime? transactionOccurredAt
});




}
/// @nodoc
class _$RecurringOccurrenceCopyWithImpl<$Res>
    implements $RecurringOccurrenceCopyWith<$Res> {
  _$RecurringOccurrenceCopyWithImpl(this._self, this._then);

  final RecurringOccurrence _self;
  final $Res Function(RecurringOccurrence) _then;

/// Create a copy of RecurringOccurrence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? expenseId = null,Object? name = null,Object? expectedAmount = null,Object? period = null,Object? dueDate = null,Object? status = null,Object? categoryId = freezed,Object? matchedBy = freezed,Object? paidAt = freezed,Object? transactionId = freezed,Object? transactionMerchant = freezed,Object? transactionAmount = freezed,Object? transactionOccurredAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,expenseId: null == expenseId ? _self.expenseId : expenseId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,expectedAmount: null == expectedAmount ? _self.expectedAmount : expectedAmount // ignore: cast_nullable_to_non_nullable
as Cop,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OccurrenceStatus,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,matchedBy: freezed == matchedBy ? _self.matchedBy : matchedBy // ignore: cast_nullable_to_non_nullable
as String?,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,transactionId: freezed == transactionId ? _self.transactionId : transactionId // ignore: cast_nullable_to_non_nullable
as String?,transactionMerchant: freezed == transactionMerchant ? _self.transactionMerchant : transactionMerchant // ignore: cast_nullable_to_non_nullable
as String?,transactionAmount: freezed == transactionAmount ? _self.transactionAmount : transactionAmount // ignore: cast_nullable_to_non_nullable
as Cop?,transactionOccurredAt: freezed == transactionOccurredAt ? _self.transactionOccurredAt : transactionOccurredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecurringOccurrence].
extension RecurringOccurrencePatterns on RecurringOccurrence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecurringOccurrence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecurringOccurrence() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecurringOccurrence value)  $default,){
final _that = this;
switch (_that) {
case _RecurringOccurrence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecurringOccurrence value)?  $default,){
final _that = this;
switch (_that) {
case _RecurringOccurrence() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String expenseId,  String name,  Cop expectedAmount,  String period,  DateTime dueDate,  OccurrenceStatus status,  String? categoryId,  String? matchedBy,  DateTime? paidAt,  String? transactionId,  String? transactionMerchant,  Cop? transactionAmount,  DateTime? transactionOccurredAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurringOccurrence() when $default != null:
return $default(_that.id,_that.expenseId,_that.name,_that.expectedAmount,_that.period,_that.dueDate,_that.status,_that.categoryId,_that.matchedBy,_that.paidAt,_that.transactionId,_that.transactionMerchant,_that.transactionAmount,_that.transactionOccurredAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String expenseId,  String name,  Cop expectedAmount,  String period,  DateTime dueDate,  OccurrenceStatus status,  String? categoryId,  String? matchedBy,  DateTime? paidAt,  String? transactionId,  String? transactionMerchant,  Cop? transactionAmount,  DateTime? transactionOccurredAt)  $default,) {final _that = this;
switch (_that) {
case _RecurringOccurrence():
return $default(_that.id,_that.expenseId,_that.name,_that.expectedAmount,_that.period,_that.dueDate,_that.status,_that.categoryId,_that.matchedBy,_that.paidAt,_that.transactionId,_that.transactionMerchant,_that.transactionAmount,_that.transactionOccurredAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String expenseId,  String name,  Cop expectedAmount,  String period,  DateTime dueDate,  OccurrenceStatus status,  String? categoryId,  String? matchedBy,  DateTime? paidAt,  String? transactionId,  String? transactionMerchant,  Cop? transactionAmount,  DateTime? transactionOccurredAt)?  $default,) {final _that = this;
switch (_that) {
case _RecurringOccurrence() when $default != null:
return $default(_that.id,_that.expenseId,_that.name,_that.expectedAmount,_that.period,_that.dueDate,_that.status,_that.categoryId,_that.matchedBy,_that.paidAt,_that.transactionId,_that.transactionMerchant,_that.transactionAmount,_that.transactionOccurredAt);case _:
  return null;

}
}

}

/// @nodoc


class _RecurringOccurrence implements RecurringOccurrence {
  const _RecurringOccurrence({required this.id, required this.expenseId, required this.name, required this.expectedAmount, required this.period, required this.dueDate, required this.status, this.categoryId, this.matchedBy, this.paidAt, this.transactionId, this.transactionMerchant, this.transactionAmount, this.transactionOccurredAt});
  

@override final  String id;
@override final  String expenseId;
@override final  String name;
@override final  Cop expectedAmount;
@override final  String period;
@override final  DateTime dueDate;
@override final  OccurrenceStatus status;
@override final  String? categoryId;
@override final  String? matchedBy;
@override final  DateTime? paidAt;
@override final  String? transactionId;
@override final  String? transactionMerchant;
@override final  Cop? transactionAmount;
@override final  DateTime? transactionOccurredAt;

/// Create a copy of RecurringOccurrence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurringOccurrenceCopyWith<_RecurringOccurrence> get copyWith => __$RecurringOccurrenceCopyWithImpl<_RecurringOccurrence>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurringOccurrence&&(identical(other.id, id) || other.id == id)&&(identical(other.expenseId, expenseId) || other.expenseId == expenseId)&&(identical(other.name, name) || other.name == name)&&(identical(other.expectedAmount, expectedAmount) || other.expectedAmount == expectedAmount)&&(identical(other.period, period) || other.period == period)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.matchedBy, matchedBy) || other.matchedBy == matchedBy)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.transactionId, transactionId) || other.transactionId == transactionId)&&(identical(other.transactionMerchant, transactionMerchant) || other.transactionMerchant == transactionMerchant)&&(identical(other.transactionAmount, transactionAmount) || other.transactionAmount == transactionAmount)&&(identical(other.transactionOccurredAt, transactionOccurredAt) || other.transactionOccurredAt == transactionOccurredAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,expenseId,name,expectedAmount,period,dueDate,status,categoryId,matchedBy,paidAt,transactionId,transactionMerchant,transactionAmount,transactionOccurredAt);

@override
String toString() {
  return 'RecurringOccurrence(id: $id, expenseId: $expenseId, name: $name, expectedAmount: $expectedAmount, period: $period, dueDate: $dueDate, status: $status, categoryId: $categoryId, matchedBy: $matchedBy, paidAt: $paidAt, transactionId: $transactionId, transactionMerchant: $transactionMerchant, transactionAmount: $transactionAmount, transactionOccurredAt: $transactionOccurredAt)';
}


}

/// @nodoc
abstract mixin class _$RecurringOccurrenceCopyWith<$Res> implements $RecurringOccurrenceCopyWith<$Res> {
  factory _$RecurringOccurrenceCopyWith(_RecurringOccurrence value, $Res Function(_RecurringOccurrence) _then) = __$RecurringOccurrenceCopyWithImpl;
@override @useResult
$Res call({
 String id, String expenseId, String name, Cop expectedAmount, String period, DateTime dueDate, OccurrenceStatus status, String? categoryId, String? matchedBy, DateTime? paidAt, String? transactionId, String? transactionMerchant, Cop? transactionAmount, DateTime? transactionOccurredAt
});




}
/// @nodoc
class __$RecurringOccurrenceCopyWithImpl<$Res>
    implements _$RecurringOccurrenceCopyWith<$Res> {
  __$RecurringOccurrenceCopyWithImpl(this._self, this._then);

  final _RecurringOccurrence _self;
  final $Res Function(_RecurringOccurrence) _then;

/// Create a copy of RecurringOccurrence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? expenseId = null,Object? name = null,Object? expectedAmount = null,Object? period = null,Object? dueDate = null,Object? status = null,Object? categoryId = freezed,Object? matchedBy = freezed,Object? paidAt = freezed,Object? transactionId = freezed,Object? transactionMerchant = freezed,Object? transactionAmount = freezed,Object? transactionOccurredAt = freezed,}) {
  return _then(_RecurringOccurrence(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,expenseId: null == expenseId ? _self.expenseId : expenseId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,expectedAmount: null == expectedAmount ? _self.expectedAmount : expectedAmount // ignore: cast_nullable_to_non_nullable
as Cop,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OccurrenceStatus,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,matchedBy: freezed == matchedBy ? _self.matchedBy : matchedBy // ignore: cast_nullable_to_non_nullable
as String?,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,transactionId: freezed == transactionId ? _self.transactionId : transactionId // ignore: cast_nullable_to_non_nullable
as String?,transactionMerchant: freezed == transactionMerchant ? _self.transactionMerchant : transactionMerchant // ignore: cast_nullable_to_non_nullable
as String?,transactionAmount: freezed == transactionAmount ? _self.transactionAmount : transactionAmount // ignore: cast_nullable_to_non_nullable
as Cop?,transactionOccurredAt: freezed == transactionOccurredAt ? _self.transactionOccurredAt : transactionOccurredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$PaymentCandidate {

 String get id; Cop get amount; DateTime get occurredAt; String? get merchant;
/// Create a copy of PaymentCandidate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentCandidateCopyWith<PaymentCandidate> get copyWith => _$PaymentCandidateCopyWithImpl<PaymentCandidate>(this as PaymentCandidate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentCandidate&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.merchant, merchant) || other.merchant == merchant));
}


@override
int get hashCode => Object.hash(runtimeType,id,amount,occurredAt,merchant);

@override
String toString() {
  return 'PaymentCandidate(id: $id, amount: $amount, occurredAt: $occurredAt, merchant: $merchant)';
}


}

/// @nodoc
abstract mixin class $PaymentCandidateCopyWith<$Res>  {
  factory $PaymentCandidateCopyWith(PaymentCandidate value, $Res Function(PaymentCandidate) _then) = _$PaymentCandidateCopyWithImpl;
@useResult
$Res call({
 String id, Cop amount, DateTime occurredAt, String? merchant
});




}
/// @nodoc
class _$PaymentCandidateCopyWithImpl<$Res>
    implements $PaymentCandidateCopyWith<$Res> {
  _$PaymentCandidateCopyWithImpl(this._self, this._then);

  final PaymentCandidate _self;
  final $Res Function(PaymentCandidate) _then;

/// Create a copy of PaymentCandidate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? amount = null,Object? occurredAt = null,Object? merchant = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Cop,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentCandidate].
extension PaymentCandidatePatterns on PaymentCandidate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentCandidate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentCandidate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentCandidate value)  $default,){
final _that = this;
switch (_that) {
case _PaymentCandidate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentCandidate value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentCandidate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  Cop amount,  DateTime occurredAt,  String? merchant)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentCandidate() when $default != null:
return $default(_that.id,_that.amount,_that.occurredAt,_that.merchant);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  Cop amount,  DateTime occurredAt,  String? merchant)  $default,) {final _that = this;
switch (_that) {
case _PaymentCandidate():
return $default(_that.id,_that.amount,_that.occurredAt,_that.merchant);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  Cop amount,  DateTime occurredAt,  String? merchant)?  $default,) {final _that = this;
switch (_that) {
case _PaymentCandidate() when $default != null:
return $default(_that.id,_that.amount,_that.occurredAt,_that.merchant);case _:
  return null;

}
}

}

/// @nodoc


class _PaymentCandidate implements PaymentCandidate {
  const _PaymentCandidate({required this.id, required this.amount, required this.occurredAt, this.merchant});
  

@override final  String id;
@override final  Cop amount;
@override final  DateTime occurredAt;
@override final  String? merchant;

/// Create a copy of PaymentCandidate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentCandidateCopyWith<_PaymentCandidate> get copyWith => __$PaymentCandidateCopyWithImpl<_PaymentCandidate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentCandidate&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.merchant, merchant) || other.merchant == merchant));
}


@override
int get hashCode => Object.hash(runtimeType,id,amount,occurredAt,merchant);

@override
String toString() {
  return 'PaymentCandidate(id: $id, amount: $amount, occurredAt: $occurredAt, merchant: $merchant)';
}


}

/// @nodoc
abstract mixin class _$PaymentCandidateCopyWith<$Res> implements $PaymentCandidateCopyWith<$Res> {
  factory _$PaymentCandidateCopyWith(_PaymentCandidate value, $Res Function(_PaymentCandidate) _then) = __$PaymentCandidateCopyWithImpl;
@override @useResult
$Res call({
 String id, Cop amount, DateTime occurredAt, String? merchant
});




}
/// @nodoc
class __$PaymentCandidateCopyWithImpl<$Res>
    implements _$PaymentCandidateCopyWith<$Res> {
  __$PaymentCandidateCopyWithImpl(this._self, this._then);

  final _PaymentCandidate _self;
  final $Res Function(_PaymentCandidate) _then;

/// Create a copy of PaymentCandidate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? amount = null,Object? occurredAt = null,Object? merchant = freezed,}) {
  return _then(_PaymentCandidate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Cop,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
