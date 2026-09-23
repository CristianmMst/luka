// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'synced_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SyncedTransaction {

 String get id; Cop get amount; String get currency; TxDirection get direction; TxKind get kind; DateTime get occurredAt; String get categoryId; String get fiscalTag; bool get transferAuto; String get parsedBy; DateTime get createdAt; DateTime get updatedAt; String? get merchant; String? get description; String? get bank; String? get accountId; String? get transferPairId; double? get confidence; String? get notes; List<String> get channels;
/// Create a copy of SyncedTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncedTransactionCopyWith<SyncedTransaction> get copyWith => _$SyncedTransactionCopyWithImpl<SyncedTransaction>(this as SyncedTransaction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncedTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.fiscalTag, fiscalTag) || other.fiscalTag == fiscalTag)&&(identical(other.transferAuto, transferAuto) || other.transferAuto == transferAuto)&&(identical(other.parsedBy, parsedBy) || other.parsedBy == parsedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.description, description) || other.description == description)&&(identical(other.bank, bank) || other.bank == bank)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.transferPairId, transferPairId) || other.transferPairId == transferPairId)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other.channels, channels));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,amount,currency,direction,kind,occurredAt,categoryId,fiscalTag,transferAuto,parsedBy,createdAt,updatedAt,merchant,description,bank,accountId,transferPairId,confidence,notes,const DeepCollectionEquality().hash(channels)]);

@override
String toString() {
  return 'SyncedTransaction(id: $id, amount: $amount, currency: $currency, direction: $direction, kind: $kind, occurredAt: $occurredAt, categoryId: $categoryId, fiscalTag: $fiscalTag, transferAuto: $transferAuto, parsedBy: $parsedBy, createdAt: $createdAt, updatedAt: $updatedAt, merchant: $merchant, description: $description, bank: $bank, accountId: $accountId, transferPairId: $transferPairId, confidence: $confidence, notes: $notes, channels: $channels)';
}


}

