import 'package:flutter_test/flutter_test.dart';
import 'package:luka/core/format/money.dart';
import 'package:luka/features/recurring/domain/recurring_draft.dart';
import 'package:luka/features/recurring/domain/recurring_models.dart';

RecurringOccurrence _occurrence({
  OccurrenceStatus status = OccurrenceStatus.pending,
  DateTime? due,
}) => RecurringOccurrence(
  id: 'o-1',
  expenseId: 'e-1',
  name: 'Spotify',
  expectedAmount: Cop.pesos(16900),
  period: '2026-10',
  dueDate: due ?? DateTime.utc(2026, 10, 22),
  status: status,
);

void main() {
  group('occurrenceStateOf (spec 011 §2)', () {
    test('pendiente antes o el día del vencimiento es próximo', () {
      final occ = _occurrence();
      expect(
        occurrenceStateOf(occ, DateTime.utc(2026, 10, 21)),
        OccurrenceState.upcoming,
      );
      expect(
        occurrenceStateOf(occ, DateTime.utc(2026, 10, 22)),
        OccurrenceState.upcoming,
      );
    });

    test('vencida dentro de los 5 días es tarde; después, sin detectar', () {
      final occ = _occurrence();
      expect(
        occurrenceStateOf(occ, DateTime.utc(2026, 10, 23)),
        OccurrenceState.late,
      );
      expect(
        occurrenceStateOf(occ, DateTime.utc(2026, 10, 27)),
        OccurrenceState.late,
      );
      expect(
        occurrenceStateOf(occ, DateTime.utc(2026, 10, 28)),
        OccurrenceState.undetected,
      );
    });

    test('pagada y omitida no dependen de la fecha', () {
      final today = DateTime.utc(2026, 12);
      expect(
        occurrenceStateOf(_occurrence(status: OccurrenceStatus.paid), today),
        OccurrenceState.paid,
      );
      expect(
        occurrenceStateOf(_occurrence(status: OccurrenceStatus.skipped), today),
        OccurrenceState.skipped,
      );
    });

    test('status desconocido del backend cae en pendiente', () {
      expect(OccurrenceStatus.fromWire('paid'), OccurrenceStatus.paid);
      expect(OccurrenceStatus.fromWire('skipped'), OccurrenceStatus.skipped);
      expect(OccurrenceStatus.fromWire('otro'), OccurrenceStatus.pending);
    });
  });

  test('colombiaToday usa la fecha de Colombia (UTC−5)', () {
    // 03:00 UTC del 17 = 22:00 del 16 en Bogotá.
    expect(
      colombiaToday(DateTime.utc(2026, 10, 17, 3)),
      DateTime.utc(2026, 10, 16),
    );
    expect(periodOf(DateTime.utc(2026, 3, 5)), '2026-03');
  });

  group('RecurringDraft.validate', () {
    const ok = RecurringDraft(
      name: 'Spotify',
      expectedAmount: Cop(1690000),
      dayOfMonth: 22,
    );

    test('un borrador completo no tiene errores y limpia espacios', () {
      final draft = ok.copyWith(name: '  Spotify   Familiar ');
      expect(draft.validate(), isEmpty);
      expect(draft.cleanName, 'Spotify Familiar');
    });

    test('marca cada campo inválido', () {
      expect(
        ok.copyWith(name: '  ').validate(),
        contains(RecurringDraftError.nameRequired),
      );
      expect(
        ok.copyWith(name: 'x' * 61).validate(),
        contains(RecurringDraftError.nameTooLong),
      );
      // El nombre hace de palabra clave: necesita 2 letras o números.
      for (final name in ['x', '*-']) {
        expect(
          ok.copyWith(name: name).validate(),
          contains(RecurringDraftError.nameRequired),
        );
      }
      expect(
        ok.copyWith(expectedAmount: null).validate(),
        contains(RecurringDraftError.amountRequired),
      );
      expect(
        ok.copyWith(expectedAmount: const Cop(0)).validate(),
        contains(RecurringDraftError.amountRequired),
      );
      expect(
        ok.copyWith(dayOfMonth: 0).validate(),
        contains(RecurringDraftError.dayInvalid),
      );
      expect(
        ok.copyWith(dayOfMonth: 32).validate(),
        contains(RecurringDraftError.dayInvalid),
      );
    });

    test('fromExpense copia los campos editables', () {
      final draft = RecurringDraft.fromExpense(
        const RecurringExpense(
          id: 'e-1',
          name: 'Arriendo',
          merchantKeyword: 'INMOBILIARIA',
          expectedAmount: Cop(150000000),
          tolerancePct: 0,
          dayOfMonth: 5,
          remindDaysBefore: 2,
          active: true,
          categoryId: 'c-1',
          accountId: 'a-1',
        ),
      );
      expect(draft.name, 'Arriendo');
      expect(draft.remindDaysBefore, 2);
      expect(draft.accountId, 'a-1');
    });
  });
}
