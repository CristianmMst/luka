// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'captured_notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CapturedNotification {

/// Id de la fila en la cola nativa, para sacarla tras enviarla.
 int get id; String get package; CaptureChannel get channel;/// Instante en que se publicó, en UTC.
 DateTime get postedAt;/// Zona del teléfono en ese momento: el backend exige `posted_at` con
/// zona horaria.
 Duration get utcOffset;/// `bigText` si la notificación lo trae; si no, `text`.
 String get text;/// En SMS es el remitente: el backend re-valida el patrón sobre él.
 String? get title;
/// Create a copy of CapturedNotification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CapturedNotificationCopyWith<CapturedNotification> get copyWith => _$CapturedNotificationCopyWithImpl<CapturedNotification>(this as CapturedNotification, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CapturedNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.package, package) || other.package == package)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.postedAt, postedAt) || other.postedAt == postedAt)&&(identical(other.utcOffset, utcOffset) || other.utcOffset == utcOffset)&&(identical(other.text, text) || other.text == text)&&(identical(other.title, title) || other.title == title));
}


@override
int get hashCode => Object.hash(runtimeType,id,package,channel,postedAt,utcOffset,text,title);

@override
String toString() {
  return 'CapturedNotification(id: $id, package: $package, channel: $channel, postedAt: $postedAt, utcOffset: $utcOffset, text: $text, title: $title)';
}


}

/// @nodoc
abstract mixin class $CapturedNotificationCopyWith<$Res>  {
  factory $CapturedNotificationCopyWith(CapturedNotification value, $Res Function(CapturedNotification) _then) = _$CapturedNotificationCopyWithImpl;
@useResult
$Res call({
 int id, String package, CaptureChannel channel, DateTime postedAt, Duration utcOffset, String text, String? title
});




}
/// @nodoc
class _$CapturedNotificationCopyWithImpl<$Res>
    implements $CapturedNotificationCopyWith<$Res> {
  _$CapturedNotificationCopyWithImpl(this._self, this._then);

  final CapturedNotification _self;
  final $Res Function(CapturedNotification) _then;

/// Create a copy of CapturedNotification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? package = null,Object? channel = null,Object? postedAt = null,Object? utcOffset = null,Object? text = null,Object? title = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,package: null == package ? _self.package : package // ignore: cast_nullable_to_non_nullable
as String,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as CaptureChannel,postedAt: null == postedAt ? _self.postedAt : postedAt // ignore: cast_nullable_to_non_nullable
as DateTime,utcOffset: null == utcOffset ? _self.utcOffset : utcOffset // ignore: cast_nullable_to_non_nullable
as Duration,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CapturedNotification].
extension CapturedNotificationPatterns on CapturedNotification {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CapturedNotification value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CapturedNotification() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CapturedNotification value)  $default,){
final _that = this;
switch (_that) {
case _CapturedNotification():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CapturedNotification value)?  $default,){
final _that = this;
switch (_that) {
case _CapturedNotification() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String package,  CaptureChannel channel,  DateTime postedAt,  Duration utcOffset,  String text,  String? title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CapturedNotification() when $default != null:
return $default(_that.id,_that.package,_that.channel,_that.postedAt,_that.utcOffset,_that.text,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String package,  CaptureChannel channel,  DateTime postedAt,  Duration utcOffset,  String text,  String? title)  $default,) {final _that = this;
switch (_that) {
case _CapturedNotification():
return $default(_that.id,_that.package,_that.channel,_that.postedAt,_that.utcOffset,_that.text,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String package,  CaptureChannel channel,  DateTime postedAt,  Duration utcOffset,  String text,  String? title)?  $default,) {final _that = this;
switch (_that) {
case _CapturedNotification() when $default != null:
return $default(_that.id,_that.package,_that.channel,_that.postedAt,_that.utcOffset,_that.text,_that.title);case _:
  return null;

}
}

}

/// @nodoc


class _CapturedNotification extends CapturedNotification {
  const _CapturedNotification({required this.id, required this.package, required this.channel, required this.postedAt, required this.utcOffset, required this.text, this.title}): super._();
  

/// Id de la fila en la cola nativa, para sacarla tras enviarla.
@override final  int id;
@override final  String package;
@override final  CaptureChannel channel;
/// Instante en que se publicó, en UTC.
@override final  DateTime postedAt;
/// Zona del teléfono en ese momento: el backend exige `posted_at` con
/// zona horaria.
@override final  Duration utcOffset;
/// `bigText` si la notificación lo trae; si no, `text`.
@override final  String text;
/// En SMS es el remitente: el backend re-valida el patrón sobre él.
@override final  String? title;

/// Create a copy of CapturedNotification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CapturedNotificationCopyWith<_CapturedNotification> get copyWith => __$CapturedNotificationCopyWithImpl<_CapturedNotification>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CapturedNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.package, package) || other.package == package)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.postedAt, postedAt) || other.postedAt == postedAt)&&(identical(other.utcOffset, utcOffset) || other.utcOffset == utcOffset)&&(identical(other.text, text) || other.text == text)&&(identical(other.title, title) || other.title == title));
}


@override
int get hashCode => Object.hash(runtimeType,id,package,channel,postedAt,utcOffset,text,title);

@override
String toString() {
  return 'CapturedNotification(id: $id, package: $package, channel: $channel, postedAt: $postedAt, utcOffset: $utcOffset, text: $text, title: $title)';
}


}