/// @nodoc
abstract mixin class $SyncedTransactionCopyWith<$Res>  {
  factory $SyncedTransactionCopyWith(SyncedTransaction value, $Res Function(SyncedTransaction) _then) = _$SyncedTransactionCopyWithImpl;
@useResult
$Res call({
 String id, Cop amount, String currency, TxDirection direction, TxKind kind, DateTime occurredAt, String categoryId, String fiscalTag, bool transferAuto, String parsedBy, DateTime createdAt, DateTime updatedAt, String? merchant, String? description, String? bank, String? accountId, String? transferPairId, double? confidence, String? notes, List<String> channels
});




}
/// @nodoc
class _$SyncedTransactionCopyWithImpl<$Res>
    implements $SyncedTransactionCopyWith<$Res> {
  _$SyncedTransactionCopyWithImpl(this._self, this._then);

  final SyncedTransaction _self;
  final $Res Function(SyncedTransaction) _then;

/// Create a copy of SyncedTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? amount = null,Object? currency = null,Object? direction = null,Object? kind = null,Object? occurredAt = null,Object? categoryId = null,Object? fiscalTag = null,Object? transferAuto = null,Object? parsedBy = null,Object? createdAt = null,Object? updatedAt = null,Object? merchant = freezed,Object? description = freezed,Object? bank = freezed,Object? accountId = freezed,Object? transferPairId = freezed,Object? confidence = freezed,Object? notes = freezed,Object? channels = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Cop,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as TxDirection,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TxKind,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,fiscalTag: null == fiscalTag ? _self.fiscalTag : fiscalTag // ignore: cast_nullable_to_non_nullable
as String,transferAuto: null == transferAuto ? _self.transferAuto : transferAuto // ignore: cast_nullable_to_non_nullable
as bool,parsedBy: null == parsedBy ? _self.parsedBy : parsedBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,bank: freezed == bank ? _self.bank : bank // ignore: cast_nullable_to_non_nullable
as String?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,transferPairId: freezed == transferPairId ? _self.transferPairId : transferPairId // ignore: cast_nullable_to_non_nullable
as String?,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,channels: null == channels ? _self.channels : channels // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncedTransaction].
extension SyncedTransactionPatterns on SyncedTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncedTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncedTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncedTransaction value)  $default,){
final _that = this;
switch (_that) {
case _SyncedTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncedTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _SyncedTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  Cop amount,  String currency,  TxDirection direction,  TxKind kind,  DateTime occurredAt,  String categoryId,  String fiscalTag,  bool transferAuto,  String parsedBy,  DateTime createdAt,  DateTime updatedAt,  String? merchant,  String? description,  String? bank,  String? accountId,  String? transferPairId,  double? confidence,  String? notes,  List<String> channels)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncedTransaction() when $default != null:
return $default(_that.id,_that.amount,_that.currency,_that.direction,_that.kind,_that.occurredAt,_that.categoryId,_that.fiscalTag,_that.transferAuto,_that.parsedBy,_that.createdAt,_that.updatedAt,_that.merchant,_that.description,_that.bank,_that.accountId,_that.transferPairId,_that.confidence,_that.notes,_that.channels);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  Cop amount,  String currency,  TxDirection direction,  TxKind kind,  DateTime occurredAt,  String categoryId,  String fiscalTag,  bool transferAuto,  String parsedBy,  DateTime createdAt,  DateTime updatedAt,  String? merchant,  String? description,  String? bank,  String? accountId,  String? transferPairId,  double? confidence,  String? notes,  List<String> channels)  $default,) {final _that = this;
switch (_that) {
case _SyncedTransaction():
return $default(_that.id,_that.amount,_that.currency,_that.direction,_that.kind,_that.occurredAt,_that.categoryId,_that.fiscalTag,_that.transferAuto,_that.parsedBy,_that.createdAt,_that.updatedAt,_that.merchant,_that.description,_that.bank,_that.accountId,_that.transferPairId,_that.confidence,_that.notes,_that.channels);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  Cop amount,  String currency,  TxDirection direction,  TxKind kind,  DateTime occurredAt,  String categoryId,  String fiscalTag,  bool transferAuto,  String parsedBy,  DateTime createdAt,  DateTime updatedAt,  String? merchant,  String? description,  String? bank,  String? accountId,  String? transferPairId,  double? confidence,  String? notes,  List<String> channels)?  $default,) {final _that = this;
switch (_that) {
case _SyncedTransaction() when $default != null:
return $default(_that.id,_that.amount,_that.currency,_that.direction,_that.kind,_that.occurredAt,_that.categoryId,_that.fiscalTag,_that.transferAuto,_that.parsedBy,_that.createdAt,_that.updatedAt,_that.merchant,_that.description,_that.bank,_that.accountId,_that.transferPairId,_that.confidence,_that.notes,_that.channels);case _:
  return null;

}
}

}

/// @nodoc


class _SyncedTransaction implements SyncedTransaction {
  const _SyncedTransaction({required this.id, required this.amount, required this.currency, required this.direction, required this.kind, required this.occurredAt, required this.categoryId, required this.fiscalTag, required this.transferAuto, required this.parsedBy, required this.createdAt, required this.updatedAt, this.merchant, this.description, this.bank, this.accountId, this.transferPairId, this.confidence, this.notes, final  List<String> channels = const <String>[]}): _channels = channels;
  

@override final  String id;
@override final  Cop amount;
@override final  String currency;
@override final  TxDirection direction;
@override final  TxKind kind;
@override final  DateTime occurredAt;
@override final  String categoryId;
@override final  String fiscalTag;
@override final  bool transferAuto;
@override final  String parsedBy;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String? merchant;
@override final  String? description;
@override final  String? bank;
@override final  String? accountId;
@override final  String? transferPairId;
@override final  double? confidence;
@override final  String? notes;
 final  List<String> _channels;
@override@JsonKey() List<String> get channels {
  if (_channels is EqualUnmodifiableListView) return _channels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_channels);
}


