// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'outbox_operation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NewTransaction {

 Cop get amount; TxDirection get direction; DateTime get occurredAt; TxKind? get kind; String? get categoryId; String? get merchant; String? get description; String? get accountId; String? get notes;
/// Create a copy of NewTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewTransactionCopyWith<NewTransaction> get copyWith => _$NewTransactionCopyWithImpl<NewTransaction>(this as NewTransaction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewTransaction&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.description, description) || other.description == description)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,amount,direction,occurredAt,kind,categoryId,merchant,description,accountId,notes);

@override
String toString() {
  return 'NewTransaction(amount: $amount, direction: $direction, occurredAt: $occurredAt, kind: $kind, categoryId: $categoryId, merchant: $merchant, description: $description, accountId: $accountId, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $NewTransactionCopyWith<$Res>  {
  factory $NewTransactionCopyWith(NewTransaction value, $Res Function(NewTransaction) _then) = _$NewTransactionCopyWithImpl;
@useResult
$Res call({
 Cop amount, TxDirection direction, DateTime occurredAt, TxKind? kind, String? categoryId, String? merchant, String? description, String? accountId, String? notes
});




}
/// @nodoc
class _$NewTransactionCopyWithImpl<$Res>
    implements $NewTransactionCopyWith<$Res> {
  _$NewTransactionCopyWithImpl(this._self, this._then);

  final NewTransaction _self;
  final $Res Function(NewTransaction) _then;

/// Create a copy of NewTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = null,Object? direction = null,Object? occurredAt = null,Object? kind = freezed,Object? categoryId = freezed,Object? merchant = freezed,Object? description = freezed,Object? accountId = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Cop,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as TxDirection,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TxKind?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NewTransaction].
extension NewTransactionPatterns on NewTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewTransaction value)  $default,){
final _that = this;
switch (_that) {
case _NewTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _NewTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Cop amount,  TxDirection direction,  DateTime occurredAt,  TxKind? kind,  String? categoryId,  String? merchant,  String? description,  String? accountId,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewTransaction() when $default != null:
return $default(_that.amount,_that.direction,_that.occurredAt,_that.kind,_that.categoryId,_that.merchant,_that.description,_that.accountId,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Cop amount,  TxDirection direction,  DateTime occurredAt,  TxKind? kind,  String? categoryId,  String? merchant,  String? description,  String? accountId,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _NewTransaction():
return $default(_that.amount,_that.direction,_that.occurredAt,_that.kind,_that.categoryId,_that.merchant,_that.description,_that.accountId,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Cop amount,  TxDirection direction,  DateTime occurredAt,  TxKind? kind,  String? categoryId,  String? merchant,  String? description,  String? accountId,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _NewTransaction() when $default != null:
return $default(_that.amount,_that.direction,_that.occurredAt,_that.kind,_that.categoryId,_that.merchant,_that.description,_that.accountId,_that.notes);case _:
  return null;

}
}

}

/// @nodoc


class _NewTransaction implements NewTransaction {
  const _NewTransaction({required this.amount, required this.direction, required this.occurredAt, this.kind, this.categoryId, this.merchant, this.description, this.accountId, this.notes});
  

@override final  Cop amount;
@override final  TxDirection direction;
@override final  DateTime occurredAt;
@override final  TxKind? kind;
@override final  String? categoryId;
@override final  String? merchant;
@override final  String? description;
@override final  String? accountId;
@override final  String? notes;

/// Create a copy of NewTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewTransactionCopyWith<_NewTransaction> get copyWith => __$NewTransactionCopyWithImpl<_NewTransaction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewTransaction&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.description, description) || other.description == description)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,amount,direction,occurredAt,kind,categoryId,merchant,description,accountId,notes);

@override
String toString() {
  return 'NewTransaction(amount: $amount, direction: $direction, occurredAt: $occurredAt, kind: $kind, categoryId: $categoryId, merchant: $merchant, description: $description, accountId: $accountId, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$NewTransactionCopyWith<$Res> implements $NewTransactionCopyWith<$Res> {
  factory _$NewTransactionCopyWith(_NewTransaction value, $Res Function(_NewTransaction) _then) = __$NewTransactionCopyWithImpl;
@override @useResult
$Res call({
 Cop amount, TxDirection direction, DateTime occurredAt, TxKind? kind, String? categoryId, String? merchant, String? description, String? accountId, String? notes
});




}
/// @nodoc
class __$NewTransactionCopyWithImpl<$Res>
    implements _$NewTransactionCopyWith<$Res> {
  __$NewTransactionCopyWithImpl(this._self, this._then);

  final _NewTransaction _self;
  final $Res Function(_NewTransaction) _then;

/// Create a copy of NewTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? direction = null,Object? occurredAt = null,Object? kind = freezed,Object? categoryId = freezed,Object? merchant = freezed,Object? description = freezed,Object? accountId = freezed,Object? notes = freezed,}) {
  return _then(_NewTransaction(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Cop,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as TxDirection,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TxKind?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$TransactionPatch {

 String? get categoryId; TxKind? get kind; ({String? value})? get notes; ({String? value})? get merchant; Cop? get amount; TxDirection? get direction; DateTime? get occurredAt; ({String? value})? get accountId; bool get learnMerchantRule;
/// Create a copy of TransactionPatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionPatchCopyWith<TransactionPatch> get copyWith => _$TransactionPatchCopyWithImpl<TransactionPatch>(this as TransactionPatch, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionPatch&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.learnMerchantRule, learnMerchantRule) || other.learnMerchantRule == learnMerchantRule));
}


@override
int get hashCode => Object.hash(runtimeType,categoryId,kind,notes,merchant,amount,direction,occurredAt,accountId,learnMerchantRule);

@override
String toString() {
  return 'TransactionPatch(categoryId: $categoryId, kind: $kind, notes: $notes, merchant: $merchant, amount: $amount, direction: $direction, occurredAt: $occurredAt, accountId: $accountId, learnMerchantRule: $learnMerchantRule)';
}


}

/// @nodoc
abstract mixin class $TransactionPatchCopyWith<$Res>  {
  factory $TransactionPatchCopyWith(TransactionPatch value, $Res Function(TransactionPatch) _then) = _$TransactionPatchCopyWithImpl;
@useResult
$Res call({
 String? categoryId, TxKind? kind, ({String? value})? notes, ({String? value})? merchant, Cop? amount, TxDirection? direction, DateTime? occurredAt, ({String? value})? accountId, bool learnMerchantRule
});




}
/// @nodoc
class _$TransactionPatchCopyWithImpl<$Res>
    implements $TransactionPatchCopyWith<$Res> {
  _$TransactionPatchCopyWithImpl(this._self, this._then);

  final TransactionPatch _self;
  final $Res Function(TransactionPatch) _then;

/// Create a copy of TransactionPatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryId = freezed,Object? kind = freezed,Object? notes = freezed,Object? merchant = freezed,Object? amount = freezed,Object? direction = freezed,Object? occurredAt = freezed,Object? accountId = freezed,Object? learnMerchantRule = null,}) {
  return _then(_self.copyWith(
categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TxKind?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as ({String? value})?,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as ({String? value})?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Cop?,direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as TxDirection?,occurredAt: freezed == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as ({String? value})?,learnMerchantRule: null == learnMerchantRule ? _self.learnMerchantRule : learnMerchantRule // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TransactionPatch].
extension TransactionPatchPatterns on TransactionPatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionPatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionPatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionPatch value)  $default,){
final _that = this;
switch (_that) {
case _TransactionPatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionPatch value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionPatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? categoryId,  TxKind? kind,  ({String? value})? notes,  ({String? value})? merchant,  Cop? amount,  TxDirection? direction,  DateTime? occurredAt,  ({String? value})? accountId,  bool learnMerchantRule)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionPatch() when $default != null:
return $default(_that.categoryId,_that.kind,_that.notes,_that.merchant,_that.amount,_that.direction,_that.occurredAt,_that.accountId,_that.learnMerchantRule);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? categoryId,  TxKind? kind,  ({String? value})? notes,  ({String? value})? merchant,  Cop? amount,  TxDirection? direction,  DateTime? occurredAt,  ({String? value})? accountId,  bool learnMerchantRule)  $default,) {final _that = this;
switch (_that) {
case _TransactionPatch():
return $default(_that.categoryId,_that.kind,_that.notes,_that.merchant,_that.amount,_that.direction,_that.occurredAt,_that.accountId,_that.learnMerchantRule);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? categoryId,  TxKind? kind,  ({String? value})? notes,  ({String? value})? merchant,  Cop? amount,  TxDirection? direction,  DateTime? occurredAt,  ({String? value})? accountId,  bool learnMerchantRule)?  $default,) {final _that = this;
switch (_that) {
case _TransactionPatch() when $default != null:
return $default(_that.categoryId,_that.kind,_that.notes,_that.merchant,_that.amount,_that.direction,_that.occurredAt,_that.accountId,_that.learnMerchantRule);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionPatch implements TransactionPatch {
  const _TransactionPatch({this.categoryId, this.kind, this.notes, this.merchant, this.amount, this.direction, this.occurredAt, this.accountId, this.learnMerchantRule = true});
  

@override final  String? categoryId;
@override final  TxKind? kind;
@override final  ({String? value})? notes;
@override final  ({String? value})? merchant;
@override final  Cop? amount;
@override final  TxDirection? direction;
@override final  DateTime? occurredAt;
@override final  ({String? value})? accountId;
@override@JsonKey() final  bool learnMerchantRule;

/// Create a copy of TransactionPatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionPatchCopyWith<_TransactionPatch> get copyWith => __$TransactionPatchCopyWithImpl<_TransactionPatch>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionPatch&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.learnMerchantRule, learnMerchantRule) || other.learnMerchantRule == learnMerchantRule));
}


@override
int get hashCode => Object.hash(runtimeType,categoryId,kind,notes,merchant,amount,direction,occurredAt,accountId,learnMerchantRule);

@override
String toString() {
  return 'TransactionPatch(categoryId: $categoryId, kind: $kind, notes: $notes, merchant: $merchant, amount: $amount, direction: $direction, occurredAt: $occurredAt, accountId: $accountId, learnMerchantRule: $learnMerchantRule)';
}


}

/// @nodoc
abstract mixin class _$TransactionPatchCopyWith<$Res> implements $TransactionPatchCopyWith<$Res> {
  factory _$TransactionPatchCopyWith(_TransactionPatch value, $Res Function(_TransactionPatch) _then) = __$TransactionPatchCopyWithImpl;
@override @useResult
$Res call({
 String? categoryId, TxKind? kind, ({String? value})? notes, ({String? value})? merchant, Cop? amount, TxDirection? direction, DateTime? occurredAt, ({String? value})? accountId, bool learnMerchantRule
});




}
/// @nodoc
class __$TransactionPatchCopyWithImpl<$Res>
    implements _$TransactionPatchCopyWith<$Res> {
  __$TransactionPatchCopyWithImpl(this._self, this._then);

  final _TransactionPatch _self;
  final $Res Function(_TransactionPatch) _then;

/// Create a copy of TransactionPatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryId = freezed,Object? kind = freezed,Object? notes = freezed,Object? merchant = freezed,Object? amount = freezed,Object? direction = freezed,Object? occurredAt = freezed,Object? accountId = freezed,Object? learnMerchantRule = null,}) {
  return _then(_TransactionPatch(
categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as TxKind?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as ({String? value})?,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as ({String? value})?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Cop?,direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as TxDirection?,occurredAt: freezed == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as ({String? value})?,learnMerchantRule: null == learnMerchantRule ? _self.learnMerchantRule : learnMerchantRule // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$OutboxOperation {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutboxOperation);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OutboxOperation()';
}


}

/// @nodoc
class $OutboxOperationCopyWith<$Res>  {
$OutboxOperationCopyWith(OutboxOperation _, $Res Function(OutboxOperation) __);
}


/// Adds pattern-matching-related methods to [OutboxOperation].
extension OutboxOperationPatterns on OutboxOperation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CreateTransactionOp value)?  createTransaction,TResult Function( PatchTransactionOp value)?  patchTransaction,TResult Function( SetTransferPairOp value)?  setTransferPair,TResult Function( UnsetTransferPairOp value)?  unsetTransferPair,TResult Function( DeleteTransactionOp value)?  deleteTransaction,TResult Function( ConvertReviewOp value)?  convertReview,TResult Function( DiscardReviewOp value)?  discardReview,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CreateTransactionOp() when createTransaction != null:
return createTransaction(_that);case PatchTransactionOp() when patchTransaction != null:
return patchTransaction(_that);case SetTransferPairOp() when setTransferPair != null:
return setTransferPair(_that);case UnsetTransferPairOp() when unsetTransferPair != null:
return unsetTransferPair(_that);case DeleteTransactionOp() when deleteTransaction != null:
return deleteTransaction(_that);case ConvertReviewOp() when convertReview != null:
return convertReview(_that);case DiscardReviewOp() when discardReview != null:
return discardReview(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CreateTransactionOp value)  createTransaction,required TResult Function( PatchTransactionOp value)  patchTransaction,required TResult Function( SetTransferPairOp value)  setTransferPair,required TResult Function( UnsetTransferPairOp value)  unsetTransferPair,required TResult Function( DeleteTransactionOp value)  deleteTransaction,required TResult Function( ConvertReviewOp value)  convertReview,required TResult Function( DiscardReviewOp value)  discardReview,}){
final _that = this;
switch (_that) {
case CreateTransactionOp():
return createTransaction(_that);case PatchTransactionOp():
return patchTransaction(_that);case SetTransferPairOp():
return setTransferPair(_that);case UnsetTransferPairOp():
return unsetTransferPair(_that);case DeleteTransactionOp():
return deleteTransaction(_that);case ConvertReviewOp():
return convertReview(_that);case DiscardReviewOp():
return discardReview(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CreateTransactionOp value)?  createTransaction,TResult? Function( PatchTransactionOp value)?  patchTransaction,TResult? Function( SetTransferPairOp value)?  setTransferPair,TResult? Function( UnsetTransferPairOp value)?  unsetTransferPair,TResult? Function( DeleteTransactionOp value)?  deleteTransaction,TResult? Function( ConvertReviewOp value)?  convertReview,TResult? Function( DiscardReviewOp value)?  discardReview,}){
final _that = this;
switch (_that) {
case CreateTransactionOp() when createTransaction != null:
return createTransaction(_that);case PatchTransactionOp() when patchTransaction != null:
return patchTransaction(_that);case SetTransferPairOp() when setTransferPair != null:
return setTransferPair(_that);case UnsetTransferPairOp() when unsetTransferPair != null:
return unsetTransferPair(_that);case DeleteTransactionOp() when deleteTransaction != null:
return deleteTransaction(_that);case ConvertReviewOp() when convertReview != null:
return convertReview(_that);case DiscardReviewOp() when discardReview != null:
return discardReview(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String localId,  NewTransaction data)?  createTransaction,TResult Function( String id,  TransactionPatch patch)?  patchTransaction,TResult Function( String id,  String pairId)?  setTransferPair,TResult Function( String id)?  unsetTransferPair,TResult Function( String id)?  deleteTransaction,TResult Function( String rawMessageId,  String localId,  NewTransaction data)?  convertReview,TResult Function( String rawMessageId)?  discardReview,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CreateTransactionOp() when createTransaction != null:
return createTransaction(_that.localId,_that.data);case PatchTransactionOp() when patchTransaction != null:
return patchTransaction(_that.id,_that.patch);case SetTransferPairOp() when setTransferPair != null:
return setTransferPair(_that.id,_that.pairId);case UnsetTransferPairOp() when unsetTransferPair != null:
return unsetTransferPair(_that.id);case DeleteTransactionOp() when deleteTransaction != null:
return deleteTransaction(_that.id);case ConvertReviewOp() when convertReview != null:
return convertReview(_that.rawMessageId,_that.localId,_that.data);case DiscardReviewOp() when discardReview != null:
return discardReview(_that.rawMessageId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String localId,  NewTransaction data)  createTransaction,required TResult Function( String id,  TransactionPatch patch)  patchTransaction,required TResult Function( String id,  String pairId)  setTransferPair,required TResult Function( String id)  unsetTransferPair,required TResult Function( String id)  deleteTransaction,required TResult Function( String rawMessageId,  String localId,  NewTransaction data)  convertReview,required TResult Function( String rawMessageId)  discardReview,}) {final _that = this;
switch (_that) {
case CreateTransactionOp():
return createTransaction(_that.localId,_that.data);case PatchTransactionOp():
return patchTransaction(_that.id,_that.patch);case SetTransferPairOp():
return setTransferPair(_that.id,_that.pairId);case UnsetTransferPairOp():
return unsetTransferPair(_that.id);case DeleteTransactionOp():
return deleteTransaction(_that.id);case ConvertReviewOp():
return convertReview(_that.rawMessageId,_that.localId,_that.data);case DiscardReviewOp():
return discardReview(_that.rawMessageId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String localId,  NewTransaction data)?  createTransaction,TResult? Function( String id,  TransactionPatch patch)?  patchTransaction,TResult? Function( String id,  String pairId)?  setTransferPair,TResult? Function( String id)?  unsetTransferPair,TResult? Function( String id)?  deleteTransaction,TResult? Function( String rawMessageId,  String localId,  NewTransaction data)?  convertReview,TResult? Function( String rawMessageId)?  discardReview,}) {final _that = this;
switch (_that) {
case CreateTransactionOp() when createTransaction != null:
return createTransaction(_that.localId,_that.data);case PatchTransactionOp() when patchTransaction != null:
return patchTransaction(_that.id,_that.patch);case SetTransferPairOp() when setTransferPair != null:
return setTransferPair(_that.id,_that.pairId);case UnsetTransferPairOp() when unsetTransferPair != null:
return unsetTransferPair(_that.id);case DeleteTransactionOp() when deleteTransaction != null:
return deleteTransaction(_that.id);case ConvertReviewOp() when convertReview != null:
return convertReview(_that.rawMessageId,_that.localId,_that.data);case DiscardReviewOp() when discardReview != null:
return discardReview(_that.rawMessageId);case _:
  return null;

}
}

}

/// @nodoc


class CreateTransactionOp extends OutboxOperation {
  const CreateTransactionOp({required this.localId, required this.data}): super._();
  