/// @nodoc
abstract mixin class _$CapturedNotificationCopyWith<$Res> implements $CapturedNotificationCopyWith<$Res> {
  factory _$CapturedNotificationCopyWith(_CapturedNotification value, $Res Function(_CapturedNotification) _then) = __$CapturedNotificationCopyWithImpl;
@override @useResult
$Res call({
 int id, String package, CaptureChannel channel, DateTime postedAt, Duration utcOffset, String text, String? title
});




}
/// @nodoc
class __$CapturedNotificationCopyWithImpl<$Res>
    implements _$CapturedNotificationCopyWith<$Res> {
  __$CapturedNotificationCopyWithImpl(this._self, this._then);

  final _CapturedNotification _self;
  final $Res Function(_CapturedNotification) _then;

/// Create a copy of CapturedNotification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? package = null,Object? channel = null,Object? postedAt = null,Object? utcOffset = null,Object? text = null,Object? title = freezed,}) {
  return _then(_CapturedNotification(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,package: null == package ? _self.package : package // ignore: cast_nullable_to_non_nullable
as String,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as CaptureChannel,postedAt: null == postedAt ? _self.postedAt : postedAt // ignore: cast_nullable_to_non_nullable
as DateTime,utcOffset: null == utcOffset ? _self.utcOffset : utcOffset // ignore: cast_nullable_to_non_nullable
as Duration,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$CaptureConfig {

 int get version; List<String> get bankingApps; List<String> get messagesApps;/// Regex con flags en línea (`(?i)…`), aplicadas al título de la
/// notificación de Mensajes.
 List<String> get smsSenderPatterns;
/// Create a copy of CaptureConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CaptureConfigCopyWith<CaptureConfig> get copyWith => _$CaptureConfigCopyWithImpl<CaptureConfig>(this as CaptureConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CaptureConfig&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other.bankingApps, bankingApps)&&const DeepCollectionEquality().equals(other.messagesApps, messagesApps)&&const DeepCollectionEquality().equals(other.smsSenderPatterns, smsSenderPatterns));
}


@override
int get hashCode => Object.hash(runtimeType,version,const DeepCollectionEquality().hash(bankingApps),const DeepCollectionEquality().hash(messagesApps),const DeepCollectionEquality().hash(smsSenderPatterns));

@override
String toString() {
  return 'CaptureConfig(version: $version, bankingApps: $bankingApps, messagesApps: $messagesApps, smsSenderPatterns: $smsSenderPatterns)';
}


}

/// @nodoc
abstract mixin class $CaptureConfigCopyWith<$Res>  {
  factory $CaptureConfigCopyWith(CaptureConfig value, $Res Function(CaptureConfig) _then) = _$CaptureConfigCopyWithImpl;
@useResult
$Res call({
 int version, List<String> bankingApps, List<String> messagesApps, List<String> smsSenderPatterns
});




}
/// @nodoc
class _$CaptureConfigCopyWithImpl<$Res>
    implements $CaptureConfigCopyWith<$Res> {
  _$CaptureConfigCopyWithImpl(this._self, this._then);

  final CaptureConfig _self;
  final $Res Function(CaptureConfig) _then;

/// Create a copy of CaptureConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? bankingApps = null,Object? messagesApps = null,Object? smsSenderPatterns = null,}) {
  return _then(_self.copyWith(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,bankingApps: null == bankingApps ? _self.bankingApps : bankingApps // ignore: cast_nullable_to_non_nullable
as List<String>,messagesApps: null == messagesApps ? _self.messagesApps : messagesApps // ignore: cast_nullable_to_non_nullable
as List<String>,smsSenderPatterns: null == smsSenderPatterns ? _self.smsSenderPatterns : smsSenderPatterns // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [CaptureConfig].
extension CaptureConfigPatterns on CaptureConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CaptureConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CaptureConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CaptureConfig value)  $default,){
final _that = this;
switch (_that) {
case _CaptureConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CaptureConfig value)?  $default,){
final _that = this;
switch (_that) {
case _CaptureConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int version,  List<String> bankingApps,  List<String> messagesApps,  List<String> smsSenderPatterns)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CaptureConfig() when $default != null:
return $default(_that.version,_that.bankingApps,_that.messagesApps,_that.smsSenderPatterns);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int version,  List<String> bankingApps,  List<String> messagesApps,  List<String> smsSenderPatterns)  $default,) {final _that = this;
switch (_that) {
case _CaptureConfig():
return $default(_that.version,_that.bankingApps,_that.messagesApps,_that.smsSenderPatterns);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int version,  List<String> bankingApps,  List<String> messagesApps,  List<String> smsSenderPatterns)?  $default,) {final _that = this;
switch (_that) {
case _CaptureConfig() when $default != null:
return $default(_that.version,_that.bankingApps,_that.messagesApps,_that.smsSenderPatterns);case _:
  return null;

}
}

}

/// @nodoc


class _CaptureConfig implements CaptureConfig {
  const _CaptureConfig({required this.version, required final  List<String> bankingApps, required final  List<String> messagesApps, required final  List<String> smsSenderPatterns}): _bankingApps = bankingApps,_messagesApps = messagesApps,_smsSenderPatterns = smsSenderPatterns;
  

@override final  int version;
 final  List<String> _bankingApps;
@override List<String> get bankingApps {
  if (_bankingApps is EqualUnmodifiableListView) return _bankingApps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bankingApps);
}

 final  List<String> _messagesApps;
@override List<String> get messagesApps {
  if (_messagesApps is EqualUnmodifiableListView) return _messagesApps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messagesApps);
}

