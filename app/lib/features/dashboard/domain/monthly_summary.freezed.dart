// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'monthly_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MonthlyTotals {

 Cop get expenses; Cop get income;
/// Create a copy of MonthlyTotals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthlyTotalsCopyWith<MonthlyTotals> get copyWith => _$MonthlyTotalsCopyWithImpl<MonthlyTotals>(this as MonthlyTotals, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthlyTotals&&(identical(other.expenses, expenses) || other.expenses == expenses)&&(identical(other.income, income) || other.income == income));
}


@override
int get hashCode => Object.hash(runtimeType,expenses,income);

@override
String toString() {
  return 'MonthlyTotals(expenses: $expenses, income: $income)';
}


}

/// @nodoc
abstract mixin class $MonthlyTotalsCopyWith<$Res>  {
  factory $MonthlyTotalsCopyWith(MonthlyTotals value, $Res Function(MonthlyTotals) _then) = _$MonthlyTotalsCopyWithImpl;
@useResult
$Res call({
 Cop expenses, Cop income
});




}
/// @nodoc
class _$MonthlyTotalsCopyWithImpl<$Res>
    implements $MonthlyTotalsCopyWith<$Res> {
  _$MonthlyTotalsCopyWithImpl(this._self, this._then);

  final MonthlyTotals _self;
  final $Res Function(MonthlyTotals) _then;

/// Create a copy of MonthlyTotals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? expenses = null,Object? income = null,}) {
  return _then(_self.copyWith(
expenses: null == expenses ? _self.expenses : expenses // ignore: cast_nullable_to_non_nullable
as Cop,income: null == income ? _self.income : income // ignore: cast_nullable_to_non_nullable
as Cop,
  ));
}

}


/// Adds pattern-matching-related methods to [MonthlyTotals].
extension MonthlyTotalsPatterns on MonthlyTotals {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonthlyTotals value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonthlyTotals() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonthlyTotals value)  $default,){
final _that = this;
switch (_that) {
case _MonthlyTotals():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonthlyTotals value)?  $default,){
final _that = this;
switch (_that) {
case _MonthlyTotals() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Cop expenses,  Cop income)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonthlyTotals() when $default != null:
return $default(_that.expenses,_that.income);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Cop expenses,  Cop income)  $default,) {final _that = this;
switch (_that) {
case _MonthlyTotals():
return $default(_that.expenses,_that.income);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Cop expenses,  Cop income)?  $default,) {final _that = this;
switch (_that) {
case _MonthlyTotals() when $default != null:
return $default(_that.expenses,_that.income);case _:
  return null;

}
}

}

/// @nodoc


class _MonthlyTotals extends MonthlyTotals {
  const _MonthlyTotals({this.expenses = const Cop(0), this.income = const Cop(0)}): super._();
  

@override@JsonKey() final  Cop expenses;
@override@JsonKey() final  Cop income;

/// Create a copy of MonthlyTotals
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonthlyTotalsCopyWith<_MonthlyTotals> get copyWith => __$MonthlyTotalsCopyWithImpl<_MonthlyTotals>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonthlyTotals&&(identical(other.expenses, expenses) || other.expenses == expenses)&&(identical(other.income, income) || other.income == income));
}


@override
int get hashCode => Object.hash(runtimeType,expenses,income);

@override
String toString() {
  return 'MonthlyTotals(expenses: $expenses, income: $income)';
}


}

/// @nodoc
abstract mixin class _$MonthlyTotalsCopyWith<$Res> implements $MonthlyTotalsCopyWith<$Res> {
  factory _$MonthlyTotalsCopyWith(_MonthlyTotals value, $Res Function(_MonthlyTotals) _then) = __$MonthlyTotalsCopyWithImpl;
@override @useResult
$Res call({
 Cop expenses, Cop income
});




}
/// @nodoc
class __$MonthlyTotalsCopyWithImpl<$Res>
    implements _$MonthlyTotalsCopyWith<$Res> {
  __$MonthlyTotalsCopyWithImpl(this._self, this._then);

  final _MonthlyTotals _self;
  final $Res Function(_MonthlyTotals) _then;

/// Create a copy of MonthlyTotals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? expenses = null,Object? income = null,}) {
  return _then(_MonthlyTotals(
expenses: null == expenses ? _self.expenses : expenses // ignore: cast_nullable_to_non_nullable
as Cop,income: null == income ? _self.income : income // ignore: cast_nullable_to_non_nullable
as Cop,
  ));
}


}

