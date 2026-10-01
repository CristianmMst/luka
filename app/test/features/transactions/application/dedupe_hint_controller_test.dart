import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luka/features/transactions/application/dedupe_hint_controller.dart';
import 'package:luka/features/transactions/domain/dedupe_hint_store.dart';
import 'package:mocktail/mocktail.dart';

class _Store extends Mock implements DedupeHintStore {}

void main() {
  late _Store store;
  late ProviderContainer container;

  setUp(() {
    store = _Store();
    container = ProviderContainer(
      overrides: [dedupeHintStoreProvider.overrideWithValue(store)],
    );
  });

  tearDown(() => container.dispose());

  test('se muestra mientras no se haya descartado', () async {
    when(() => store.wasDismissed()).thenAnswer((_) async => false);

    expect(await container.read(dedupeHintControllerProvider.future), isTrue);
  });

  test('no se muestra si ya se descartó', () async {
    when(() => store.wasDismissed()).thenAnswer((_) async => true);

    expect(await container.read(dedupeHintControllerProvider.future), isFalse);
  });

  test('descartar lo oculta al instante y lo guarda', () async {
    when(() => store.wasDismissed()).thenAnswer((_) async => false);
    when(() => store.dismiss()).thenAnswer((_) async {});
    await container.read(dedupeHintControllerProvider.future);

    await container.read(dedupeHintControllerProvider.notifier).dismiss();

    expect(container.read(dedupeHintControllerProvider).value, isFalse);
    verify(() => store.dismiss()).called(1);
  });

  test('si la base local falla, no se muestra', () async {
    when(() => store.wasDismissed()).thenThrow(StateError('db'));

    expect(await container.read(dedupeHintControllerProvider.future), isFalse);
  });
}
