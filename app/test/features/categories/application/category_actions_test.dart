import 'package:finanzia/features/categories/application/category_actions.dart';
import 'package:finanzia/features/categories/domain/categories_ports.dart';
import 'package:finanzia/features/categories/domain/category_draft.dart';
import 'package:finanzia/features/sync/domain/synced_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements CategoriesRemote {}

class _MockStore extends Mock implements CategoriesStore {}

const _mascotas = SyncedCategory(
  id: 'c-1',
  name: 'Mascotas',
  fiscalTag: 'no_deducible',
  isSystem: false,
  userId: 'u-1',
  icon: 'pets',
  color: '#6B4C9A',
);

void main() {
  late _MockRemote remote;
  late _MockStore store;
  late int syncs;
  late CategoryActions actions;

  setUpAll(() {
    registerFallbackValue(const CategoryDraft(name: 'x'));
    registerFallbackValue(_mascotas);
  });

  setUp(() {
    remote = _MockRemote();
    store = _MockStore();
    syncs = 0;
    when(() => store.upsert(any())).thenAnswer((_) async {});
    when(() => store.remove(any())).thenAnswer((_) async {});
    actions = CategoryActions(
      remote: remote,
      store: store,
      requestSync: () => syncs++,
    );
  });

  test('crear guarda en local lo que devolvió el servidor', () async {
    when(() => remote.create(any())).thenAnswer((_) async => _mascotas);

    final created = await actions.create(
      const CategoryDraft(name: '  Mascotas ', icon: 'pets', color: '#6B4C9A'),
    );

    expect(created, _mascotas);
    final sent =
        verify(() => remote.create(captureAny())).captured.single
            as CategoryDraft;
    expect(sent.name, 'Mascotas');
    verify(() => store.upsert(_mascotas)).called(1);
    expect(syncs, 0);
  });

  test('un borrador inválido no llega al servidor', () async {
    await expectLater(
      actions.create(const CategoryDraft(name: ' ')),
      throwsA(
        isA<InvalidCategoryDraft>().having(
          (e) => e.errors,
          'errors',
          {CategoryDraftError.nameRequired},
        ),
      ),
    );
    verifyNever(() => remote.create(any()));
  });

  test('un fallo del servidor se propaga sin tocar la base local', () async {
    when(
      () => remote.create(any()),
    ).thenThrow(const CategoryDuplicateName());

    await expectLater(
      actions.create(const CategoryDraft(name: 'Donaciones')),
      throwsA(isA<CategoryDuplicateName>()),
    );
    verifyNever(() => store.upsert(any()));
  });

  test('editar guarda y pide sync (pudo cambiar movimientos)', () async {
    when(() => remote.update(any(), any())).thenAnswer((_) async => _mascotas);

    await actions.update('c-1', const CategoryDraft(name: 'Mascotas'));

    verify(() => store.upsert(_mascotas)).called(1);
    expect(syncs, 1);
  });

  test('borrar quita en local y pide sync', () async {
    when(() => remote.delete(any())).thenAnswer((_) async {});

    await actions.delete('c-1');

    verify(() => remote.delete('c-1')).called(1);
    verify(() => store.remove('c-1')).called(1);
    expect(syncs, 1);
  });

  test('si borrar falla, no se toca la base local', () async {
    when(() => remote.delete(any())).thenThrow(const CategoryOffline());

    await expectLater(actions.delete('c-1'), throwsA(isA<CategoryOffline>()));
    verifyNever(() => store.remove(any()));
    expect(syncs, 0);
  });

  test('ownCategoriesProvider lee la base local', () async {
    const own = OwnCategory(
      id: 'c-1',
      name: 'Mascotas',
      fiscalTag: 'no_deducible',
      transactionCount: 3,
    );
    when(() => store.watchOwn()).thenAnswer((_) => Stream.value([own]));
    final container = ProviderContainer(
      overrides: [categoriesStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(ownCategoriesProvider, (_, _) {});
    addTearDown(sub.close);

    expect(await container.read(ownCategoriesProvider.future), [own]);
  });
}
