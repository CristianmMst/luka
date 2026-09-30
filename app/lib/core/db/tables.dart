import 'package:drift/drift.dart';

/// Espejo local de `transactions` (spec 004 §5). `categoryId` y `fiscalTag`
/// son nulos solo en una creación local que el servidor aún no clasificó.
class LocalTransactions extends Table {
  TextColumn get id => text()();
  IntColumn get amountCents => integer()();
  TextColumn get currency => text()();
  TextColumn get direction => text()();
  TextColumn get kind => text()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get merchant => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get bank => text().nullable()();
  TextColumn get accountId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get fiscalTag => text().nullable()();
  TextColumn get transferPairId => text().nullable()();
  BoolColumn get transferAuto => boolean().withDefault(const Constant(false))();
  TextColumn get parsedBy => text()();
  RealColumn get confidence => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Tiene operaciones en el outbox: el pull no la sobrescribe (spec 003 §3).
  BoolColumn get pendingPush => boolean().withDefault(const Constant(false))();

  /// JSON de los canales de origen (`channels`, orden estable del enum
  /// `Channel`, spec 005 §6); `'[]'` para filas creadas en local antes del
  /// primer pull (F4.2).
  TextColumn get channels => text().withDefault(const Constant('[]'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalCategories extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get slug => text().nullable()();
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  TextColumn get fiscalTag => text()();
  BoolColumn get isSystem => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get bank => text()();
  TextColumn get kind => text()();
  TextColumn get last4 => text().nullable()();
  TextColumn get alias => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Ítems abiertos de la cola de revisión (spec 005 §7).
@DataClassName('LocalReviewRow')
class LocalReview extends Table {
  TextColumn get rawMessageId => text()();
  TextColumn get channel => text()();
  TextColumn get bank => text().nullable()();
  TextColumn get sender => text()();
  DateTimeColumn get receivedAt => dateTime()();
  TextColumn get reason => text()();

  /// JSON `{campo: valor}` de `partial_extract`.
  TextColumn get partialExtract => text()();
  TextColumn get messageText => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {rawMessageId};
}

/// Operaciones hechas sin red, en orden FIFO por `seq` (spec 005 §9).
/// Los índices sirven al canje de ids y a buscar las operaciones de una
/// fila.
@DataClassName('OutboxRow')
@TableIndex(name: 'outbox_target_id', columns: {#targetId})
@TableIndex(name: 'outbox_related_id', columns: {#relatedId})
class Outbox extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get kind => text()();

  /// Registro que toca la operación; se reescribe al canjear un id local.
  TextColumn get targetId => text()();
  TextColumn get relatedId => text().nullable()();

  /// Campos de la operación sin ids (JSON).
  TextColumn get payload => text()();
  TextColumn get idempotencyKey => text()();

  /// `pending` o `rejected` (resolución manual).
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Cursores y metadatos de sync (`transactions_cursor`, `last_synced_at`,
/// `owner_user_id`).
@DataClassName('SyncStateRow')
class SyncState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Plantillas de tags NFC (spec 006 §5, F4.5b): solo locales, no se
/// sincronizan. Un tag escrito en otro teléfono no se encuentra aquí.
@DataClassName('LocalNfcTagRow')
class LocalNfcTags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get accountId => text().nullable()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Gastos fijos del usuario (spec 004 §5, F7.6): snapshot completo en cada
/// sync.
@DataClassName('LocalRecurringExpenseRow')
class LocalRecurringExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get merchantKeyword => text()();
  IntColumn get expectedAmountCents => integer()();
  IntColumn get tolerancePct => integer()();
  IntColumn get dayOfMonth => integer()();
  IntColumn get remindDaysBefore => integer()();
  BoolColumn get active => boolean()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get accountId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Ocurrencias del mes anterior al siguiente (spec 004 §5, F7.6). El nombre
/// y el monto esperado se leen del gasto fijo; `period` es `AAAA-MM` y
/// `due_date` `AAAA-MM-DD`, como los manda la API.
@DataClassName('LocalRecurringOccurrenceRow')
class LocalRecurringOccurrences extends Table {
  TextColumn get id => text()();
  TextColumn get expenseId => text()();
  TextColumn get period => text()();
  TextColumn get dueDate => text()();
  TextColumn get status => text()();
  TextColumn get matchedBy => text().nullable()();
  DateTimeColumn get paidAt => dateTime().nullable()();
  TextColumn get transactionId => text().nullable()();
  TextColumn get transactionMerchant => text().nullable()();
  IntColumn get transactionAmountCents => integer().nullable()();
  DateTimeColumn get transactionOccurredAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
