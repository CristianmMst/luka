// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'day_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DayGroup {

 DateTime get day; DayLabel get label; Cop get expenses; List<TransactionView> get items;
/// Create a copy of DayGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayGroupCopyWith<DayGroup> get copyWith => _$DayGroupCopyWithImpl<DayGroup>(this as DayGroup, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayGroup&&(identical(other.day, day) || other.day == day)&&(identical(other.label, label) || other.label == label)&&(identical(other.expenses, expenses) || other.expenses == expenses)&&const DeepCollectionEquality().equals(other.items, items));
}


@override
int get hashCode => Object.hash(runtimeType,day,label,expenses,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'DayGroup(day: $day, label: $label, expenses: $expenses, items: $items)';
}


}

/// @nodoc
abstract mixin class $DayGroupCopyWith<$Res>  {
  factory $DayGroupCopyWith(DayGroup value, $Res Function(DayGroup) _then) = _$DayGroupCopyWithImpl;
@useResult
$Res call({
 DateTime day, DayLabel label, Cop expenses, List<TransactionView> items
});




}
/// @nodoc
class _$DayGroupCopyWithImpl<$Res>
    implements $DayGroupCopyWith<$Res> {
  _$DayGroupCopyWithImpl(this._self, this._then);

  final DayGroup _self;
  final $Res Function(DayGroup) _then;

/// Create a copy of DayGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? day = null,Object? label = null,Object? expenses = null,Object? items = null,}) {
  return _then(_self.copyWith(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as DayLabel,expenses: null == expenses ? _self.expenses : expenses // ignore: cast_nullable_to_non_nullable
as Cop,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<TransactionView>,
  ));
}

}


/// Adds pattern-matching-related methods to [DayGroup].
extension DayGroupPatterns on DayGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayGroup value)  $default,){
final _that = this;
switch (_that) {
case _DayGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayGroup value)?  $default,){
final _that = this;
switch (_that) {
case _DayGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime day,  DayLabel label,  Cop expenses,  List<TransactionView> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayGroup() when $default != null:
return $default(_that.day,_that.label,_that.expenses,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime day,  DayLabel label,  Cop expenses,  List<TransactionView> items)  $default,) {final _that = this;
switch (_that) {
case _DayGroup():
return $default(_that.day,_that.label,_that.expenses,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime day,  DayLabel label,  Cop expenses,  List<TransactionView> items)?  $default,) {final _that = this;
switch (_that) {
case _DayGroup() when $default != null:
return $default(_that.day,_that.label,_that.expenses,_that.items);case _:
  return null;

}
}

}

/// @nodoc


class _DayGroup implements DayGroup {
  const _DayGroup({required this.day, required this.label, required this.expenses, required final  List<TransactionView> items}): _items = items;
  

@override final  DateTime day;
@override final  DayLabel label;
@override final  Cop expenses;
 final  List<TransactionView> _items;
@override List<TransactionView> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of DayGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayGroupCopyWith<_DayGroup> get copyWith => __$DayGroupCopyWithImpl<_DayGroup>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayGroup&&(identical(other.day, day) || other.day == day)&&(identical(other.label, label) || other.label == label)&&(identical(other.expenses, expenses) || other.expenses == expenses)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,day,label,expenses,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'DayGroup(day: $day, label: $label, expenses: $expenses, items: $items)';
}


}

/// @nodoc
abstract mixin class _$DayGroupCopyWith<$Res> implements $DayGroupCopyWith<$Res> {
  factory _$DayGroupCopyWith(_DayGroup value, $Res Function(_DayGroup) _then) = __$DayGroupCopyWithImpl;
@override @useResult
$Res call({
 DateTime day, DayLabel label, Cop expenses, List<TransactionView> items
});




}
/// @nodoc
class __$DayGroupCopyWithImpl<$Res>
    implements _$DayGroupCopyWith<$Res> {
  __$DayGroupCopyWithImpl(this._self, this._then);

  final _DayGroup _self;
  final $Res Function(_DayGroup) _then;

/// Create a copy of DayGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? day = null,Object? label = null,Object? expenses = null,Object? items = null,}) {
  return _then(_DayGroup(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as DayLabel,expenses: null == expenses ? _self.expenses : expenses // ignore: cast_nullable_to_non_nullable
as Cop,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<TransactionView>,
  ));
}


}

// dart format on