 final  String localId;
 final  NewTransaction data;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateTransactionOpCopyWith<CreateTransactionOp> get copyWith => _$CreateTransactionOpCopyWithImpl<CreateTransactionOp>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateTransactionOp&&(identical(other.localId, localId) || other.localId == localId)&&(identical(other.data, data) || other.data == data));
}


@override
int get hashCode => Object.hash(runtimeType,localId,data);

@override
String toString() {
  return 'OutboxOperation.createTransaction(localId: $localId, data: $data)';
}


}

/// @nodoc
abstract mixin class $CreateTransactionOpCopyWith<$Res> implements $OutboxOperationCopyWith<$Res> {
  factory $CreateTransactionOpCopyWith(CreateTransactionOp value, $Res Function(CreateTransactionOp) _then) = _$CreateTransactionOpCopyWithImpl;
@useResult
$Res call({
 String localId, NewTransaction data
});


$NewTransactionCopyWith<$Res> get data;

}
/// @nodoc
class _$CreateTransactionOpCopyWithImpl<$Res>
    implements $CreateTransactionOpCopyWith<$Res> {
  _$CreateTransactionOpCopyWithImpl(this._self, this._then);

  final CreateTransactionOp _self;
  final $Res Function(CreateTransactionOp) _then;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? localId = null,Object? data = null,}) {
  return _then(CreateTransactionOp(
localId: null == localId ? _self.localId : localId // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as NewTransaction,
  ));
}

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NewTransactionCopyWith<$Res> get data {
  
  return $NewTransactionCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

/// @nodoc


class PatchTransactionOp extends OutboxOperation {
  const PatchTransactionOp({required this.id, required this.patch}): super._();
  

 final  String id;
 final  TransactionPatch patch;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PatchTransactionOpCopyWith<PatchTransactionOp> get copyWith => _$PatchTransactionOpCopyWithImpl<PatchTransactionOp>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PatchTransactionOp&&(identical(other.id, id) || other.id == id)&&(identical(other.patch, patch) || other.patch == patch));
}


