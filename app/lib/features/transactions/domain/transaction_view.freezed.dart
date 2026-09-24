// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_view.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransactionView {

 String get id; Cop get amount; TxDirection get direction; TxKind get kind; DateTime get occurredAt; Set<TxChannel> get channels; SyncMark get sync; String? get merchant; String? get categoryId; String? get categoryName; String? get categorySlug; String? get bank;/// Cuenta vinculada, en crudo (`Bank`/`AccountKind` del cable, spec 004
/// §2.4); presentation arma la etiqueta con l10n. Sin cuenta, todas
/// son `null`.
 String? get accountBank; String? get accountKind; String? get accountLast4; String? get accountAlias; String? get notes; String? get transferPairId; String? get parsedBy;
/// Create a copy of TransactionView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionViewCopyWith<TransactionView> get copyWith => _$TransactionViewCopyWithImpl<TransactionView>(this as TransactionView, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionView&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&const DeepCollectionEquality().equals(other.channels, channels)&&(identical(other.sync, sync) || other.sync == sync)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.categorySlug, categorySlug) || other.categorySlug == categorySlug)&&(identical(other.bank, bank) || other.bank == bank)&&(identical(other.accountBank, accountBank) || other.accountBank == accountBank)&&(identical(other.accountKind, accountKind) || other.accountKind == accountKind)&&(identical(other.accountLast4, accountLast4) || other.accountLast4 == accountLast4)&&(identical(other.accountAlias, accountAlias) || other.accountAlias == accountAlias)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.transferPairId, transferPairId) || other.transferPairId == transferPairId)&&(identical(other.parsedBy, parsedBy) || other.parsedBy == parsedBy));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,amount,direction,kind,occurredAt,const DeepCollectionEquality().hash(channels),sync,merchant,categoryId,categoryName,categorySlug,bank,accountBank,accountKind,accountLast4,accountAlias,notes,transferPairId,parsedBy]);

@override
String toString() {
  return 'TransactionView(id: $id, amount: $amount, direction: $direction, kind: $kind, occurredAt: $occurredAt, channels: $channels, sync: $sync, merchant: $merchant, categoryId: $categoryId, categoryName: $categoryName, categorySlug: $categorySlug, bank: $bank, accountBank: $accountBank, accountKind: $accountKind, accountLast4: $accountLast4, accountAlias: $accountAlias, notes: $notes, transferPairId: $transferPairId, parsedBy: $parsedBy)';
}


}

