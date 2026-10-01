import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luka/core/l10n/gen/app_localizations.dart';
import 'package:luka/core/theme/luka_colors.dart';
import 'package:luka/core/theme/tokens/spacing.dart';
import 'package:luka/features/nfc/application/nfc_actions.dart';
import 'package:luka/features/nfc/domain/nfc_ports.dart';
import 'package:luka/features/nfc/presentation/nfc_format.dart';

/// "Acerca el tag al teléfono" (diseño B "Escribir a pantalla completa",
/// F4.5b, AC-4.3): pantalla café que espera un tag y le escribe el
/// enlace de [template]. Muestra el resultado y deja reintentar.
class NfcWriteScreen extends ConsumerStatefulWidget {
  const NfcWriteScreen({required this.template, super.key});

  final NfcTagTemplate template;

  /// Abre la pantalla; `true` si el tag quedó escrito.
  static Future<bool> show(
    BuildContext context,
    NfcTagTemplate template,
  ) async =>
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => NfcWriteScreen(template: template),
        ),
      ) ??
      false;

  @override
  ConsumerState<NfcWriteScreen> createState() => _NfcWriteScreenState();
}

class _NfcWriteScreenState extends ConsumerState<NfcWriteScreen> {
  bool _done = false;
  NfcFailure? _failure;
  // Se guarda al iniciar: `ref` no se puede usar en dispose.
  late final NfcService _service;

  @override
  void initState() {
    super.initState();
    _service = ref.read(nfcServiceProvider);
    unawaited(_write());
  }

  @override
  void dispose() {
    if (!_done) unawaited(_service.cancel());
    super.dispose();
  }

  Future<void> _write() async {
    setState(() => _failure = null);
    try {
      await ref.read(nfcActionsProvider).writeTag(widget.template);
      if (mounted) setState(() => _done = true);
    } on NfcFailure catch (failure) {
      // Cancelar al salir no es un error que mostrar.
      if (mounted && failure is! NfcCancelled) {
        setState(() => _failure = failure);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = context.lukaColors;
    final textTheme = Theme.of(context).textTheme;
    final failure = _failure;
    final name = widget.template.name;
    final soft = brand.onHero.withValues(alpha: 0.85);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: brand.hero,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.lg,
              Space.md,
              Space.lg,
              Space.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Semantics(
                  liveRegion: true,
                  child: Column(
                    spacing: Space.lg,
                    children: [
                      ExcludeSemantics(
                        child: _Rings(
                          icon: _done
                              ? Icons.check_rounded
                              : failure != null
                              ? Icons.priority_high_rounded
                              : Icons.nfc_rounded,
                        ),
                      ),
                      Semantics(
                        header: true,
                        child: Text(
                          _done ? l10n.nfcWriteDoneTitle : l10n.nfcWriteTitle,
                          textAlign: TextAlign.center,
                          style: textTheme.headlineMedium?.copyWith(
                            color: brand.onHero,
                          ),
                        ),
                      ),
                      Text(
                        _done
                            ? l10n.nfcWriteDoneBody(name)
                            : failure != null
                            ? nfcFailureMessage(l10n, failure)
                            : l10n.nfcWriteBody(name),
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(color: soft),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_done)
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: brand.heroCard,
                      foregroundColor: brand.hero,
                    ),
                    child: Text(l10n.nfcWriteDone),
                  )
                else ...[
                  if (failure != null) ...[
                    FilledButton(
                      onPressed: () => unawaited(_write()),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: brand.heroCard,
                        foregroundColor: brand.hero,
                      ),
                      child: Text(l10n.nfcWriteRetry),
                    ),
                    const SizedBox(height: Space.sm),
                  ],
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: brand.onHero,
                      side: BorderSide(color: soft),
                    ),
                    child: Text(l10n.nfcWriteCancel),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ondas concéntricas con el ícono del estado.
class _Rings extends StatelessWidget {
  const _Rings({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final brand = context.lukaColors;
    final scheme = Theme.of(context).colorScheme;

    Widget ring(double size, double alpha, Widget child) => Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: brand.onHero.withValues(alpha: alpha),
          width: 2,
        ),
      ),
      child: child,
    );

    return ring(
      180,
      0.25,
      ring(
        128,
        0.5,
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: brand.heroChip,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 34, color: scheme.onPrimaryContainer),
        ),
      ),
    );
  }
}