/// @nodoc
mixin _$CategorySpend {

 String? get categoryId; Cop get amount; String? get slug; String? get name;
/// Create a copy of CategorySpend
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategorySpendCopyWith<CategorySpend> get copyWith => _$CategorySpendCopyWithImpl<CategorySpend>(this as CategorySpend, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategorySpend&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,categoryId,amount,slug,name);

@override
String toString() {
  return 'CategorySpend(categoryId: $categoryId, amount: $amount, slug: $slug, name: $name)';
}


}

/// @nodoc
abstract mixin class $CategorySpendCopyWith<$Res>  {
  factory $CategorySpendCopyWith(CategorySpend value, $Res Function(CategorySpend) _then) = _$CategorySpendCopyWithImpl;
@useResult
$Res call({
 String? categoryId, Cop amount, String? slug, String? name
});




}
/// @nodoc
class _$CategorySpendCopyWithImpl<$Res>
    implements $CategorySpendCopyWith<$Res> {
  _$CategorySpendCopyWithImpl(this._self, this._then);

  final CategorySpend _self;
  final $Res Function(CategorySpend) _then;

/// Create a copy of CategorySpend
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryId = freezed,Object? amount = null,Object? slug = freezed,Object? name = freezed,}) {
  return _then(_self.copyWith(
categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Cop,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CategorySpend].
extension CategorySpendPatterns on CategorySpend {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategorySpend value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategorySpend() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategorySpend value)  $default,){
final _that = this;
switch (_that) {
case _CategorySpend():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategorySpend value)?  $default,){
final _that = this;
switch (_that) {
case _CategorySpend() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? categoryId,  Cop amount,  String? slug,  String? name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategorySpend() when $default != null:
return $default(_that.categoryId,_that.amount,_that.slug,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? categoryId,  Cop amount,  String? slug,  String? name)  $default,) {final _that = this;
switch (_that) {
case _CategorySpend():
return $default(_that.categoryId,_that.amount,_that.slug,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? categoryId,  Cop amount,  String? slug,  String? name)?  $default,) {final _that = this;
switch (_that) {
case _CategorySpend() when $default != null:
return $default(_that.categoryId,_that.amount,_that.slug,_that.name);case _:
  return null;

}
}

}

/// @nodoc


class _CategorySpend implements CategorySpend {
  const _CategorySpend({required this.categoryId, required this.amount, this.slug, this.name});
  

@override final  String? categoryId;
@override final  Cop amount;
@override final  String? slug;
@override final  String? name;

/// Create a copy of CategorySpend
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategorySpendCopyWith<_CategorySpend> get copyWith => __$CategorySpendCopyWithImpl<_CategorySpend>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategorySpend&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,categoryId,amount,slug,name);

@override
String toString() {
  return 'CategorySpend(categoryId: $categoryId, amount: $amount, slug: $slug, name: $name)';
}


}

/// @nodoc
abstract mixin class _$CategorySpendCopyWith<$Res> implements $CategorySpendCopyWith<$Res> {
  factory _$CategorySpendCopyWith(_CategorySpend value, $Res Function(_CategorySpend) _then) = __$CategorySpendCopyWithImpl;
@override @useResult
$Res call({
 String? categoryId, Cop amount, String? slug, String? name
});




}
/// @nodoc
class __$CategorySpendCopyWithImpl<$Res>
    implements _$CategorySpendCopyWith<$Res> {
  __$CategorySpendCopyWithImpl(this._self, this._then);

  final _CategorySpend _self;
  final $Res Function(_CategorySpend) _then;

/// Create a copy of CategorySpend
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryId = freezed,Object? amount = null,Object? slug = freezed,Object? name = freezed,}) {
  return _then(_CategorySpend(
categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Cop,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$AmountDelta {

 Cop get difference; int? get percent;
/// Create a copy of AmountDelta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AmountDeltaCopyWith<AmountDelta> get copyWith => _$AmountDeltaCopyWithImpl<AmountDelta>(this as AmountDelta, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AmountDelta&&(identical(other.difference, difference) || other.difference == difference)&&(identical(other.percent, percent) || other.percent == percent));
}


@override
int get hashCode => Object.hash(runtimeType,difference,percent);

@override
String toString() {
  return 'AmountDelta(difference: $difference, percent: $percent)';
}


}

/// @nodoc
abstract mixin class $AmountDeltaCopyWith<$Res>  {
  factory $AmountDeltaCopyWith(AmountDelta value, $Res Function(AmountDelta) _then) = _$AmountDeltaCopyWithImpl;
@useResult
$Res call({
 Cop difference, int? percent
});




}
/// @nodoc
class _$AmountDeltaCopyWithImpl<$Res>
    implements $AmountDeltaCopyWith<$Res> {
  _$AmountDeltaCopyWithImpl(this._self, this._then);

  final AmountDelta _self;
  final $Res Function(AmountDelta) _then;

/// Create a copy of AmountDelta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? difference = null,Object? percent = freezed,}) {
  return _then(_self.copyWith(
difference: null == difference ? _self.difference : difference // ignore: cast_nullable_to_non_nullable
as Cop,percent: freezed == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [AmountDelta].
extension AmountDeltaPatterns on AmountDelta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AmountDelta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AmountDelta() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AmountDelta value)  $default,){
final _that = this;
switch (_that) {
case _AmountDelta():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AmountDelta value)?  $default,){
final _that = this;
switch (_that) {
case _AmountDelta() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Cop difference,  int? percent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AmountDelta() when $default != null:
return $default(_that.difference,_that.percent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Cop difference,  int? percent)  $default,) {final _that = this;
switch (_that) {
case _AmountDelta():
return $default(_that.difference,_that.percent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Cop difference,  int? percent)?  $default,) {final _that = this;
switch (_that) {
case _AmountDelta() when $default != null:
return $default(_that.difference,_that.percent);case _:
  return null;

}
}

}

/// @nodoc


class _AmountDelta implements AmountDelta {
  const _AmountDelta({required this.difference, this.percent});
  

@override final  Cop difference;
@override final  int? percent;

/// Create a copy of AmountDelta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AmountDeltaCopyWith<_AmountDelta> get copyWith => __$AmountDeltaCopyWithImpl<_AmountDelta>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AmountDelta&&(identical(other.difference, difference) || other.difference == difference)&&(identical(other.percent, percent) || other.percent == percent));
}


@override
int get hashCode => Object.hash(runtimeType,difference,percent);

@override
String toString() {
  return 'AmountDelta(difference: $difference, percent: $percent)';
}


}

/// @nodoc
abstract mixin class _$AmountDeltaCopyWith<$Res> implements $AmountDeltaCopyWith<$Res> {
  factory _$AmountDeltaCopyWith(_AmountDelta value, $Res Function(_AmountDelta) _then) = __$AmountDeltaCopyWithImpl;
@override @useResult
$Res call({
 Cop difference, int? percent
});




}
/// @nodoc
class __$AmountDeltaCopyWithImpl<$Res>
    implements _$AmountDeltaCopyWith<$Res> {
  __$AmountDeltaCopyWithImpl(this._self, this._then);

  final _AmountDelta _self;
  final $Res Function(_AmountDelta) _then;

/// Create a copy of AmountDelta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? difference = null,Object? percent = freezed,}) {
  return _then(_AmountDelta(
difference: null == difference ? _self.difference : difference // ignore: cast_nullable_to_non_nullable
as Cop,percent: freezed == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$MonthlySummary {

 ColombiaMonth get month; MonthlyTotals get totals; MonthlyTotals get previousTotals;/// Hasta [topCategoriesCount] categorías de gasto, de mayor a menor.
 List<CategorySpend> get topCategories;/// Gasto del resto de categorías ("Otras categorías").
 Cop get otherAmount;
/// Create a copy of MonthlySummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthlySummaryCopyWith<MonthlySummary> get copyWith => _$MonthlySummaryCopyWithImpl<MonthlySummary>(this as MonthlySummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthlySummary&&(identical(other.month, month) || other.month == month)&&(identical(other.totals, totals) || other.totals == totals)&&(identical(other.previousTotals, previousTotals) || other.previousTotals == previousTotals)&&const DeepCollectionEquality().equals(other.topCategories, topCategories)&&(identical(other.otherAmount, otherAmount) || other.otherAmount == otherAmount));
}


@override
int get hashCode => Object.hash(runtimeType,month,totals,previousTotals,const DeepCollectionEquality().hash(topCategories),otherAmount);

@override
String toString() {
  return 'MonthlySummary(month: $month, totals: $totals, previousTotals: $previousTotals, topCategories: $topCategories, otherAmount: $otherAmount)';
}


}

/// @nodoc
abstract mixin class $MonthlySummaryCopyWith<$Res>  {
  factory $MonthlySummaryCopyWith(MonthlySummary value, $Res Function(MonthlySummary) _then) = _$MonthlySummaryCopyWithImpl;
@useResult
$Res call({
 ColombiaMonth month, MonthlyTotals totals, MonthlyTotals previousTotals, List<CategorySpend> topCategories, Cop otherAmount
});


$MonthlyTotalsCopyWith<$Res> get totals;$MonthlyTotalsCopyWith<$Res> get previousTotals;

}
/// @nodoc
class _$MonthlySummaryCopyWithImpl<$Res>
    implements $MonthlySummaryCopyWith<$Res> {
  _$MonthlySummaryCopyWithImpl(this._self, this._then);

  final MonthlySummary _self;
  final $Res Function(MonthlySummary) _then;

/// Create a copy of MonthlySummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? month = null,Object? totals = null,Object? previousTotals = null,Object? topCategories = null,Object? otherAmount = null,}) {
  return _then(_self.copyWith(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as ColombiaMonth,totals: null == totals ? _self.totals : totals // ignore: cast_nullable_to_non_nullable
as MonthlyTotals,previousTotals: null == previousTotals ? _self.previousTotals : previousTotals // ignore: cast_nullable_to_non_nullable
as MonthlyTotals,topCategories: null == topCategories ? _self.topCategories : topCategories // ignore: cast_nullable_to_non_nullable
as List<CategorySpend>,otherAmount: null == otherAmount ? _self.otherAmount : otherAmount // ignore: cast_nullable_to_non_nullable
as Cop,
  ));
}
/// Create a copy of MonthlySummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonthlyTotalsCopyWith<$Res> get totals {
  
  return $MonthlyTotalsCopyWith<$Res>(_self.totals, (value) {
    return _then(_self.copyWith(totals: value));
  });
}/// Create a copy of MonthlySummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonthlyTotalsCopyWith<$Res> get previousTotals {
  
  return $MonthlyTotalsCopyWith<$Res>(_self.previousTotals, (value) {
    return _then(_self.copyWith(previousTotals: value));
  });
}
}


/// Adds pattern-matching-related methods to [MonthlySummary].
extension MonthlySummaryPatterns on MonthlySummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonthlySummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonthlySummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonthlySummary value)  $default,){
final _that = this;
switch (_that) {
case _MonthlySummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonthlySummary value)?  $default,){
final _that = this;
switch (_that) {
case _MonthlySummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ColombiaMonth month,  MonthlyTotals totals,  MonthlyTotals previousTotals,  List<CategorySpend> topCategories,  Cop otherAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonthlySummary() when $default != null:
return $default(_that.month,_that.totals,_that.previousTotals,_that.topCategories,_that.otherAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ColombiaMonth month,  MonthlyTotals totals,  MonthlyTotals previousTotals,  List<CategorySpend> topCategories,  Cop otherAmount)  $default,) {final _that = this;
switch (_that) {
case _MonthlySummary():
return $default(_that.month,_that.totals,_that.previousTotals,_that.topCategories,_that.otherAmount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ColombiaMonth month,  MonthlyTotals totals,  MonthlyTotals previousTotals,  List<CategorySpend> topCategories,  Cop otherAmount)?  $default,) {final _that = this;
switch (_that) {
case _MonthlySummary() when $default != null:
return $default(_that.month,_that.totals,_that.previousTotals,_that.topCategories,_that.otherAmount);case _:
  return null;

}
}

}

/// @nodoc


class _MonthlySummary extends MonthlySummary {
  const _MonthlySummary({required this.month, required this.totals, required this.previousTotals, required final  List<CategorySpend> topCategories, required this.otherAmount}): _topCategories = topCategories,super._();
  

@override final  ColombiaMonth month;
@override final  MonthlyTotals totals;
@override final  MonthlyTotals previousTotals;
/// Hasta [topCategoriesCount] categorías de gasto, de mayor a menor.
 final  List<CategorySpend> _topCategories;
/// Hasta [topCategoriesCount] categorías de gasto, de mayor a menor.
@override List<CategorySpend> get topCategories {
  if (_topCategories is EqualUnmodifiableListView) return _topCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topCategories);
}

/// Gasto del resto de categorías ("Otras categorías").
@override final  Cop otherAmount;

/// Create a copy of MonthlySummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonthlySummaryCopyWith<_MonthlySummary> get copyWith => __$MonthlySummaryCopyWithImpl<_MonthlySummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonthlySummary&&(identical(other.month, month) || other.month == month)&&(identical(other.totals, totals) || other.totals == totals)&&(identical(other.previousTotals, previousTotals) || other.previousTotals == previousTotals)&&const DeepCollectionEquality().equals(other._topCategories, _topCategories)&&(identical(other.otherAmount, otherAmount) || other.otherAmount == otherAmount));
}