/// @nodoc
abstract mixin class $TransactionViewCopyWith<$Res>  {
  factory $TransactionViewCopyWith(TransactionView value, $Res Function(TransactionView) _then) = _$TransactionViewCopyWithImpl;
@useResult
$Res call({
 String id, Cop amount, TxDirection direction, TxKind kind, DateTime occurredAt, Set<TxChannel> channels, SyncMark sync, String? merchant, String? categoryId, String? categoryName, String? categorySlug, String? bank, String? accountBank, String? accountKind, String? accountLast4, String? accountAlias, String? notes, String? transferPairId, String? parsedBy
});




}
/// @nodoc
class _$TransactionViewCopyWithImpl<$Res>
    implements $TransactionViewCopyWith<$Res> {
  _$TransactionViewCopyWithImpl(this._self, this._then);

  final TransactionView _self;
  final $Res Function(TransactionView) _then;

/// Create a copy of TransactionView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? amount = null,Object? direction = null,Object? kind = null,Object? occurredAt = null,Object? channels = null,Object? sync = null,Object? merchant = freezed,Object? categoryId = freezed,Object? categoryName = freezed,Object? categorySlug = freezed,Object? bank = freezed,Object? accountBank = freezed,Object? accountKind = freezed,Object? accountLast4 = freezed,Object? accountAlias = freezed,Object? notes = freezed,Object? transferPairId = freezed,Object? parsedBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Cop,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as TxDirection,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TxKind,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,channels: null == channels ? _self.channels : channels // ignore: cast_nullable_to_non_nullable
as Set<TxChannel>,sync: null == sync ? _self.sync : sync // ignore: cast_nullable_to_non_nullable
as SyncMark,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,categorySlug: freezed == categorySlug ? _self.categorySlug : categorySlug // ignore: cast_nullable_to_non_nullable
as String?,bank: freezed == bank ? _self.bank : bank // ignore: cast_nullable_to_non_nullable
as String?,accountBank: freezed == accountBank ? _self.accountBank : accountBank // ignore: cast_nullable_to_non_nullable
as String?,accountKind: freezed == accountKind ? _self.accountKind : accountKind // ignore: cast_nullable_to_non_nullable
as String?,accountLast4: freezed == accountLast4 ? _self.accountLast4 : accountLast4 // ignore: cast_nullable_to_non_nullable
as String?,accountAlias: freezed == accountAlias ? _self.accountAlias : accountAlias // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,transferPairId: freezed == transferPairId ? _self.transferPairId : transferPairId // ignore: cast_nullable_to_non_nullable
as String?,parsedBy: freezed == parsedBy ? _self.parsedBy : parsedBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TransactionView].
extension TransactionViewPatterns on TransactionView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionView value)  $default,){
final _that = this;
switch (_that) {
case _TransactionView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionView value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  Cop amount,  TxDirection direction,  TxKind kind,  DateTime occurredAt,  Set<TxChannel> channels,  SyncMark sync,  String? merchant,  String? categoryId,  String? categoryName,  String? categorySlug,  String? bank,  String? accountBank,  String? accountKind,  String? accountLast4,  String? accountAlias,  String? notes,  String? transferPairId,  String? parsedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionView() when $default != null:
return $default(_that.id,_that.amount,_that.direction,_that.kind,_that.occurredAt,_that.channels,_that.sync,_that.merchant,_that.categoryId,_that.categoryName,_that.categorySlug,_that.bank,_that.accountBank,_that.accountKind,_that.accountLast4,_that.accountAlias,_that.notes,_that.transferPairId,_that.parsedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  Cop amount,  TxDirection direction,  TxKind kind,  DateTime occurredAt,  Set<TxChannel> channels,  SyncMark sync,  String? merchant,  String? categoryId,  String? categoryName,  String? categorySlug,  String? bank,  String? accountBank,  String? accountKind,  String? accountLast4,  String? accountAlias,  String? notes,  String? transferPairId,  String? parsedBy)  $default,) {final _that = this;
switch (_that) {
case _TransactionView():
return $default(_that.id,_that.amount,_that.direction,_that.kind,_that.occurredAt,_that.channels,_that.sync,_that.merchant,_that.categoryId,_that.categoryName,_that.categorySlug,_that.bank,_that.accountBank,_that.accountKind,_that.accountLast4,_that.accountAlias,_that.notes,_that.transferPairId,_that.parsedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  Cop amount,  TxDirection direction,  TxKind kind,  DateTime occurredAt,  Set<TxChannel> channels,  SyncMark sync,  String? merchant,  String? categoryId,  String? categoryName,  String? categorySlug,  String? bank,  String? accountBank,  String? accountKind,  String? accountLast4,  String? accountAlias,  String? notes,  String? transferPairId,  String? parsedBy)?  $default,) {final _that = this;
switch (_that) {
case _TransactionView() when $default != null:
return $default(_that.id,_that.amount,_that.direction,_that.kind,_that.occurredAt,_that.channels,_that.sync,_that.merchant,_that.categoryId,_that.categoryName,_that.categorySlug,_that.bank,_that.accountBank,_that.accountKind,_that.accountLast4,_that.accountAlias,_that.notes,_that.transferPairId,_that.parsedBy);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionView implements TransactionView {
  const _TransactionView({required this.id, required this.amount, required this.direction, required this.kind, required this.occurredAt, required final  Set<TxChannel> channels, required this.sync, this.merchant, this.categoryId, this.categoryName, this.categorySlug, this.bank, this.accountBank, this.accountKind, this.accountLast4, this.accountAlias, this.notes, this.transferPairId, this.parsedBy}): _channels = channels;
  

@override final  String id;
@override final  Cop amount;
@override final  TxDirection direction;
@override final  TxKind kind;
@override final  DateTime occurredAt;
 final  Set<TxChannel> _channels;
@override Set<TxChannel> get channels {
  if (_channels is EqualUnmodifiableSetView) return _channels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_channels);
}

@override final  SyncMark sync;
@override final  String? merchant;
@override final  String? categoryId;
@override final  String? categoryName;
@override final  String? categorySlug;
@override final  String? bank;
/// Cuenta vinculada, en crudo (`Bank`/`AccountKind` del cable, spec 004
/// §2.4); presentation arma la etiqueta con l10n. Sin cuenta, todas
/// son `null`.
@override final  String? accountBank;
@override final  String? accountKind;
@override final  String? accountLast4;
@override final  String? accountAlias;
@override final  String? notes;
@override final  String? transferPairId;
@override final  String? parsedBy;

/// Create a copy of TransactionView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionViewCopyWith<_TransactionView> get copyWith => __$TransactionViewCopyWithImpl<_TransactionView>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionView&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&const DeepCollectionEquality().equals(other._channels, _channels)&&(identical(other.sync, sync) || other.sync == sync)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.categorySlug, categorySlug) || other.categorySlug == categorySlug)&&(identical(other.bank, bank) || other.bank == bank)&&(identical(other.accountBank, accountBank) || other.accountBank == accountBank)&&(identical(other.accountKind, accountKind) || other.accountKind == accountKind)&&(identical(other.accountLast4, accountLast4) || other.accountLast4 == accountLast4)&&(identical(other.accountAlias, accountAlias) || other.accountAlias == accountAlias)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.transferPairId, transferPairId) || other.transferPairId == transferPairId)&&(identical(other.parsedBy, parsedBy) || other.parsedBy == parsedBy));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,amount,direction,kind,occurredAt,const DeepCollectionEquality().hash(_channels),sync,merchant,categoryId,categoryName,categorySlug,bank,accountBank,accountKind,accountLast4,accountAlias,notes,transferPairId,parsedBy]);

@override
String toString() {
  return 'TransactionView(id: $id, amount: $amount, direction: $direction, kind: $kind, occurredAt: $occurredAt, channels: $channels, sync: $sync, merchant: $merchant, categoryId: $categoryId, categoryName: $categoryName, categorySlug: $categorySlug, bank: $bank, accountBank: $accountBank, accountKind: $accountKind, accountLast4: $accountLast4, accountAlias: $accountAlias, notes: $notes, transferPairId: $transferPairId, parsedBy: $parsedBy)';
}


}

/// @nodoc
abstract mixin class _$TransactionViewCopyWith<$Res> implements $TransactionViewCopyWith<$Res> {
  factory _$TransactionViewCopyWith(_TransactionView value, $Res Function(_TransactionView) _then) = __$TransactionViewCopyWithImpl;
@override @useResult
$Res call({
 String id, Cop amount, TxDirection direction, TxKind kind, DateTime occurredAt, Set<TxChannel> channels, SyncMark sync, String? merchant, String? categoryId, String? categoryName, String? categorySlug, String? bank, String? accountBank, String? accountKind, String? accountLast4, String? accountAlias, String? notes, String? transferPairId, String? parsedBy
});




}
/// @nodoc
class __$TransactionViewCopyWithImpl<$Res>
    implements _$TransactionViewCopyWith<$Res> {
  __$TransactionViewCopyWithImpl(this._self, this._then);

  final _TransactionView _self;
  final $Res Function(_TransactionView) _then;

/// Create a copy of TransactionView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? amount = null,Object? direction = null,Object? kind = null,Object? occurredAt = null,Object? channels = null,Object? sync = null,Object? merchant = freezed,Object? categoryId = freezed,Object? categoryName = freezed,Object? categorySlug = freezed,Object? bank = freezed,Object? accountBank = freezed,Object? accountKind = freezed,Object? accountLast4 = freezed,Object? accountAlias = freezed,Object? notes = freezed,Object? transferPairId = freezed,Object? parsedBy = freezed,}) {
  return _then(_TransactionView(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Cop,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as TxDirection,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TxKind,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,channels: null == channels ? _self._channels : channels // ignore: cast_nullable_to_non_nullable
as Set<TxChannel>,sync: null == sync ? _self.sync : sync // ignore: cast_nullable_to_non_nullable
as SyncMark,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,categorySlug: freezed == categorySlug ? _self.categorySlug : categorySlug // ignore: cast_nullable_to_non_nullable
as String?,bank: freezed == bank ? _self.bank : bank // ignore: cast_nullable_to_non_nullable
as String?,accountBank: freezed == accountBank ? _self.accountBank : accountBank // ignore: cast_nullable_to_non_nullable
as String?,accountKind: freezed == accountKind ? _self.accountKind : accountKind // ignore: cast_nullable_to_non_nullable
as String?,accountLast4: freezed == accountLast4 ? _self.accountLast4 : accountLast4 // ignore: cast_nullable_to_non_nullable
as String?,accountAlias: freezed == accountAlias ? _self.accountAlias : accountAlias // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,transferPairId: freezed == transferPairId ? _self.transferPairId : transferPairId // ignore: cast_nullable_to_non_nullable
as String?,parsedBy: freezed == parsedBy ? _self.parsedBy : parsedBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