@override
int get hashCode => Object.hash(runtimeType,id,patch);

@override
String toString() {
  return 'OutboxOperation.patchTransaction(id: $id, patch: $patch)';
}


}

/// @nodoc
abstract mixin class $PatchTransactionOpCopyWith<$Res> implements $OutboxOperationCopyWith<$Res> {
  factory $PatchTransactionOpCopyWith(PatchTransactionOp value, $Res Function(PatchTransactionOp) _then) = _$PatchTransactionOpCopyWithImpl;
@useResult
$Res call({
 String id, TransactionPatch patch
});


$TransactionPatchCopyWith<$Res> get patch;

}
/// @nodoc
class _$PatchTransactionOpCopyWithImpl<$Res>
    implements $PatchTransactionOpCopyWith<$Res> {
  _$PatchTransactionOpCopyWithImpl(this._self, this._then);

  final PatchTransactionOp _self;
  final $Res Function(PatchTransactionOp) _then;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? patch = null,}) {
  return _then(PatchTransactionOp(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,patch: null == patch ? _self.patch : patch // ignore: cast_nullable_to_non_nullable
as TransactionPatch,
  ));
}

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionPatchCopyWith<$Res> get patch {
  
  return $TransactionPatchCopyWith<$Res>(_self.patch, (value) {
    return _then(_self.copyWith(patch: value));
  });
}
}