/// Create a copy of SyncedTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncedTransactionCopyWith<_SyncedTransaction> get copyWith => __$SyncedTransactionCopyWithImpl<_SyncedTransaction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncedTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.fiscalTag, fiscalTag) || other.fiscalTag == fiscalTag)&&(identical(other.transferAuto, transferAuto) || other.transferAuto == transferAuto)&&(identical(other.parsedBy, parsedBy) || other.parsedBy == parsedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.description, description) || other.description == description)&&(identical(other.bank, bank) || other.bank == bank)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.transferPairId, transferPairId) || other.transferPairId == transferPairId)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other._channels, _channels));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,amount,currency,direction,kind,occurredAt,categoryId,fiscalTag,transferAuto,parsedBy,createdAt,updatedAt,merchant,description,bank,accountId,transferPairId,confidence,notes,const DeepCollectionEquality().hash(_channels)]);

@override
String toString() {
  return 'SyncedTransaction(id: $id, amount: $amount, currency: $currency, direction: $direction, kind: $kind, occurredAt: $occurredAt, categoryId: $categoryId, fiscalTag: $fiscalTag, transferAuto: $transferAuto, parsedBy: $parsedBy, createdAt: $createdAt, updatedAt: $updatedAt, merchant: $merchant, description: $description, bank: $bank, accountId: $accountId, transferPairId: $transferPairId, confidence: $confidence, notes: $notes, channels: $channels)';
}


}

/// @nodoc
abstract mixin class _$SyncedTransactionCopyWith<$Res> implements $SyncedTransactionCopyWith<$Res> {
  factory _$SyncedTransactionCopyWith(_SyncedTransaction value, $Res Function(_SyncedTransaction) _then) = __$SyncedTransactionCopyWithImpl;
@override @useResult
$Res call({
 String id, Cop amount, String currency, TxDirection direction, TxKind kind, DateTime occurredAt, String categoryId, String fiscalTag, bool transferAuto, String parsedBy, DateTime createdAt, DateTime updatedAt, String? merchant, String? description, String? bank, String? accountId, String? transferPairId, double? confidence, String? notes, List<String> channels
});




}
/// @nodoc
class __$SyncedTransactionCopyWithImpl<$Res>
    implements _$SyncedTransactionCopyWith<$Res> {
  __$SyncedTransactionCopyWithImpl(this._self, this._then);

  final _SyncedTransaction _self;
  final $Res Function(_SyncedTransaction) _then;

/// Create a copy of SyncedTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? amount = null,Object? currency = null,Object? direction = null,Object? kind = null,Object? occurredAt = null,Object? categoryId = null,Object? fiscalTag = null,Object? transferAuto = null,Object? parsedBy = null,Object? createdAt = null,Object? updatedAt = null,Object? merchant = freezed,Object? description = freezed,Object? bank = freezed,Object? accountId = freezed,Object? transferPairId = freezed,Object? confidence = freezed,Object? notes = freezed,Object? channels = null,}) {
  return _then(_SyncedTransaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Cop,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as TxDirection,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TxKind,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,fiscalTag: null == fiscalTag ? _self.fiscalTag : fiscalTag // ignore: cast_nullable_to_non_nullable
as String,transferAuto: null == transferAuto ? _self.transferAuto : transferAuto // ignore: cast_nullable_to_non_nullable
as bool,parsedBy: null == parsedBy ? _self.parsedBy : parsedBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,bank: freezed == bank ? _self.bank : bank // ignore: cast_nullable_to_non_nullable
as String?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,transferPairId: freezed == transferPairId ? _self.transferPairId : transferPairId // ignore: cast_nullable_to_non_nullable
as String?,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,channels: null == channels ? _self._channels : channels // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$SyncedSource {

 String get channel; DateTime get receivedAt;
/// Create a copy of SyncedSource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncedSourceCopyWith<SyncedSource> get copyWith => _$SyncedSourceCopyWithImpl<SyncedSource>(this as SyncedSource, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncedSource&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt));
}


@override
int get hashCode => Object.hash(runtimeType,channel,receivedAt);

@override
String toString() {
  return 'SyncedSource(channel: $channel, receivedAt: $receivedAt)';
}


}

