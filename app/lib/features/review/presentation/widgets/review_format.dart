import 'package:finanzia/core/format/money.dart';
import 'package:finanzia/core/l10n/gen/app_localizations.dart';
import 'package:finanzia/core/theme/tokens/type_tokens.dart';
import 'package:finanzia/features/review/domain/amount_highlight.dart';
import 'package:finanzia/features/review/domain/review_item.dart';
import 'package:finanzia/features/transactions/presentation/widgets/transaction_format.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Presentación compartida de la lista y el detalle de Revisión: motivo,
/// canal, origen, montos resaltados y el campo de monto.

/// Motivo legible del fallo (`reason` del backend, spec 008 §3.5).
String reasonLabel(AppLocalizations l10n, String reason) => switch (reason) {
  'no_template' => l10n.reviewReasonNoTemplate,
  'llm_disabled' => l10n.reviewReasonLlmDisabled,
  'llm_invalid_output' ||
  'llm_low_confidence' => l10n.reviewReasonLlmUnreliable,
  _ => l10n.reviewReasonOther,
};

IconData reviewChannelIcon(String channel) => switch (channel) {
  'email' => Icons.mail_outline_rounded,
  'notification' => Icons.notifications_none_rounded,
  _ => Icons.help_outline_rounded,
};

String reviewChannelName(AppLocalizations l10n, String channel) =>
    switch (channel) {
      'email' => l10n.channelEmail,
      'notification' => l10n.channelNotification,
      _ => channel,
    };

/// El banco del mensaje, o su remitente si no se reconoció el banco.
String reviewSource(AppLocalizations l10n, ReviewItem item) =>
    switch (item.bank) {
      final bank? when bank.isNotEmpty => bankLabel(l10n, bank),
      _ => item.sender,
    };

/// Texto en una sola línea lógica (sin saltos ni espacios repetidos), para
/// el extracto de la lista.
String collapseWhitespace(String text) =>
    text.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Estilo del monto resaltado: fondo `primaryContainer` y la fuente mono,
/// con contraste AA sobre la tarjeta.
TextStyle highlightStyle(ColorScheme scheme) => amountTextStyle.copyWith(
  color: scheme.onPrimaryContainer,
  backgroundColor: scheme.primaryContainer,
);

/// [text] como spans, con los montos de [highlightAmounts] resaltados. Con
/// [onAmount], tocar un monto lo entrega ya convertido en [Cop]; los
/// reconocedores quedan en [recognizers] para que quien los crea los
/// libere.
List<InlineSpan> highlightedSpans(
  AppLocalizations l10n,
  String text,
  TextStyle highlight, {
  ValueChanged<Cop>? onAmount,
  List<GestureRecognizer>? recognizers,
}) {
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final range in highlightAmounts(text)) {
    if (range.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, range.start)));
    }
    final raw = text.substring(range.start, range.end);
    final amount = parseAmount(raw)!;
    TapGestureRecognizer? recognizer;
    if (onAmount != null) {
      recognizer = TapGestureRecognizer()..onTap = () => onAmount(amount);
      recognizers?.add(recognizer);
    }
    spans.add(
      TextSpan(
        text: raw,
        style: highlight,
        recognizer: recognizer,
        semanticsLabel: l10n.reviewAmountSemantics(spokenAmount(amount)),
      ),
    );
    cursor = range.end;
  }
  if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
  return spans;
}

/// Montos distintos de [text], en orden de aparición.
List<Cop> distinctAmounts(String text) => {
  for (final range in highlightAmounts(text))
    ?parseAmount(text.substring(range.start, range.end)),
}.toList();

/// `126.400` o `126.400,50` para el lector de pantalla.
String spokenAmount(Cop amount) =>
    spokenNumber(amount, withDecimals: amount.cents % 100 != 0);

// ------------------------------------------------------------ campo monto

/// Texto del campo de monto para [amount]: `126.400` o `126.400,50`.
String copInputText(Cop amount) => spokenAmount(amount);

/// Monto escrito en el campo (`126.400`, `126.400,5`); `null` si está vacío
/// o no es un monto.
Cop? parseCopInput(String text) {
  var clean = text.replaceAll('.', '').replaceAll(',', '.').trim();
  if (clean.endsWith('.')) clean = clean.substring(0, clean.length - 1);
  if (clean.isEmpty) return null;
  try {
    return Cop.parse(clean);
  } on FormatException {
    return null;
  }
}

/// Escribe el monto con puntos de miles mientras se teclea y admite una
/// coma decimal con hasta dos cifras (formato es-CO). Un punto tecleado
/// cuenta como la coma: hay teclados numéricos que solo traen punto.
class CopInputFormatter extends TextInputFormatter {
  const CopInputFormatter();

  static const _maxDigits = 12;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var raw = newValue.text;
    final typedDot =
        raw.length == oldValue.text.length + 1 &&
        newValue.selection.baseOffset > 0 &&
        raw[newValue.selection.baseOffset - 1] == '.';
    if (typedDot) {
      final at = newValue.selection.baseOffset - 1;
      raw = '${raw.substring(0, at)},${raw.substring(at + 1)}';
    }
    final text = format(raw);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// `1234567,891` → `1.234.567,89`; los puntos se toman como miles.
  static String format(String raw) {
    final comma = raw.indexOf(',');
    final whole = comma < 0 ? raw : raw.substring(0, comma);
    var digits = whole
        .replaceAll(RegExp(r'\D'), '')
        .replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (digits.length > _maxDigits) digits = digits.substring(0, _maxDigits);
    final grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    if (comma < 0) return grouped;
    final decimals = raw.substring(comma + 1).replaceAll(RegExp(r'\D'), '');
    final cut = decimals.length > 2 ? decimals.substring(0, 2) : decimals;
    return '${grouped.isEmpty ? '0' : grouped},$cut';
  }
}