/// @nodoc


class SetTransferPairOp extends OutboxOperation {
  const SetTransferPairOp({required this.id, required this.pairId}): super._();
  

 final  String id;
 final  String pairId;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetTransferPairOpCopyWith<SetTransferPairOp> get copyWith => _$SetTransferPairOpCopyWithImpl<SetTransferPairOp>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetTransferPairOp&&(identical(other.id, id) || other.id == id)&&(identical(other.pairId, pairId) || other.pairId == pairId));
}


@override
int get hashCode => Object.hash(runtimeType,id,pairId);

@override
String toString() {
  return 'OutboxOperation.setTransferPair(id: $id, pairId: $pairId)';
}


}

/// @nodoc
abstract mixin class $SetTransferPairOpCopyWith<$Res> implements $OutboxOperationCopyWith<$Res> {
  factory $SetTransferPairOpCopyWith(SetTransferPairOp value, $Res Function(SetTransferPairOp) _then) = _$SetTransferPairOpCopyWithImpl;
@useResult
$Res call({
 String id, String pairId
});




}
/// @nodoc
class _$SetTransferPairOpCopyWithImpl<$Res>
    implements $SetTransferPairOpCopyWith<$Res> {
  _$SetTransferPairOpCopyWithImpl(this._self, this._then);

  final SetTransferPairOp _self;
  final $Res Function(SetTransferPairOp) _then;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? pairId = null,}) {
  return _then(SetTransferPairOp(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pairId: null == pairId ? _self.pairId : pairId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class UnsetTransferPairOp extends OutboxOperation {
  const UnsetTransferPairOp({required this.id}): super._();
  

 final  String id;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnsetTransferPairOpCopyWith<UnsetTransferPairOp> get copyWith => _$UnsetTransferPairOpCopyWithImpl<UnsetTransferPairOp>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnsetTransferPairOp&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'OutboxOperation.unsetTransferPair(id: $id)';
}


}

/// @nodoc
abstract mixin class $UnsetTransferPairOpCopyWith<$Res> implements $OutboxOperationCopyWith<$Res> {
  factory $UnsetTransferPairOpCopyWith(UnsetTransferPairOp value, $Res Function(UnsetTransferPairOp) _then) = _$UnsetTransferPairOpCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class _$UnsetTransferPairOpCopyWithImpl<$Res>
    implements $UnsetTransferPairOpCopyWith<$Res> {
  _$UnsetTransferPairOpCopyWithImpl(this._self, this._then);

  final UnsetTransferPairOp _self;
  final $Res Function(UnsetTransferPairOp) _then;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(UnsetTransferPairOp(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class DeleteTransactionOp extends OutboxOperation {
  const DeleteTransactionOp({required this.id}): super._();
  

 final  String id;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeleteTransactionOpCopyWith<DeleteTransactionOp> get copyWith => _$DeleteTransactionOpCopyWithImpl<DeleteTransactionOp>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteTransactionOp&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'OutboxOperation.deleteTransaction(id: $id)';
}


}

/// @nodoc
abstract mixin class $DeleteTransactionOpCopyWith<$Res> implements $OutboxOperationCopyWith<$Res> {
  factory $DeleteTransactionOpCopyWith(DeleteTransactionOp value, $Res Function(DeleteTransactionOp) _then) = _$DeleteTransactionOpCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class _$DeleteTransactionOpCopyWithImpl<$Res>
    implements $DeleteTransactionOpCopyWith<$Res> {
  _$DeleteTransactionOpCopyWithImpl(this._self, this._then);

  final DeleteTransactionOp _self;
  final $Res Function(DeleteTransactionOp) _then;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(DeleteTransactionOp(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ConvertReviewOp extends OutboxOperation {
  const ConvertReviewOp({required this.rawMessageId, required this.localId, required this.data}): super._();
  

 final  String rawMessageId;
 final  String localId;
 final  NewTransaction data;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConvertReviewOpCopyWith<ConvertReviewOp> get copyWith => _$ConvertReviewOpCopyWithImpl<ConvertReviewOp>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConvertReviewOp&&(identical(other.rawMessageId, rawMessageId) || other.rawMessageId == rawMessageId)&&(identical(other.localId, localId) || other.localId == localId)&&(identical(other.data, data) || other.data == data));
}


@override
int get hashCode => Object.hash(runtimeType,rawMessageId,localId,data);

@override
String toString() {
  return 'OutboxOperation.convertReview(rawMessageId: $rawMessageId, localId: $localId, data: $data)';
}


}

/// @nodoc
abstract mixin class $ConvertReviewOpCopyWith<$Res> implements $OutboxOperationCopyWith<$Res> {
  factory $ConvertReviewOpCopyWith(ConvertReviewOp value, $Res Function(ConvertReviewOp) _then) = _$ConvertReviewOpCopyWithImpl;
@useResult
$Res call({
 String rawMessageId, String localId, NewTransaction data
});


$NewTransactionCopyWith<$Res> get data;

}
/// @nodoc
class _$ConvertReviewOpCopyWithImpl<$Res>
    implements $ConvertReviewOpCopyWith<$Res> {
  _$ConvertReviewOpCopyWithImpl(this._self, this._then);

  final ConvertReviewOp _self;
  final $Res Function(ConvertReviewOp) _then;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? rawMessageId = null,Object? localId = null,Object? data = null,}) {
  return _then(ConvertReviewOp(
rawMessageId: null == rawMessageId ? _self.rawMessageId : rawMessageId // ignore: cast_nullable_to_non_nullable
as String,localId: null == localId ? _self.localId : localId // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as NewTransaction,
  ));
}

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NewTransactionCopyWith<$Res> get data {
  
  return $NewTransactionCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}

/// @nodoc


class DiscardReviewOp extends OutboxOperation {
  const DiscardReviewOp({required this.rawMessageId}): super._();
  

 final  String rawMessageId;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiscardReviewOpCopyWith<DiscardReviewOp> get copyWith => _$DiscardReviewOpCopyWithImpl<DiscardReviewOp>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiscardReviewOp&&(identical(other.rawMessageId, rawMessageId) || other.rawMessageId == rawMessageId));
}


@override
int get hashCode => Object.hash(runtimeType,rawMessageId);

@override
String toString() {
  return 'OutboxOperation.discardReview(rawMessageId: $rawMessageId)';
}


}

/// @nodoc
abstract mixin class $DiscardReviewOpCopyWith<$Res> implements $OutboxOperationCopyWith<$Res> {
  factory $DiscardReviewOpCopyWith(DiscardReviewOp value, $Res Function(DiscardReviewOp) _then) = _$DiscardReviewOpCopyWithImpl;
@useResult
$Res call({
 String rawMessageId
});




}
/// @nodoc
class _$DiscardReviewOpCopyWithImpl<$Res>
    implements $DiscardReviewOpCopyWith<$Res> {
  _$DiscardReviewOpCopyWithImpl(this._self, this._then);

  final DiscardReviewOp _self;
  final $Res Function(DiscardReviewOp) _then;

/// Create a copy of OutboxOperation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? rawMessageId = null,}) {
  return _then(DiscardReviewOp(
rawMessageId: null == rawMessageId ? _self.rawMessageId : rawMessageId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