/// @nodoc
abstract mixin class $SyncedSourceCopyWith<$Res>  {
  factory $SyncedSourceCopyWith(SyncedSource value, $Res Function(SyncedSource) _then) = _$SyncedSourceCopyWithImpl;
@useResult
$Res call({
 String channel, DateTime receivedAt
});




}
/// @nodoc
class _$SyncedSourceCopyWithImpl<$Res>
    implements $SyncedSourceCopyWith<$Res> {
  _$SyncedSourceCopyWithImpl(this._self, this._then);

  final SyncedSource _self;
  final $Res Function(SyncedSource) _then;

/// Create a copy of SyncedSource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? channel = null,Object? receivedAt = null,}) {
  return _then(_self.copyWith(
channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,receivedAt: null == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncedSource].
extension SyncedSourcePatterns on SyncedSource {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncedSource value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncedSource() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncedSource value)  $default,){
final _that = this;
switch (_that) {
case _SyncedSource():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncedSource value)?  $default,){
final _that = this;
switch (_that) {
case _SyncedSource() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String channel,  DateTime receivedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncedSource() when $default != null:
return $default(_that.channel,_that.receivedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String channel,  DateTime receivedAt)  $default,) {final _that = this;
switch (_that) {
case _SyncedSource():
return $default(_that.channel,_that.receivedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String channel,  DateTime receivedAt)?  $default,) {final _that = this;
switch (_that) {
case _SyncedSource() when $default != null:
return $default(_that.channel,_that.receivedAt);case _:
  return null;

}
}

}

/// @nodoc


class _SyncedSource implements SyncedSource {
  const _SyncedSource({required this.channel, required this.receivedAt});
  

@override final  String channel;
@override final  DateTime receivedAt;

/// Create a copy of SyncedSource
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncedSourceCopyWith<_SyncedSource> get copyWith => __$SyncedSourceCopyWithImpl<_SyncedSource>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncedSource&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt));
}


@override
int get hashCode => Object.hash(runtimeType,channel,receivedAt);

@override
String toString() {
  return 'SyncedSource(channel: $channel, receivedAt: $receivedAt)';
}


}

/// @nodoc
abstract mixin class _$SyncedSourceCopyWith<$Res> implements $SyncedSourceCopyWith<$Res> {
  factory _$SyncedSourceCopyWith(_SyncedSource value, $Res Function(_SyncedSource) _then) = __$SyncedSourceCopyWithImpl;
@override @useResult
$Res call({
 String channel, DateTime receivedAt
});




}
/// @nodoc
class __$SyncedSourceCopyWithImpl<$Res>
    implements _$SyncedSourceCopyWith<$Res> {
  __$SyncedSourceCopyWithImpl(this._self, this._then);

  final _SyncedSource _self;
  final $Res Function(_SyncedSource) _then;

/// Create a copy of SyncedSource
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? channel = null,Object? receivedAt = null,}) {
  return _then(_SyncedSource(
channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,receivedAt: null == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$SyncedCategory {

 String get id; String get name; String get fiscalTag; bool get isSystem; String? get userId; String? get slug; String? get icon; String? get color;
/// Create a copy of SyncedCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncedCategoryCopyWith<SyncedCategory> get copyWith => _$SyncedCategoryCopyWithImpl<SyncedCategory>(this as SyncedCategory, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncedCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.fiscalTag, fiscalTag) || other.fiscalTag == fiscalTag)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,fiscalTag,isSystem,userId,slug,icon,color);

@override
String toString() {
  return 'SyncedCategory(id: $id, name: $name, fiscalTag: $fiscalTag, isSystem: $isSystem, userId: $userId, slug: $slug, icon: $icon, color: $color)';
}


}

/// @nodoc
abstract mixin class $SyncedCategoryCopyWith<$Res>  {
  factory $SyncedCategoryCopyWith(SyncedCategory value, $Res Function(SyncedCategory) _then) = _$SyncedCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String fiscalTag, bool isSystem, String? userId, String? slug, String? icon, String? color
});




}
/// @nodoc
class _$SyncedCategoryCopyWithImpl<$Res>
    implements $SyncedCategoryCopyWith<$Res> {
  _$SyncedCategoryCopyWithImpl(this._self, this._then);

  final SyncedCategory _self;
  final $Res Function(SyncedCategory) _then;

/// Create a copy of SyncedCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? fiscalTag = null,Object? isSystem = null,Object? userId = freezed,Object? slug = freezed,Object? icon = freezed,Object? color = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fiscalTag: null == fiscalTag ? _self.fiscalTag : fiscalTag // ignore: cast_nullable_to_non_nullable
as String,isSystem: null == isSystem ? _self.isSystem : isSystem // ignore: cast_nullable_to_non_nullable
as bool,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncedCategory].
extension SyncedCategoryPatterns on SyncedCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncedCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncedCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncedCategory value)  $default,){
final _that = this;
switch (_that) {
case _SyncedCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncedCategory value)?  $default,){
final _that = this;
switch (_that) {
case _SyncedCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String fiscalTag,  bool isSystem,  String? userId,  String? slug,  String? icon,  String? color)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncedCategory() when $default != null:
return $default(_that.id,_that.name,_that.fiscalTag,_that.isSystem,_that.userId,_that.slug,_that.icon,_that.color);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String fiscalTag,  bool isSystem,  String? userId,  String? slug,  String? icon,  String? color)  $default,) {final _that = this;
switch (_that) {
case _SyncedCategory():
return $default(_that.id,_that.name,_that.fiscalTag,_that.isSystem,_that.userId,_that.slug,_that.icon,_that.color);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String fiscalTag,  bool isSystem,  String? userId,  String? slug,  String? icon,  String? color)?  $default,) {final _that = this;
switch (_that) {
case _SyncedCategory() when $default != null:
return $default(_that.id,_that.name,_that.fiscalTag,_that.isSystem,_that.userId,_that.slug,_that.icon,_that.color);case _:
  return null;

}
}

}

