import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:luka/features/nfc/data/ndef_uri.dart';
import 'package:luka/features/nfc/domain/nfc_ports.dart';
import 'package:ndef_record/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart' as nfc;
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

/// [NfcService] sobre `nfc_manager` (Android e iOS en primer plano).
///
/// Cada operación abre una sesión, atiende el primer tag y la cierra. En iOS
/// la sesión muestra la hoja del sistema con [_iosPrompt]; en Android el
/// lector queda activo mientras la pantalla de escritura está abierta.
class NfcManagerService implements NfcService {
  NfcManagerService({
    String iosPrompt = 'Acerca el tag a la parte de arriba del iPhone',
  }) : _iosPrompt = iosPrompt;

  final String _iosPrompt;
  Completer<Object?>? _pending;

  static const Set<nfc.NfcPollingOption> _polling = {
    nfc.NfcPollingOption.iso14443,
    nfc.NfcPollingOption.iso15693,
  };

  bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<NfcAvailability> availability() async {
    final value = await nfc.NfcManager.instance.checkAvailability();
    return switch (value) {
      nfc.NfcAvailability.enabled => NfcAvailability.enabled,
      nfc.NfcAvailability.disabled => NfcAvailability.disabled,
      nfc.NfcAvailability.unsupported => NfcAvailability.unsupported,
    };
  }

  @override
  Future<void> write(Uri uri) async {
    final message = NdefMessage(records: [uriRecord(uri)]);
    await _session((tag) async {
      if (_isIos) {
        final ndef = NdefIos.from(tag);
        if (ndef == null || ndef.status != NdefStatusIos.readWrite) {
          throw const NfcTagNotWritable();
        }
        if (message.byteLength > ndef.capacity) throw const NfcTagTooSmall();
        await ndef.writeNdef(message);
        return null;
      }
      final ndef = NdefAndroid.from(tag);
      if (ndef == null) {
        // Tag de fábrica sin formato NDEF: se formatea con el mensaje.
        final formatable = NdefFormatableAndroid.from(tag);
        if (formatable == null) throw const NfcTagNotWritable();
        await formatable.format(message);
        return null;
      }
      if (!ndef.isWritable) throw const NfcTagNotWritable();
      if (message.byteLength > ndef.maxSize) throw const NfcTagTooSmall();
      await ndef.writeNdefMessage(message);
      return null;
    });
  }

  @override
  Future<Uri?> readUri() async {
    final result = await _session((tag) async {
      final message = _isIos
          ? NdefIos.from(tag)?.cachedNdefMessage
          : NdefAndroid.from(tag)?.cachedNdefMessage;
      return firstUri(message);
    });
    return result as Uri?;
  }

  @override
  Future<void> cancel() async {
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(const NfcCancelled());
    }
    await nfc.NfcManager.instance.stopSession();
  }

  /// Abre una sesión, corre [onTag] con el primer tag y la cierra.
  Future<Object?> _session(Future<Object?> Function(nfc.NfcTag) onTag) async {
    final available = await availability();
    if (available != NfcAvailability.enabled) {
      throw NfcUnavailable(available);
    }
    await cancel();
    final done = _pending = Completer<Object?>();
    await nfc.NfcManager.instance.startSession(
      pollingOptions: _polling,
      alertMessageIos: _iosPrompt,
      onSessionErrorIos: (_) {
        if (!done.isCompleted) done.completeError(const NfcCancelled());
      },
      onDiscovered: (tag) async {
        try {
          final value = await onTag(tag);
          await nfc.NfcManager.instance.stopSession();
          if (!done.isCompleted) done.complete(value);
        } on NfcFailure catch (failure) {
          await nfc.NfcManager.instance.stopSession();
          if (!done.isCompleted) done.completeError(failure);
        } on Object {
          await nfc.NfcManager.instance.stopSession();
          if (!done.isCompleted) done.completeError(const NfcIoError());
        }
      },
    );
    try {
      return await done.future;
    } finally {
      if (identical(_pending, done)) _pending = null;
    }
  }
}