/// Regex con flags en línea (`(?i)…`), aplicadas al título de la
/// notificación de Mensajes.
 final  List<String> _smsSenderPatterns;
/// Regex con flags en línea (`(?i)…`), aplicadas al título de la
/// notificación de Mensajes.
@override List<String> get smsSenderPatterns {
  if (_smsSenderPatterns is EqualUnmodifiableListView) return _smsSenderPatterns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_smsSenderPatterns);
}


/// Create a copy of CaptureConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CaptureConfigCopyWith<_CaptureConfig> get copyWith => __$CaptureConfigCopyWithImpl<_CaptureConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CaptureConfig&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other._bankingApps, _bankingApps)&&const DeepCollectionEquality().equals(other._messagesApps, _messagesApps)&&const DeepCollectionEquality().equals(other._smsSenderPatterns, _smsSenderPatterns));
}


@override
int get hashCode => Object.hash(runtimeType,version,const DeepCollectionEquality().hash(_bankingApps),const DeepCollectionEquality().hash(_messagesApps),const DeepCollectionEquality().hash(_smsSenderPatterns));

@override
String toString() {
  return 'CaptureConfig(version: $version, bankingApps: $bankingApps, messagesApps: $messagesApps, smsSenderPatterns: $smsSenderPatterns)';
}


}

/// @nodoc
abstract mixin class _$CaptureConfigCopyWith<$Res> implements $CaptureConfigCopyWith<$Res> {
  factory _$CaptureConfigCopyWith(_CaptureConfig value, $Res Function(_CaptureConfig) _then) = __$CaptureConfigCopyWithImpl;
@override @useResult
$Res call({
 int version, List<String> bankingApps, List<String> messagesApps, List<String> smsSenderPatterns
});




}
/// @nodoc
class __$CaptureConfigCopyWithImpl<$Res>
    implements _$CaptureConfigCopyWith<$Res> {
  __$CaptureConfigCopyWithImpl(this._self, this._then);

  final _CaptureConfig _self;
  final $Res Function(_CaptureConfig) _then;

/// Create a copy of CaptureConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? bankingApps = null,Object? messagesApps = null,Object? smsSenderPatterns = null,}) {
  return _then(_CaptureConfig(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,bankingApps: null == bankingApps ? _self._bankingApps : bankingApps // ignore: cast_nullable_to_non_nullable
as List<String>,messagesApps: null == messagesApps ? _self._messagesApps : messagesApps // ignore: cast_nullable_to_non_nullable
as List<String>,smsSenderPatterns: null == smsSenderPatterns ? _self._smsSenderPatterns : smsSenderPatterns // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
