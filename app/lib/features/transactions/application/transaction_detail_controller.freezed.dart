// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_detail_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SourcesState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SourcesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SourcesState()';
}


}

/// @nodoc
class $SourcesStateCopyWith<$Res>  {
$SourcesStateCopyWith(SourcesState _, $Res Function(SourcesState) __);
}


/// Adds pattern-matching-related methods to [SourcesState].
extension SourcesStatePatterns on SourcesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SourcesLoading value)?  loading,TResult Function( SourcesOffline value)?  offline,TResult Function( SourcesLoaded value)?  loaded,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SourcesLoading() when loading != null:
return loading(_that);case SourcesOffline() when offline != null:
return offline(_that);case SourcesLoaded() when loaded != null:
return loaded(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SourcesLoading value)  loading,required TResult Function( SourcesOffline value)  offline,required TResult Function( SourcesLoaded value)  loaded,}){
final _that = this;
switch (_that) {
case SourcesLoading():
return loading(_that);case SourcesOffline():
return offline(_that);case SourcesLoaded():
return loaded(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SourcesLoading value)?  loading,TResult? Function( SourcesOffline value)?  offline,TResult? Function( SourcesLoaded value)?  loaded,}){
final _that = this;
switch (_that) {
case SourcesLoading() when loading != null:
return loading(_that);case SourcesOffline() when offline != null:
return offline(_that);case SourcesLoaded() when loaded != null:
return loaded(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function()?  offline,TResult Function( List<TxSource> sources)?  loaded,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SourcesLoading() when loading != null:
return loading();case SourcesOffline() when offline != null:
return offline();case SourcesLoaded() when loaded != null:
return loaded(_that.sources);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function()  offline,required TResult Function( List<TxSource> sources)  loaded,}) {final _that = this;
switch (_that) {
case SourcesLoading():
return loading();case SourcesOffline():
return offline();case SourcesLoaded():
return loaded(_that.sources);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function()?  offline,TResult? Function( List<TxSource> sources)?  loaded,}) {final _that = this;
switch (_that) {
case SourcesLoading() when loading != null:
return loading();case SourcesOffline() when offline != null:
return offline();case SourcesLoaded() when loaded != null:
return loaded(_that.sources);case _:
  return null;

}
}

}

/// @nodoc


class SourcesLoading implements SourcesState {
  const SourcesLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SourcesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SourcesState.loading()';
}


}




/// @nodoc


class SourcesOffline implements SourcesState {
  const SourcesOffline();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SourcesOffline);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SourcesState.offline()';
}


}




/// @nodoc


class SourcesLoaded implements SourcesState {
  const SourcesLoaded(final  List<TxSource> sources): _sources = sources;
  

 final  List<TxSource> _sources;
 List<TxSource> get sources {
  if (_sources is EqualUnmodifiableListView) return _sources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sources);
}


/// Create a copy of SourcesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SourcesLoadedCopyWith<SourcesLoaded> get copyWith => _$SourcesLoadedCopyWithImpl<SourcesLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SourcesLoaded&&const DeepCollectionEquality().equals(other._sources, _sources));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_sources));

@override
String toString() {
  return 'SourcesState.loaded(sources: $sources)';
}


}

/// @nodoc
abstract mixin class $SourcesLoadedCopyWith<$Res> implements $SourcesStateCopyWith<$Res> {
  factory $SourcesLoadedCopyWith(SourcesLoaded value, $Res Function(SourcesLoaded) _then) = _$SourcesLoadedCopyWithImpl;
@useResult
$Res call({
 List<TxSource> sources
});




}
/// @nodoc
class _$SourcesLoadedCopyWithImpl<$Res>
    implements $SourcesLoadedCopyWith<$Res> {
  _$SourcesLoadedCopyWithImpl(this._self, this._then);

  final SourcesLoaded _self;
  final $Res Function(SourcesLoaded) _then;

/// Create a copy of SourcesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sources = null,}) {
  return _then(SourcesLoaded(
null == sources ? _self._sources : sources // ignore: cast_nullable_to_non_nullable
as List<TxSource>,
  ));
}


}

/// @nodoc
mixin _$TransactionDetailState {

 AsyncValue<TransactionView?> get tx; SourcesState get sources;
/// Create a copy of TransactionDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionDetailStateCopyWith<TransactionDetailState> get copyWith => _$TransactionDetailStateCopyWithImpl<TransactionDetailState>(this as TransactionDetailState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionDetailState&&(identical(other.tx, tx) || other.tx == tx)&&(identical(other.sources, sources) || other.sources == sources));
}


