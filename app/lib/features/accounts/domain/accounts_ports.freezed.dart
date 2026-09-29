// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'accounts_ports.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LinkedAccount {

 String get id; String get bank; String get kind; int get transactionCount; String? get last4; String? get alias;
/// Create a copy of LinkedAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinkedAccountCopyWith<LinkedAccount> get copyWith => _$LinkedAccountCopyWithImpl<LinkedAccount>(this as LinkedAccount, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinkedAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.bank, bank) || other.bank == bank)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.transactionCount, transactionCount) || other.transactionCount == transactionCount)&&(identical(other.last4, last4) || other.last4 == last4)&&(identical(other.alias, alias) || other.alias == alias));
}


@override
int get hashCode => Object.hash(runtimeType,id,bank,kind,transactionCount,last4,alias);

@override
String toString() {
  return 'LinkedAccount(id: $id, bank: $bank, kind: $kind, transactionCount: $transactionCount, last4: $last4, alias: $alias)';
}


}

/// @nodoc
abstract mixin class $LinkedAccountCopyWith<$Res>  {
  factory $LinkedAccountCopyWith(LinkedAccount value, $Res Function(LinkedAccount) _then) = _$LinkedAccountCopyWithImpl;
@useResult
$Res call({
 String id, String bank, String kind, int transactionCount, String? last4, String? alias
});




}
/// @nodoc
class _$LinkedAccountCopyWithImpl<$Res>
    implements $LinkedAccountCopyWith<$Res> {
  _$LinkedAccountCopyWithImpl(this._self, this._then);

  final LinkedAccount _self;
  final $Res Function(LinkedAccount) _then;

/// Create a copy of LinkedAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? bank = null,Object? kind = null,Object? transactionCount = null,Object? last4 = freezed,Object? alias = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bank: null == bank ? _self.bank : bank // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,transactionCount: null == transactionCount ? _self.transactionCount : transactionCount // ignore: cast_nullable_to_non_nullable
as int,last4: freezed == last4 ? _self.last4 : last4 // ignore: cast_nullable_to_non_nullable
as String?,alias: freezed == alias ? _self.alias : alias // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LinkedAccount].
extension LinkedAccountPatterns on LinkedAccount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LinkedAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LinkedAccount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LinkedAccount value)  $default,){
final _that = this;
switch (_that) {
case _LinkedAccount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LinkedAccount value)?  $default,){
final _that = this;
switch (_that) {
case _LinkedAccount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String bank,  String kind,  int transactionCount,  String? last4,  String? alias)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LinkedAccount() when $default != null:
return $default(_that.id,_that.bank,_that.kind,_that.transactionCount,_that.last4,_that.alias);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String bank,  String kind,  int transactionCount,  String? last4,  String? alias)  $default,) {final _that = this;
switch (_that) {
case _LinkedAccount():
return $default(_that.id,_that.bank,_that.kind,_that.transactionCount,_that.last4,_that.alias);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String bank,  String kind,  int transactionCount,  String? last4,  String? alias)?  $default,) {final _that = this;
switch (_that) {
case _LinkedAccount() when $default != null:
return $default(_that.id,_that.bank,_that.kind,_that.transactionCount,_that.last4,_that.alias);case _:
  return null;

}
}

}

/// @nodoc


class _LinkedAccount implements LinkedAccount {
  const _LinkedAccount({required this.id, required this.bank, required this.kind, required this.transactionCount, this.last4, this.alias});
  

@override final  String id;
@override final  String bank;
@override final  String kind;
@override final  int transactionCount;
@override final  String? last4;
@override final  String? alias;

/// Create a copy of LinkedAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LinkedAccountCopyWith<_LinkedAccount> get copyWith => __$LinkedAccountCopyWithImpl<_LinkedAccount>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LinkedAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.bank, bank) || other.bank == bank)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.transactionCount, transactionCount) || other.transactionCount == transactionCount)&&(identical(other.last4, last4) || other.last4 == last4)&&(identical(other.alias, alias) || other.alias == alias));
}


@override
int get hashCode => Object.hash(runtimeType,id,bank,kind,transactionCount,last4,alias);

@override
String toString() {
  return 'LinkedAccount(id: $id, bank: $bank, kind: $kind, transactionCount: $transactionCount, last4: $last4, alias: $alias)';
}


}

/// @nodoc
abstract mixin class _$LinkedAccountCopyWith<$Res> implements $LinkedAccountCopyWith<$Res> {
  factory _$LinkedAccountCopyWith(_LinkedAccount value, $Res Function(_LinkedAccount) _then) = __$LinkedAccountCopyWithImpl;
@override @useResult
$Res call({
 String id, String bank, String kind, int transactionCount, String? last4, String? alias
});




}
/// @nodoc
class __$LinkedAccountCopyWithImpl<$Res>
    implements _$LinkedAccountCopyWith<$Res> {
  __$LinkedAccountCopyWithImpl(this._self, this._then);

  final _LinkedAccount _self;
  final $Res Function(_LinkedAccount) _then;

/// Create a copy of LinkedAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? bank = null,Object? kind = null,Object? transactionCount = null,Object? last4 = freezed,Object? alias = freezed,}) {
  return _then(_LinkedAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bank: null == bank ? _self.bank : bank // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,transactionCount: null == transactionCount ? _self.transactionCount : transactionCount // ignore: cast_nullable_to_non_nullable
as int,last4: freezed == last4 ? _self.last4 : last4 // ignore: cast_nullable_to_non_nullable
as String?,alias: freezed == alias ? _self.alias : alias // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
