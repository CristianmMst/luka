// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'review_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReviewItem {

 String get rawMessageId;/// `email` o `notification`.
 String get channel; String get sender; DateTime get receivedAt;/// Motivo del fallo (`no_template`, `llm_low_confidence`, …).
 String get reason;/// Lo que sí se extrajo (`amount`, `direction`, `occurred_at`,
/// `merchant`); vacío salvo en fallos del LLM.
 Map<String, String> get partialExtract; String? get bank;/// Cuerpo crudo; `null` si ya se purgó.
 String? get text;
/// Create a copy of ReviewItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewItemCopyWith<ReviewItem> get copyWith => _$ReviewItemCopyWithImpl<ReviewItem>(this as ReviewItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewItem&&(identical(other.rawMessageId, rawMessageId) || other.rawMessageId == rawMessageId)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt)&&(identical(other.reason, reason) || other.reason == reason)&&const DeepCollectionEquality().equals(other.partialExtract, partialExtract)&&(identical(other.bank, bank) || other.bank == bank)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,rawMessageId,channel,sender,receivedAt,reason,const DeepCollectionEquality().hash(partialExtract),bank,text);

@override
String toString() {
  return 'ReviewItem(rawMessageId: $rawMessageId, channel: $channel, sender: $sender, receivedAt: $receivedAt, reason: $reason, partialExtract: $partialExtract, bank: $bank, text: $text)';
}


}

/// @nodoc
abstract mixin class $ReviewItemCopyWith<$Res>  {
  factory $ReviewItemCopyWith(ReviewItem value, $Res Function(ReviewItem) _then) = _$ReviewItemCopyWithImpl;
@useResult
$Res call({
 String rawMessageId, String channel, String sender, DateTime receivedAt, String reason, Map<String, String> partialExtract, String? bank, String? text
});




}
/// @nodoc
class _$ReviewItemCopyWithImpl<$Res>
    implements $ReviewItemCopyWith<$Res> {
  _$ReviewItemCopyWithImpl(this._self, this._then);

  final ReviewItem _self;
  final $Res Function(ReviewItem) _then;

/// Create a copy of ReviewItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rawMessageId = null,Object? channel = null,Object? sender = null,Object? receivedAt = null,Object? reason = null,Object? partialExtract = null,Object? bank = freezed,Object? text = freezed,}) {
  return _then(_self.copyWith(
rawMessageId: null == rawMessageId ? _self.rawMessageId : rawMessageId // ignore: cast_nullable_to_non_nullable
as String,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,sender: null == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as String,receivedAt: null == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,partialExtract: null == partialExtract ? _self.partialExtract : partialExtract // ignore: cast_nullable_to_non_nullable
as Map<String, String>,bank: freezed == bank ? _self.bank : bank // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReviewItem].
extension ReviewItemPatterns on ReviewItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReviewItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReviewItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReviewItem value)  $default,){
final _that = this;
switch (_that) {
case _ReviewItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReviewItem value)?  $default,){
final _that = this;
switch (_that) {
case _ReviewItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String rawMessageId,  String channel,  String sender,  DateTime receivedAt,  String reason,  Map<String, String> partialExtract,  String? bank,  String? text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReviewItem() when $default != null:
return $default(_that.rawMessageId,_that.channel,_that.sender,_that.receivedAt,_that.reason,_that.partialExtract,_that.bank,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String rawMessageId,  String channel,  String sender,  DateTime receivedAt,  String reason,  Map<String, String> partialExtract,  String? bank,  String? text)  $default,) {final _that = this;
switch (_that) {
case _ReviewItem():
return $default(_that.rawMessageId,_that.channel,_that.sender,_that.receivedAt,_that.reason,_that.partialExtract,_that.bank,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String rawMessageId,  String channel,  String sender,  DateTime receivedAt,  String reason,  Map<String, String> partialExtract,  String? bank,  String? text)?  $default,) {final _that = this;
switch (_that) {
case _ReviewItem() when $default != null:
return $default(_that.rawMessageId,_that.channel,_that.sender,_that.receivedAt,_that.reason,_that.partialExtract,_that.bank,_that.text);case _:
  return null;

}
}

}

/// @nodoc


class _ReviewItem implements ReviewItem {
  const _ReviewItem({required this.rawMessageId, required this.channel, required this.sender, required this.receivedAt, required this.reason, required final  Map<String, String> partialExtract, this.bank, this.text}): _partialExtract = partialExtract;
  

@override final  String rawMessageId;
/// `email` o `notification`.
@override final  String channel;
@override final  String sender;
@override final  DateTime receivedAt;
/// Motivo del fallo (`no_template`, `llm_low_confidence`, …).
@override final  String reason;
/// Lo que sí se extrajo (`amount`, `direction`, `occurred_at`,
/// `merchant`); vacío salvo en fallos del LLM.
 final  Map<String, String> _partialExtract;
/// Lo que sí se extrajo (`amount`, `direction`, `occurred_at`,
/// `merchant`); vacío salvo en fallos del LLM.
@override Map<String, String> get partialExtract {
  if (_partialExtract is EqualUnmodifiableMapView) return _partialExtract;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_partialExtract);
}

@override final  String? bank;
/// Cuerpo crudo; `null` si ya se purgó.
@override final  String? text;

/// Create a copy of ReviewItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewItemCopyWith<_ReviewItem> get copyWith => __$ReviewItemCopyWithImpl<_ReviewItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewItem&&(identical(other.rawMessageId, rawMessageId) || other.rawMessageId == rawMessageId)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt)&&(identical(other.reason, reason) || other.reason == reason)&&const DeepCollectionEquality().equals(other._partialExtract, _partialExtract)&&(identical(other.bank, bank) || other.bank == bank)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,rawMessageId,channel,sender,receivedAt,reason,const DeepCollectionEquality().hash(_partialExtract),bank,text);

@override
String toString() {
  return 'ReviewItem(rawMessageId: $rawMessageId, channel: $channel, sender: $sender, receivedAt: $receivedAt, reason: $reason, partialExtract: $partialExtract, bank: $bank, text: $text)';
}


}

/// @nodoc
abstract mixin class _$ReviewItemCopyWith<$Res> implements $ReviewItemCopyWith<$Res> {
  factory _$ReviewItemCopyWith(_ReviewItem value, $Res Function(_ReviewItem) _then) = __$ReviewItemCopyWithImpl;
@override @useResult
$Res call({
 String rawMessageId, String channel, String sender, DateTime receivedAt, String reason, Map<String, String> partialExtract, String? bank, String? text
});




}
/// @nodoc
class __$ReviewItemCopyWithImpl<$Res>
    implements _$ReviewItemCopyWith<$Res> {
  __$ReviewItemCopyWithImpl(this._self, this._then);

  final _ReviewItem _self;
  final $Res Function(_ReviewItem) _then;

/// Create a copy of ReviewItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rawMessageId = null,Object? channel = null,Object? sender = null,Object? receivedAt = null,Object? reason = null,Object? partialExtract = null,Object? bank = freezed,Object? text = freezed,}) {
  return _then(_ReviewItem(
rawMessageId: null == rawMessageId ? _self.rawMessageId : rawMessageId // ignore: cast_nullable_to_non_nullable
as String,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,sender: null == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as String,receivedAt: null == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,partialExtract: null == partialExtract ? _self._partialExtract : partialExtract // ignore: cast_nullable_to_non_nullable
as Map<String, String>,bank: freezed == bank ? _self.bank : bank // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
