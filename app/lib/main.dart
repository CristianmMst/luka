import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/app/app.dart';
import 'package:luka/app/composition.dart';
import 'package:luka/features/push/data/firebase_push_service.dart';
import 'package:luka/features/push/data/push_data_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(_fontLicenses);
  // Sin opciones de Firebase la app arranca igual, sin push (spec 011 §6).
  final firebaseReady = await initFirebase();
  runApp(
    ProviderScope(
      overrides: [
        ...appOverrides,
        firebaseReadyProvider.overrideWithValue(firebaseReady),
      ],
      child: const LukaApp(),
    ),
  );
}

/// Licencias OFL de las fuentes empaquetadas (pantalla de licencias).
Stream<LicenseEntry> _fontLicenses() async* {
  const fonts = {
    'BricolageGrotesque': 'bricolagegrotesque',
    'Manrope': 'manrope',
    'IBMPlexMono': 'ibmplexmono',
    'Roboto': 'roboto',
  };
  for (final MapEntry(key: family, value: file) in fonts.entries) {
    final text = await rootBundle.loadString(
      'assets/fonts/licenses/$file-OFL.txt',
    );
    yield LicenseEntryWithLineBreaks([family], text);
  }
}