@override
int get hashCode => Object.hash(runtimeType,tx,sources);

@override
String toString() {
  return 'TransactionDetailState(tx: $tx, sources: $sources)';
}


}

/// @nodoc
abstract mixin class $TransactionDetailStateCopyWith<$Res>  {
  factory $TransactionDetailStateCopyWith(TransactionDetailState value, $Res Function(TransactionDetailState) _then) = _$TransactionDetailStateCopyWithImpl;
@useResult
$Res call({
 AsyncValue<TransactionView?> tx, SourcesState sources
});


$SourcesStateCopyWith<$Res> get sources;

}
/// @nodoc
class _$TransactionDetailStateCopyWithImpl<$Res>
    implements $TransactionDetailStateCopyWith<$Res> {
  _$TransactionDetailStateCopyWithImpl(this._self, this._then);

  final TransactionDetailState _self;
  final $Res Function(TransactionDetailState) _then;

/// Create a copy of TransactionDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tx = null,Object? sources = null,}) {
  return _then(_self.copyWith(
tx: null == tx ? _self.tx : tx // ignore: cast_nullable_to_non_nullable
as AsyncValue<TransactionView?>,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as SourcesState,
  ));
}
/// Create a copy of TransactionDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SourcesStateCopyWith<$Res> get sources {
  
  return $SourcesStateCopyWith<$Res>(_self.sources, (value) {
    return _then(_self.copyWith(sources: value));
  });
}
}


/// Adds pattern-matching-related methods to [TransactionDetailState].
extension TransactionDetailStatePatterns on TransactionDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionDetailState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionDetailState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionDetailState value)  $default,){
final _that = this;
switch (_that) {
case _TransactionDetailState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionDetailState value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionDetailState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AsyncValue<TransactionView?> tx,  SourcesState sources)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionDetailState() when $default != null:
return $default(_that.tx,_that.sources);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AsyncValue<TransactionView?> tx,  SourcesState sources)  $default,) {final _that = this;
switch (_that) {
case _TransactionDetailState():
return $default(_that.tx,_that.sources);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AsyncValue<TransactionView?> tx,  SourcesState sources)?  $default,) {final _that = this;
switch (_that) {
case _TransactionDetailState() when $default != null:
return $default(_that.tx,_that.sources);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionDetailState implements TransactionDetailState {
  const _TransactionDetailState({required this.tx, required this.sources});
  

@override final  AsyncValue<TransactionView?> tx;
@override final  SourcesState sources;

/// Create a copy of TransactionDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionDetailStateCopyWith<_TransactionDetailState> get copyWith => __$TransactionDetailStateCopyWithImpl<_TransactionDetailState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionDetailState&&(identical(other.tx, tx) || other.tx == tx)&&(identical(other.sources, sources) || other.sources == sources));
}


@override
int get hashCode => Object.hash(runtimeType,tx,sources);

@override
String toString() {
  return 'TransactionDetailState(tx: $tx, sources: $sources)';
}


}

/// @nodoc
abstract mixin class _$TransactionDetailStateCopyWith<$Res> implements $TransactionDetailStateCopyWith<$Res> {
  factory _$TransactionDetailStateCopyWith(_TransactionDetailState value, $Res Function(_TransactionDetailState) _then) = __$TransactionDetailStateCopyWithImpl;
@override @useResult
$Res call({
 AsyncValue<TransactionView?> tx, SourcesState sources
});


@override $SourcesStateCopyWith<$Res> get sources;

}
/// @nodoc
class __$TransactionDetailStateCopyWithImpl<$Res>
    implements _$TransactionDetailStateCopyWith<$Res> {
  __$TransactionDetailStateCopyWithImpl(this._self, this._then);

  final _TransactionDetailState _self;
  final $Res Function(_TransactionDetailState) _then;

/// Create a copy of TransactionDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tx = null,Object? sources = null,}) {
  return _then(_TransactionDetailState(
tx: null == tx ? _self.tx : tx // ignore: cast_nullable_to_non_nullable
as AsyncValue<TransactionView?>,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as SourcesState,
  ));
}

/// Create a copy of TransactionDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SourcesStateCopyWith<$Res> get sources {
  
  return $SourcesStateCopyWith<$Res>(_self.sources, (value) {
    return _then(_self.copyWith(sources: value));
  });
}
}

// dart format on