/// @nodoc


class _SyncedCategory implements SyncedCategory {
  const _SyncedCategory({required this.id, required this.name, required this.fiscalTag, required this.isSystem, this.userId, this.slug, this.icon, this.color});
  

@override final  String id;
@override final  String name;
@override final  String fiscalTag;
@override final  bool isSystem;
@override final  String? userId;
@override final  String? slug;
@override final  String? icon;
@override final  String? color;

/// Create a copy of SyncedCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncedCategoryCopyWith<_SyncedCategory> get copyWith => __$SyncedCategoryCopyWithImpl<_SyncedCategory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncedCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.fiscalTag, fiscalTag) || other.fiscalTag == fiscalTag)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,fiscalTag,isSystem,userId,slug,icon,color);

@override
String toString() {
  return 'SyncedCategory(id: $id, name: $name, fiscalTag: $fiscalTag, isSystem: $isSystem, userId: $userId, slug: $slug, icon: $icon, color: $color)';
}


}

/// @nodoc
abstract mixin class _$SyncedCategoryCopyWith<$Res> implements $SyncedCategoryCopyWith<$Res> {
  factory _$SyncedCategoryCopyWith(_SyncedCategory value, $Res Function(_SyncedCategory) _then) = __$SyncedCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String fiscalTag, bool isSystem, String? userId, String? slug, String? icon, String? color
});




}
/// @nodoc
class __$SyncedCategoryCopyWithImpl<$Res>
    implements _$SyncedCategoryCopyWith<$Res> {
  __$SyncedCategoryCopyWithImpl(this._self, this._then);

  final _SyncedCategory _self;
  final $Res Function(_SyncedCategory) _then;

/// Create a copy of SyncedCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? fiscalTag = null,Object? isSystem = null,Object? userId = freezed,Object? slug = freezed,Object? icon = freezed,Object? color = freezed,}) {
  return _then(_SyncedCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fiscalTag: null == fiscalTag ? _self.fiscalTag : fiscalTag // ignore: cast_nullable_to_non_nullable
as String,isSystem: null == isSystem ? _self.isSystem : isSystem // ignore: cast_nullable_to_non_nullable
as bool,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$SyncedAccount {

 String get id; String get bank; String get kind; String? get last4; String? get alias;
/// Create a copy of SyncedAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncedAccountCopyWith<SyncedAccount> get copyWith => _$SyncedAccountCopyWithImpl<SyncedAccount>(this as SyncedAccount, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncedAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.bank, bank) || other.bank == bank)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.last4, last4) || other.last4 == last4)&&(identical(other.alias, alias) || other.alias == alias));
}


@override
int get hashCode => Object.hash(runtimeType,id,bank,kind,last4,alias);

@override
String toString() {
  return 'SyncedAccount(id: $id, bank: $bank, kind: $kind, last4: $last4, alias: $alias)';
}


}

/// @nodoc
abstract mixin class $SyncedAccountCopyWith<$Res>  {
  factory $SyncedAccountCopyWith(SyncedAccount value, $Res Function(SyncedAccount) _then) = _$SyncedAccountCopyWithImpl;
@useResult
$Res call({
 String id, String bank, String kind, String? last4, String? alias
});




}
/// @nodoc
class _$SyncedAccountCopyWithImpl<$Res>
    implements $SyncedAccountCopyWith<$Res> {
  _$SyncedAccountCopyWithImpl(this._self, this._then);

  final SyncedAccount _self;
  final $Res Function(SyncedAccount) _then;

/// Create a copy of SyncedAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? bank = null,Object? kind = null,Object? last4 = freezed,Object? alias = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bank: null == bank ? _self.bank : bank // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,last4: freezed == last4 ? _self.last4 : last4 // ignore: cast_nullable_to_non_nullable
as String?,alias: freezed == alias ? _self.alias : alias // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncedAccount].
extension SyncedAccountPatterns on SyncedAccount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncedAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncedAccount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncedAccount value)  $default,){
final _that = this;
switch (_that) {
case _SyncedAccount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncedAccount value)?  $default,){
final _that = this;
switch (_that) {
case _SyncedAccount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String bank,  String kind,  String? last4,  String? alias)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncedAccount() when $default != null:
return $default(_that.id,_that.bank,_that.kind,_that.last4,_that.alias);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String bank,  String kind,  String? last4,  String? alias)  $default,) {final _that = this;
switch (_that) {
case _SyncedAccount():
return $default(_that.id,_that.bank,_that.kind,_that.last4,_that.alias);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String bank,  String kind,  String? last4,  String? alias)?  $default,) {final _that = this;
switch (_that) {
case _SyncedAccount() when $default != null:
return $default(_that.id,_that.bank,_that.kind,_that.last4,_that.alias);case _:
  return null;

}
}

}