@override
int get hashCode => Object.hash(runtimeType,month,totals,previousTotals,const DeepCollectionEquality().hash(_topCategories),otherAmount);

@override
String toString() {
  return 'MonthlySummary(month: $month, totals: $totals, previousTotals: $previousTotals, topCategories: $topCategories, otherAmount: $otherAmount)';
}


}

/// @nodoc
abstract mixin class _$MonthlySummaryCopyWith<$Res> implements $MonthlySummaryCopyWith<$Res> {
  factory _$MonthlySummaryCopyWith(_MonthlySummary value, $Res Function(_MonthlySummary) _then) = __$MonthlySummaryCopyWithImpl;
@override @useResult
$Res call({
 ColombiaMonth month, MonthlyTotals totals, MonthlyTotals previousTotals, List<CategorySpend> topCategories, Cop otherAmount
});


@override $MonthlyTotalsCopyWith<$Res> get totals;@override $MonthlyTotalsCopyWith<$Res> get previousTotals;

}
/// @nodoc
class __$MonthlySummaryCopyWithImpl<$Res>
    implements _$MonthlySummaryCopyWith<$Res> {
  __$MonthlySummaryCopyWithImpl(this._self, this._then);

  final _MonthlySummary _self;
  final $Res Function(_MonthlySummary) _then;

/// Create a copy of MonthlySummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? month = null,Object? totals = null,Object? previousTotals = null,Object? topCategories = null,Object? otherAmount = null,}) {
  return _then(_MonthlySummary(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as ColombiaMonth,totals: null == totals ? _self.totals : totals // ignore: cast_nullable_to_non_nullable
as MonthlyTotals,previousTotals: null == previousTotals ? _self.previousTotals : previousTotals // ignore: cast_nullable_to_non_nullable
as MonthlyTotals,topCategories: null == topCategories ? _self._topCategories : topCategories // ignore: cast_nullable_to_non_nullable
as List<CategorySpend>,otherAmount: null == otherAmount ? _self.otherAmount : otherAmount // ignore: cast_nullable_to_non_nullable
as Cop,
  ));
}

/// Create a copy of MonthlySummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonthlyTotalsCopyWith<$Res> get totals {
  
  return $MonthlyTotalsCopyWith<$Res>(_self.totals, (value) {
    return _then(_self.copyWith(totals: value));
  });
}/// Create a copy of MonthlySummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MonthlyTotalsCopyWith<$Res> get previousTotals {
  
  return $MonthlyTotalsCopyWith<$Res>(_self.previousTotals, (value) {
    return _then(_self.copyWith(previousTotals: value));
  });
}
}

// dart format on
