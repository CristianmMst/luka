// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transactions_list_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransactionsListState {

 TransactionFilter get filter; int get limit; AsyncValue<List<DayGroup>> get groups; bool get hasMore;
/// Create a copy of TransactionsListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionsListStateCopyWith<TransactionsListState> get copyWith => _$TransactionsListStateCopyWithImpl<TransactionsListState>(this as TransactionsListState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionsListState&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.groups, groups) || other.groups == groups)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}


@override
int get hashCode => Object.hash(runtimeType,filter,limit,groups,hasMore);

@override
String toString() {
  return 'TransactionsListState(filter: $filter, limit: $limit, groups: $groups, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class $TransactionsListStateCopyWith<$Res>  {
  factory $TransactionsListStateCopyWith(TransactionsListState value, $Res Function(TransactionsListState) _then) = _$TransactionsListStateCopyWithImpl;
@useResult
$Res call({
 TransactionFilter filter, int limit, AsyncValue<List<DayGroup>> groups, bool hasMore
});


$TransactionFilterCopyWith<$Res> get filter;

}
/// @nodoc
class _$TransactionsListStateCopyWithImpl<$Res>
    implements $TransactionsListStateCopyWith<$Res> {
  _$TransactionsListStateCopyWithImpl(this._self, this._then);

  final TransactionsListState _self;
  final $Res Function(TransactionsListState) _then;

/// Create a copy of TransactionsListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? filter = null,Object? limit = null,Object? groups = null,Object? hasMore = null,}) {
  return _then(_self.copyWith(
filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as TransactionFilter,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,groups: null == groups ? _self.groups : groups // ignore: cast_nullable_to_non_nullable
as AsyncValue<List<DayGroup>>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of TransactionsListState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionFilterCopyWith<$Res> get filter {
  
  return $TransactionFilterCopyWith<$Res>(_self.filter, (value) {
    return _then(_self.copyWith(filter: value));
  });
}
}


/// Adds pattern-matching-related methods to [TransactionsListState].
extension TransactionsListStatePatterns on TransactionsListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionsListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionsListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionsListState value)  $default,){
final _that = this;
switch (_that) {
case _TransactionsListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionsListState value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionsListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TransactionFilter filter,  int limit,  AsyncValue<List<DayGroup>> groups,  bool hasMore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionsListState() when $default != null:
return $default(_that.filter,_that.limit,_that.groups,_that.hasMore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TransactionFilter filter,  int limit,  AsyncValue<List<DayGroup>> groups,  bool hasMore)  $default,) {final _that = this;
switch (_that) {
case _TransactionsListState():
return $default(_that.filter,_that.limit,_that.groups,_that.hasMore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TransactionFilter filter,  int limit,  AsyncValue<List<DayGroup>> groups,  bool hasMore)?  $default,) {final _that = this;
switch (_that) {
case _TransactionsListState() when $default != null:
return $default(_that.filter,_that.limit,_that.groups,_that.hasMore);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionsListState implements TransactionsListState {
  const _TransactionsListState({required this.filter, required this.limit, required this.groups, required this.hasMore});
  

@override final  TransactionFilter filter;
@override final  int limit;
@override final  AsyncValue<List<DayGroup>> groups;
@override final  bool hasMore;

/// Create a copy of TransactionsListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionsListStateCopyWith<_TransactionsListState> get copyWith => __$TransactionsListStateCopyWithImpl<_TransactionsListState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionsListState&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.groups, groups) || other.groups == groups)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}


@override
int get hashCode => Object.hash(runtimeType,filter,limit,groups,hasMore);

@override
String toString() {
  return 'TransactionsListState(filter: $filter, limit: $limit, groups: $groups, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class _$TransactionsListStateCopyWith<$Res> implements $TransactionsListStateCopyWith<$Res> {
  factory _$TransactionsListStateCopyWith(_TransactionsListState value, $Res Function(_TransactionsListState) _then) = __$TransactionsListStateCopyWithImpl;
@override @useResult
$Res call({
 TransactionFilter filter, int limit, AsyncValue<List<DayGroup>> groups, bool hasMore
});


@override $TransactionFilterCopyWith<$Res> get filter;

}
/// @nodoc
class __$TransactionsListStateCopyWithImpl<$Res>
    implements _$TransactionsListStateCopyWith<$Res> {
  __$TransactionsListStateCopyWithImpl(this._self, this._then);

  final _TransactionsListState _self;
  final $Res Function(_TransactionsListState) _then;

/// Create a copy of TransactionsListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? filter = null,Object? limit = null,Object? groups = null,Object? hasMore = null,}) {
  return _then(_TransactionsListState(
filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as TransactionFilter,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,groups: null == groups ? _self.groups : groups // ignore: cast_nullable_to_non_nullable
as AsyncValue<List<DayGroup>>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of TransactionsListState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionFilterCopyWith<$Res> get filter {
  
  return $TransactionFilterCopyWith<$Res>(_self.filter, (value) {
    return _then(_self.copyWith(filter: value));
  });
}
}

// dart format on