/// @nodoc


class _SyncedAccount implements SyncedAccount {
  const _SyncedAccount({required this.id, required this.bank, required this.kind, this.last4, this.alias});
  

@override final  String id;
@override final  String bank;
@override final  String kind;
@override final  String? last4;
@override final  String? alias;

/// Create a copy of SyncedAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncedAccountCopyWith<_SyncedAccount> get copyWith => __$SyncedAccountCopyWithImpl<_SyncedAccount>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncedAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.bank, bank) || other.bank == bank)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.last4, last4) || other.last4 == last4)&&(identical(other.alias, alias) || other.alias == alias));
}


@override
int get hashCode => Object.hash(runtimeType,id,bank,kind,last4,alias);

@override
String toString() {
  return 'SyncedAccount(id: $id, bank: $bank, kind: $kind, last4: $last4, alias: $alias)';
}


}

/// @nodoc
abstract mixin class _$SyncedAccountCopyWith<$Res> implements $SyncedAccountCopyWith<$Res> {
  factory _$SyncedAccountCopyWith(_SyncedAccount value, $Res Function(_SyncedAccount) _then) = __$SyncedAccountCopyWithImpl;
@override @useResult
$Res call({
 String id, String bank, String kind, String? last4, String? alias
});




}
/// @nodoc
class __$SyncedAccountCopyWithImpl<$Res>
    implements _$SyncedAccountCopyWith<$Res> {
  __$SyncedAccountCopyWithImpl(this._self, this._then);

  final _SyncedAccount _self;
  final $Res Function(_SyncedAccount) _then;

/// Create a copy of SyncedAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? bank = null,Object? kind = null,Object? last4 = freezed,Object? alias = freezed,}) {
  return _then(_SyncedAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bank: null == bank ? _self.bank : bank // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,last4: freezed == last4 ? _self.last4 : last4 // ignore: cast_nullable_to_non_nullable
as String?,alias: freezed == alias ? _self.alias : alias // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$SyncedReviewItem {

 String get rawMessageId; String get channel; String get sender; DateTime get receivedAt; String get reason; Map<String, String> get partialExtract; DateTime get createdAt; String? get bank; String? get text;
/// Create a copy of SyncedReviewItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncedReviewItemCopyWith<SyncedReviewItem> get copyWith => _$SyncedReviewItemCopyWithImpl<SyncedReviewItem>(this as SyncedReviewItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncedReviewItem&&(identical(other.rawMessageId, rawMessageId) || other.rawMessageId == rawMessageId)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt)&&(identical(other.reason, reason) || other.reason == reason)&&const DeepCollectionEquality().equals(other.partialExtract, partialExtract)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.bank, bank) || other.bank == bank)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,rawMessageId,channel,sender,receivedAt,reason,const DeepCollectionEquality().hash(partialExtract),createdAt,bank,text);

@override
String toString() {
  return 'SyncedReviewItem(rawMessageId: $rawMessageId, channel: $channel, sender: $sender, receivedAt: $receivedAt, reason: $reason, partialExtract: $partialExtract, createdAt: $createdAt, bank: $bank, text: $text)';
}


}

/// @nodoc
abstract mixin class $SyncedReviewItemCopyWith<$Res>  {
  factory $SyncedReviewItemCopyWith(SyncedReviewItem value, $Res Function(SyncedReviewItem) _then) = _$SyncedReviewItemCopyWithImpl;
@useResult
$Res call({
 String rawMessageId, String channel, String sender, DateTime receivedAt, String reason, Map<String, String> partialExtract, DateTime createdAt, String? bank, String? text
});




}
/// @nodoc
class _$SyncedReviewItemCopyWithImpl<$Res>
    implements $SyncedReviewItemCopyWith<$Res> {
  _$SyncedReviewItemCopyWithImpl(this._self, this._then);

  final SyncedReviewItem _self;
  final $Res Function(SyncedReviewItem) _then;

/// Create a copy of SyncedReviewItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rawMessageId = null,Object? channel = null,Object? sender = null,Object? receivedAt = null,Object? reason = null,Object? partialExtract = null,Object? createdAt = null,Object? bank = freezed,Object? text = freezed,}) {
  return _then(_self.copyWith(
rawMessageId: null == rawMessageId ? _self.rawMessageId : rawMessageId // ignore: cast_nullable_to_non_nullable
as String,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,sender: null == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as String,receivedAt: null == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,partialExtract: null == partialExtract ? _self.partialExtract : partialExtract // ignore: cast_nullable_to_non_nullable
as Map<String, String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,bank: freezed == bank ? _self.bank : bank // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncedReviewItem].
extension SyncedReviewItemPatterns on SyncedReviewItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncedReviewItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncedReviewItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncedReviewItem value)  $default,){
final _that = this;
switch (_that) {
case _SyncedReviewItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncedReviewItem value)?  $default,){
final _that = this;
switch (_that) {
case _SyncedReviewItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String rawMessageId,  String channel,  String sender,  DateTime receivedAt,  String reason,  Map<String, String> partialExtract,  DateTime createdAt,  String? bank,  String? text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncedReviewItem() when $default != null:
return $default(_that.rawMessageId,_that.channel,_that.sender,_that.receivedAt,_that.reason,_that.partialExtract,_that.createdAt,_that.bank,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String rawMessageId,  String channel,  String sender,  DateTime receivedAt,  String reason,  Map<String, String> partialExtract,  DateTime createdAt,  String? bank,  String? text)  $default,) {final _that = this;
switch (_that) {
case _SyncedReviewItem():
return $default(_that.rawMessageId,_that.channel,_that.sender,_that.receivedAt,_that.reason,_that.partialExtract,_that.createdAt,_that.bank,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String rawMessageId,  String channel,  String sender,  DateTime receivedAt,  String reason,  Map<String, String> partialExtract,  DateTime createdAt,  String? bank,  String? text)?  $default,) {final _that = this;
switch (_that) {
case _SyncedReviewItem() when $default != null:
return $default(_that.rawMessageId,_that.channel,_that.sender,_that.receivedAt,_that.reason,_that.partialExtract,_that.createdAt,_that.bank,_that.text);case _:
  return null;

}
}

}

/// @nodoc


class _SyncedReviewItem implements SyncedReviewItem {
  const _SyncedReviewItem({required this.rawMessageId, required this.channel, required this.sender, required this.receivedAt, required this.reason, required final  Map<String, String> partialExtract, required this.createdAt, this.bank, this.text}): _partialExtract = partialExtract;
  

@override final  String rawMessageId;
@override final  String channel;
@override final  String sender;
@override final  DateTime receivedAt;
@override final  String reason;
 final  Map<String, String> _partialExtract;
@override Map<String, String> get partialExtract {
  if (_partialExtract is EqualUnmodifiableMapView) return _partialExtract;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_partialExtract);
}

@override final  DateTime createdAt;
@override final  String? bank;
@override final  String? text;

/// Create a copy of SyncedReviewItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncedReviewItemCopyWith<_SyncedReviewItem> get copyWith => __$SyncedReviewItemCopyWithImpl<_SyncedReviewItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncedReviewItem&&(identical(other.rawMessageId, rawMessageId) || other.rawMessageId == rawMessageId)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt)&&(identical(other.reason, reason) || other.reason == reason)&&const DeepCollectionEquality().equals(other._partialExtract, _partialExtract)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.bank, bank) || other.bank == bank)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,rawMessageId,channel,sender,receivedAt,reason,const DeepCollectionEquality().hash(_partialExtract),createdAt,bank,text);

@override
String toString() {
  return 'SyncedReviewItem(rawMessageId: $rawMessageId, channel: $channel, sender: $sender, receivedAt: $receivedAt, reason: $reason, partialExtract: $partialExtract, createdAt: $createdAt, bank: $bank, text: $text)';
}


}

/// @nodoc
abstract mixin class _$SyncedReviewItemCopyWith<$Res> implements $SyncedReviewItemCopyWith<$Res> {
  factory _$SyncedReviewItemCopyWith(_SyncedReviewItem value, $Res Function(_SyncedReviewItem) _then) = __$SyncedReviewItemCopyWithImpl;
@override @useResult
$Res call({
 String rawMessageId, String channel, String sender, DateTime receivedAt, String reason, Map<String, String> partialExtract, DateTime createdAt, String? bank, String? text
});




}
/// @nodoc
class __$SyncedReviewItemCopyWithImpl<$Res>
    implements _$SyncedReviewItemCopyWith<$Res> {
  __$SyncedReviewItemCopyWithImpl(this._self, this._then);

  final _SyncedReviewItem _self;
  final $Res Function(_SyncedReviewItem) _then;

/// Create a copy of SyncedReviewItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rawMessageId = null,Object? channel = null,Object? sender = null,Object? receivedAt = null,Object? reason = null,Object? partialExtract = null,Object? createdAt = null,Object? bank = freezed,Object? text = freezed,}) {
  return _then(_SyncedReviewItem(
rawMessageId: null == rawMessageId ? _self.rawMessageId : rawMessageId // ignore: cast_nullable_to_non_nullable
as String,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,sender: null == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as String,receivedAt: null == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,partialExtract: null == partialExtract ? _self._partialExtract : partialExtract // ignore: cast_nullable_to_non_nullable
as Map<String, String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,bank: freezed == bank ? _self.bank : bank // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
