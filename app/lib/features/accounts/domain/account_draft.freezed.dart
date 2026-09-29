// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountDraft {

 String get bank; String get kind; String get last4; String get alias;
/// Create a copy of AccountDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountDraftCopyWith<AccountDraft> get copyWith => _$AccountDraftCopyWithImpl<AccountDraft>(this as AccountDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountDraft&&(identical(other.bank, bank) || other.bank == bank)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.last4, last4) || other.last4 == last4)&&(identical(other.alias, alias) || other.alias == alias));
}


@override
int get hashCode => Object.hash(runtimeType,bank,kind,last4,alias);

@override
String toString() {
  return 'AccountDraft(bank: $bank, kind: $kind, last4: $last4, alias: $alias)';
}


}

/// @nodoc
abstract mixin class $AccountDraftCopyWith<$Res>  {
  factory $AccountDraftCopyWith(AccountDraft value, $Res Function(AccountDraft) _then) = _$AccountDraftCopyWithImpl;
@useResult
$Res call({
 String bank, String kind, String last4, String alias
});




}
/// @nodoc
class _$AccountDraftCopyWithImpl<$Res>
    implements $AccountDraftCopyWith<$Res> {
  _$AccountDraftCopyWithImpl(this._self, this._then);

  final AccountDraft _self;
  final $Res Function(AccountDraft) _then;

/// Create a copy of AccountDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bank = null,Object? kind = null,Object? last4 = null,Object? alias = null,}) {
  return _then(_self.copyWith(
bank: null == bank ? _self.bank : bank // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,last4: null == last4 ? _self.last4 : last4 // ignore: cast_nullable_to_non_nullable
as String,alias: null == alias ? _self.alias : alias // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountDraft].
extension AccountDraftPatterns on AccountDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountDraft value)  $default,){
final _that = this;
switch (_that) {
case _AccountDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountDraft value)?  $default,){
final _that = this;
switch (_that) {
case _AccountDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String bank,  String kind,  String last4,  String alias)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountDraft() when $default != null:
return $default(_that.bank,_that.kind,_that.last4,_that.alias);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String bank,  String kind,  String last4,  String alias)  $default,) {final _that = this;
switch (_that) {
case _AccountDraft():
return $default(_that.bank,_that.kind,_that.last4,_that.alias);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String bank,  String kind,  String last4,  String alias)?  $default,) {final _that = this;
switch (_that) {
case _AccountDraft() when $default != null:
return $default(_that.bank,_that.kind,_that.last4,_that.alias);case _:
  return null;

}
}

}

/// @nodoc


class _AccountDraft extends AccountDraft {
  const _AccountDraft({this.bank = '', this.kind = 'savings', this.last4 = '', this.alias = ''}): super._();
  

@override@JsonKey() final  String bank;
@override@JsonKey() final  String kind;
@override@JsonKey() final  String last4;
@override@JsonKey() final  String alias;

/// Create a copy of AccountDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountDraftCopyWith<_AccountDraft> get copyWith => __$AccountDraftCopyWithImpl<_AccountDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountDraft&&(identical(other.bank, bank) || other.bank == bank)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.last4, last4) || other.last4 == last4)&&(identical(other.alias, alias) || other.alias == alias));
}


@override
int get hashCode => Object.hash(runtimeType,bank,kind,last4,alias);

@override
String toString() {
  return 'AccountDraft(bank: $bank, kind: $kind, last4: $last4, alias: $alias)';
}


}

/// @nodoc
abstract mixin class _$AccountDraftCopyWith<$Res> implements $AccountDraftCopyWith<$Res> {
  factory _$AccountDraftCopyWith(_AccountDraft value, $Res Function(_AccountDraft) _then) = __$AccountDraftCopyWithImpl;
@override @useResult
$Res call({
 String bank, String kind, String last4, String alias
});




}
/// @nodoc
class __$AccountDraftCopyWithImpl<$Res>
    implements _$AccountDraftCopyWith<$Res> {
  __$AccountDraftCopyWithImpl(this._self, this._then);

  final _AccountDraft _self;
  final $Res Function(_AccountDraft) _then;

/// Create a copy of AccountDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bank = null,Object? kind = null,Object? last4 = null,Object? alias = null,}) {
  return _then(_AccountDraft(
bank: null == bank ? _self.bank : bank // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,last4: null == last4 ? _self.last4 : last4 // ignore: cast_nullable_to_non_nullable
as String,alias: null == alias ? _self.alias : alias // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
