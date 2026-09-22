import 'package:finanzia/app/app.dart';
import 'package:finanzia/app/composition.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(_fontLicenses);
  runApp(ProviderScope(overrides: appOverrides, child: const FinanziaApp()));
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
