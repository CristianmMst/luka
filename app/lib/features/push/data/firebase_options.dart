import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Opciones de Firebase del proyecto `luka-510204` (spec 011 §6). Son
/// identificadores públicos, no secretos (como el client ID de OAuth).
///
/// Mientras nadie corra `flutterfire configure --project=luka-510204` y pegue
/// aquí sus valores, devuelve `null`: la app funciona igual, solo sin
/// recordatorios push (el backend guarda los avisos en el stream).
FirebaseOptions? firebaseOptionsFor(TargetPlatform platform) =>
    switch (platform) {
      TargetPlatform.android => _android,
      TargetPlatform.iOS => _ios,
      _ => null,
    };

/// App Android `co.luka.luka`.
const FirebaseOptions? _android = null;

/// App iOS `co.luka.luka`.
const FirebaseOptions? _ios = null;
