// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransactionFilter {

 PeriodPreset get period; DateTime? get from; DateTime? get to; Set<TxKind> get kinds; Set<String> get banks; Set<TxChannel> get channels; String? get categoryId; String get text;
/// Create a copy of TransactionFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionFilterCopyWith<TransactionFilter> get copyWith => _$TransactionFilterCopyWithImpl<TransactionFilter>(this as TransactionFilter, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFilter&&(identical(other.period, period) || other.period == period)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&const DeepCollectionEquality().equals(other.kinds, kinds)&&const DeepCollectionEquality().equals(other.banks, banks)&&const DeepCollectionEquality().equals(other.channels, channels)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,period,from,to,const DeepCollectionEquality().hash(kinds),const DeepCollectionEquality().hash(banks),const DeepCollectionEquality().hash(channels),categoryId,text);

@override
String toString() {
  return 'TransactionFilter(period: $period, from: $from, to: $to, kinds: $kinds, banks: $banks, channels: $channels, categoryId: $categoryId, text: $text)';
}


}

/// @nodoc
abstract mixin class $TransactionFilterCopyWith<$Res>  {
  factory $TransactionFilterCopyWith(TransactionFilter value, $Res Function(TransactionFilter) _then) = _$TransactionFilterCopyWithImpl;
@useResult
$Res call({
 PeriodPreset period, DateTime? from, DateTime? to, Set<TxKind> kinds, Set<String> banks, Set<TxChannel> channels, String? categoryId, String text
});




}
/// @nodoc
class _$TransactionFilterCopyWithImpl<$Res>
    implements $TransactionFilterCopyWith<$Res> {
  _$TransactionFilterCopyWithImpl(this._self, this._then);

  final TransactionFilter _self;
  final $Res Function(TransactionFilter) _then;

/// Create a copy of TransactionFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? period = null,Object? from = freezed,Object? to = freezed,Object? kinds = null,Object? banks = null,Object? channels = null,Object? categoryId = freezed,Object? text = null,}) {
  return _then(_self.copyWith(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as PeriodPreset,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as DateTime?,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as DateTime?,kinds: null == kinds ? _self.kinds : kinds // ignore: cast_nullable_to_non_nullable
as Set<TxKind>,banks: null == banks ? _self.banks : banks // ignore: cast_nullable_to_non_nullable
as Set<String>,channels: null == channels ? _self.channels : channels // ignore: cast_nullable_to_non_nullable
as Set<TxChannel>,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TransactionFilter].
extension TransactionFilterPatterns on TransactionFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionFilter value)  $default,){
final _that = this;
switch (_that) {
case _TransactionFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionFilter value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PeriodPreset period,  DateTime? from,  DateTime? to,  Set<TxKind> kinds,  Set<String> banks,  Set<TxChannel> channels,  String? categoryId,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionFilter() when $default != null:
return $default(_that.period,_that.from,_that.to,_that.kinds,_that.banks,_that.channels,_that.categoryId,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PeriodPreset period,  DateTime? from,  DateTime? to,  Set<TxKind> kinds,  Set<String> banks,  Set<TxChannel> channels,  String? categoryId,  String text)  $default,) {final _that = this;
switch (_that) {
case _TransactionFilter():
return $default(_that.period,_that.from,_that.to,_that.kinds,_that.banks,_that.channels,_that.categoryId,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PeriodPreset period,  DateTime? from,  DateTime? to,  Set<TxKind> kinds,  Set<String> banks,  Set<TxChannel> channels,  String? categoryId,  String text)?  $default,) {final _that = this;
switch (_that) {
case _TransactionFilter() when $default != null:
return $default(_that.period,_that.from,_that.to,_that.kinds,_that.banks,_that.channels,_that.categoryId,_that.text);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionFilter extends TransactionFilter {
  const _TransactionFilter({this.period = PeriodPreset.thisMonth, this.from, this.to, final  Set<TxKind> kinds = const <TxKind>{}, final  Set<String> banks = const <String>{}, final  Set<TxChannel> channels = const <TxChannel>{}, this.categoryId, this.text = ''}): _kinds = kinds,_banks = banks,_channels = channels,super._();
  

@override@JsonKey() final  PeriodPreset period;
@override final  DateTime? from;
@override final  DateTime? to;
 final  Set<TxKind> _kinds;
@override@JsonKey() Set<TxKind> get kinds {
  if (_kinds is EqualUnmodifiableSetView) return _kinds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_kinds);
}

 final  Set<String> _banks;
@override@JsonKey() Set<String> get banks {
  if (_banks is EqualUnmodifiableSetView) return _banks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_banks);
}

 final  Set<TxChannel> _channels;
@override@JsonKey() Set<TxChannel> get channels {
  if (_channels is EqualUnmodifiableSetView) return _channels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_channels);
}

@override final  String? categoryId;
@override@JsonKey() final  String text;

/// Create a copy of TransactionFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionFilterCopyWith<_TransactionFilter> get copyWith => __$TransactionFilterCopyWithImpl<_TransactionFilter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionFilter&&(identical(other.period, period) || other.period == period)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&const DeepCollectionEquality().equals(other._kinds, _kinds)&&const DeepCollectionEquality().equals(other._banks, _banks)&&const DeepCollectionEquality().equals(other._channels, _channels)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,period,from,to,const DeepCollectionEquality().hash(_kinds),const DeepCollectionEquality().hash(_banks),const DeepCollectionEquality().hash(_channels),categoryId,text);

@override
String toString() {
  return 'TransactionFilter(period: $period, from: $from, to: $to, kinds: $kinds, banks: $banks, channels: $channels, categoryId: $categoryId, text: $text)';
}


}

/// @nodoc
abstract mixin class _$TransactionFilterCopyWith<$Res> implements $TransactionFilterCopyWith<$Res> {
  factory _$TransactionFilterCopyWith(_TransactionFilter value, $Res Function(_TransactionFilter) _then) = __$TransactionFilterCopyWithImpl;
@override @useResult
$Res call({
 PeriodPreset period, DateTime? from, DateTime? to, Set<TxKind> kinds, Set<String> banks, Set<TxChannel> channels, String? categoryId, String text
});




}
/// @nodoc
class __$TransactionFilterCopyWithImpl<$Res>
    implements _$TransactionFilterCopyWith<$Res> {
  __$TransactionFilterCopyWithImpl(this._self, this._then);

  final _TransactionFilter _self;
  final $Res Function(_TransactionFilter) _then;

/// Create a copy of TransactionFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? period = null,Object? from = freezed,Object? to = freezed,Object? kinds = null,Object? banks = null,Object? channels = null,Object? categoryId = freezed,Object? text = null,}) {
  return _then(_TransactionFilter(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as PeriodPreset,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as DateTime?,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as DateTime?,kinds: null == kinds ? _self._kinds : kinds // ignore: cast_nullable_to_non_nullable
as Set<TxKind>,banks: null == banks ? _self._banks : banks // ignore: cast_nullable_to_non_nullable
as Set<String>,channels: null == channels ? _self._channels : channels // ignore: cast_nullable_to_non_nullable
as Set<TxChannel>,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
