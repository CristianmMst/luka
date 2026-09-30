// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalTransactionsTable extends LocalTransactions
    with TableInfo<$LocalTransactionsTable, LocalTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _merchantMeta = const VerificationMeta(
    'merchant',
  );
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
    'merchant',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bankMeta = const VerificationMeta('bank');
  @override
  late final GeneratedColumn<String> bank = GeneratedColumn<String>(
    'bank',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fiscalTagMeta = const VerificationMeta(
    'fiscalTag',
  );
  @override
  late final GeneratedColumn<String> fiscalTag = GeneratedColumn<String>(
    'fiscal_tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transferPairIdMeta = const VerificationMeta(
    'transferPairId',
  );
  @override
  late final GeneratedColumn<String> transferPairId = GeneratedColumn<String>(
    'transfer_pair_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transferAutoMeta = const VerificationMeta(
    'transferAuto',
  );
  @override
  late final GeneratedColumn<bool> transferAuto = GeneratedColumn<bool>(
    'transfer_auto',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("transfer_auto" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _parsedByMeta = const VerificationMeta(
    'parsedBy',
  );
  @override
  late final GeneratedColumn<String> parsedBy = GeneratedColumn<String>(
    'parsed_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pendingPushMeta = const VerificationMeta(
    'pendingPush',
  );
  @override
  late final GeneratedColumn<bool> pendingPush = GeneratedColumn<bool>(
    'pending_push',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_push" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _channelsMeta = const VerificationMeta(
    'channels',
  );
  @override
  late final GeneratedColumn<String> channels = GeneratedColumn<String>(
    'channels',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    amountCents,
    currency,
    direction,
    kind,
    occurredAt,
    merchant,
    description,
    bank,
    accountId,
    categoryId,
    fiscalTag,
    transferPairId,
    transferAuto,
    parsedBy,
    confidence,
    notes,
    createdAt,
    updatedAt,
    pendingPush,
    channels,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('merchant')) {
      context.handle(
        _merchantMeta,
        merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('bank')) {
      context.handle(
        _bankMeta,
        bank.isAcceptableOrUnknown(data['bank']!, _bankMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('fiscal_tag')) {
      context.handle(
        _fiscalTagMeta,
        fiscalTag.isAcceptableOrUnknown(data['fiscal_tag']!, _fiscalTagMeta),
      );
    }
    if (data.containsKey('transfer_pair_id')) {
      context.handle(
        _transferPairIdMeta,
        transferPairId.isAcceptableOrUnknown(
          data['transfer_pair_id']!,
          _transferPairIdMeta,
        ),
      );
    }
    if (data.containsKey('transfer_auto')) {
      context.handle(
        _transferAutoMeta,
        transferAuto.isAcceptableOrUnknown(
          data['transfer_auto']!,
          _transferAutoMeta,
        ),
      );
    }
    if (data.containsKey('parsed_by')) {
      context.handle(
        _parsedByMeta,
        parsedBy.isAcceptableOrUnknown(data['parsed_by']!, _parsedByMeta),
      );
    } else if (isInserting) {
      context.missing(_parsedByMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('pending_push')) {
      context.handle(
        _pendingPushMeta,
        pendingPush.isAcceptableOrUnknown(
          data['pending_push']!,
          _pendingPushMeta,
        ),
      );
    }
    if (data.containsKey('channels')) {
      context.handle(
        _channelsMeta,
        channels.isAcceptableOrUnknown(data['channels']!, _channelsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      merchant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      bank: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      fiscalTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fiscal_tag'],
      ),
      transferPairId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_pair_id'],
      ),
      transferAuto: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}transfer_auto'],
      )!,
      parsedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parsed_by'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pendingPush: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_push'],
      )!,
      channels: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channels'],
      )!,
    );
  }

  @override
  $LocalTransactionsTable createAlias(String alias) {
    return $LocalTransactionsTable(attachedDatabase, alias);
  }
}

class LocalTransaction extends DataClass
    implements Insertable<LocalTransaction> {
  final String id;
  final int amountCents;
  final String currency;
  final String direction;
  final String kind;
  final DateTime occurredAt;
  final String? merchant;
  final String? description;
  final String? bank;
  final String? accountId;
  final String? categoryId;
  final String? fiscalTag;
  final String? transferPairId;
  final bool transferAuto;
  final String parsedBy;
  final double? confidence;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Tiene operaciones en el outbox: el pull no la sobrescribe (spec 003 §3).
  final bool pendingPush;

  /// JSON de los canales de origen (`channels`, orden estable del enum
  /// `Channel`, spec 005 §6); `'[]'` para filas creadas en local antes del
  /// primer pull (F4.2).
  final String channels;
  const LocalTransaction({
    required this.id,
    required this.amountCents,
    required this.currency,
    required this.direction,
    required this.kind,
    required this.occurredAt,
    this.merchant,
    this.description,
    this.bank,
    this.accountId,
    this.categoryId,
    this.fiscalTag,
    this.transferPairId,
    required this.transferAuto,
    required this.parsedBy,
    this.confidence,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.pendingPush,
    required this.channels,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['amount_cents'] = Variable<int>(amountCents);
    map['currency'] = Variable<String>(currency);
    map['direction'] = Variable<String>(direction);
    map['kind'] = Variable<String>(kind);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || merchant != null) {
      map['merchant'] = Variable<String>(merchant);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || bank != null) {
      map['bank'] = Variable<String>(bank);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || fiscalTag != null) {
      map['fiscal_tag'] = Variable<String>(fiscalTag);
    }
    if (!nullToAbsent || transferPairId != null) {
      map['transfer_pair_id'] = Variable<String>(transferPairId);
    }
    map['transfer_auto'] = Variable<bool>(transferAuto);
    map['parsed_by'] = Variable<String>(parsedBy);
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending_push'] = Variable<bool>(pendingPush);
    map['channels'] = Variable<String>(channels);
    return map;
  }

  LocalTransactionsCompanion toCompanion(bool nullToAbsent) {
    return LocalTransactionsCompanion(
      id: Value(id),
      amountCents: Value(amountCents),
      currency: Value(currency),
      direction: Value(direction),
      kind: Value(kind),
      occurredAt: Value(occurredAt),
      merchant: merchant == null && nullToAbsent
          ? const Value.absent()
          : Value(merchant),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      bank: bank == null && nullToAbsent ? const Value.absent() : Value(bank),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      fiscalTag: fiscalTag == null && nullToAbsent
          ? const Value.absent()
          : Value(fiscalTag),
      transferPairId: transferPairId == null && nullToAbsent
          ? const Value.absent()
          : Value(transferPairId),
      transferAuto: Value(transferAuto),
      parsedBy: Value(parsedBy),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      pendingPush: Value(pendingPush),
      channels: Value(channels),
    );
  }

  factory LocalTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTransaction(
      id: serializer.fromJson<String>(json['id']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      currency: serializer.fromJson<String>(json['currency']),
      direction: serializer.fromJson<String>(json['direction']),
      kind: serializer.fromJson<String>(json['kind']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      merchant: serializer.fromJson<String?>(json['merchant']),
      description: serializer.fromJson<String?>(json['description']),
      bank: serializer.fromJson<String?>(json['bank']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      fiscalTag: serializer.fromJson<String?>(json['fiscalTag']),
      transferPairId: serializer.fromJson<String?>(json['transferPairId']),
      transferAuto: serializer.fromJson<bool>(json['transferAuto']),
      parsedBy: serializer.fromJson<String>(json['parsedBy']),
      confidence: serializer.fromJson<double?>(json['confidence']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pendingPush: serializer.fromJson<bool>(json['pendingPush']),
      channels: serializer.fromJson<String>(json['channels']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'amountCents': serializer.toJson<int>(amountCents),
      'currency': serializer.toJson<String>(currency),
      'direction': serializer.toJson<String>(direction),
      'kind': serializer.toJson<String>(kind),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'merchant': serializer.toJson<String?>(merchant),
      'description': serializer.toJson<String?>(description),
      'bank': serializer.toJson<String?>(bank),
      'accountId': serializer.toJson<String?>(accountId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'fiscalTag': serializer.toJson<String?>(fiscalTag),
      'transferPairId': serializer.toJson<String?>(transferPairId),
      'transferAuto': serializer.toJson<bool>(transferAuto),
      'parsedBy': serializer.toJson<String>(parsedBy),
      'confidence': serializer.toJson<double?>(confidence),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pendingPush': serializer.toJson<bool>(pendingPush),
      'channels': serializer.toJson<String>(channels),
    };
  }

  LocalTransaction copyWith({
    String? id,
    int? amountCents,
    String? currency,
    String? direction,
    String? kind,
    DateTime? occurredAt,
    Value<String?> merchant = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> bank = const Value.absent(),
    Value<String?> accountId = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> fiscalTag = const Value.absent(),
    Value<String?> transferPairId = const Value.absent(),
    bool? transferAuto,
    String? parsedBy,
    Value<double?> confidence = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pendingPush,
    String? channels,
  }) => LocalTransaction(
    id: id ?? this.id,
    amountCents: amountCents ?? this.amountCents,
    currency: currency ?? this.currency,
    direction: direction ?? this.direction,
    kind: kind ?? this.kind,
    occurredAt: occurredAt ?? this.occurredAt,
    merchant: merchant.present ? merchant.value : this.merchant,
    description: description.present ? description.value : this.description,
    bank: bank.present ? bank.value : this.bank,
    accountId: accountId.present ? accountId.value : this.accountId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    fiscalTag: fiscalTag.present ? fiscalTag.value : this.fiscalTag,
    transferPairId: transferPairId.present
        ? transferPairId.value
        : this.transferPairId,
    transferAuto: transferAuto ?? this.transferAuto,
    parsedBy: parsedBy ?? this.parsedBy,
    confidence: confidence.present ? confidence.value : this.confidence,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingPush: pendingPush ?? this.pendingPush,
    channels: channels ?? this.channels,
  );
  LocalTransaction copyWithCompanion(LocalTransactionsCompanion data) {
    return LocalTransaction(
      id: data.id.present ? data.id.value : this.id,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      currency: data.currency.present ? data.currency.value : this.currency,
      direction: data.direction.present ? data.direction.value : this.direction,
      kind: data.kind.present ? data.kind.value : this.kind,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      description: data.description.present
          ? data.description.value
          : this.description,
      bank: data.bank.present ? data.bank.value : this.bank,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      fiscalTag: data.fiscalTag.present ? data.fiscalTag.value : this.fiscalTag,
      transferPairId: data.transferPairId.present
          ? data.transferPairId.value
          : this.transferPairId,
      transferAuto: data.transferAuto.present
          ? data.transferAuto.value
          : this.transferAuto,
      parsedBy: data.parsedBy.present ? data.parsedBy.value : this.parsedBy,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingPush: data.pendingPush.present
          ? data.pendingPush.value
          : this.pendingPush,
      channels: data.channels.present ? data.channels.value : this.channels,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTransaction(')
          ..write('id: $id, ')
          ..write('amountCents: $amountCents, ')
          ..write('currency: $currency, ')
          ..write('direction: $direction, ')
          ..write('kind: $kind, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('merchant: $merchant, ')
          ..write('description: $description, ')
          ..write('bank: $bank, ')
          ..write('accountId: $accountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('fiscalTag: $fiscalTag, ')
          ..write('transferPairId: $transferPairId, ')
          ..write('transferAuto: $transferAuto, ')
          ..write('parsedBy: $parsedBy, ')
          ..write('confidence: $confidence, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingPush: $pendingPush, ')
          ..write('channels: $channels')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    amountCents,
    currency,
    direction,
    kind,
    occurredAt,
    merchant,
    description,
    bank,
    accountId,
    categoryId,
    fiscalTag,
    transferPairId,
    transferAuto,
    parsedBy,
    confidence,
    notes,
    createdAt,
    updatedAt,
    pendingPush,
    channels,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTransaction &&
          other.id == this.id &&
          other.amountCents == this.amountCents &&
          other.currency == this.currency &&
          other.direction == this.direction &&
          other.kind == this.kind &&
          other.occurredAt == this.occurredAt &&
          other.merchant == this.merchant &&
          other.description == this.description &&
          other.bank == this.bank &&
          other.accountId == this.accountId &&
          other.categoryId == this.categoryId &&
          other.fiscalTag == this.fiscalTag &&
          other.transferPairId == this.transferPairId &&
          other.transferAuto == this.transferAuto &&
          other.parsedBy == this.parsedBy &&
          other.confidence == this.confidence &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.pendingPush == this.pendingPush &&
          other.channels == this.channels);
}

class LocalTransactionsCompanion extends UpdateCompanion<LocalTransaction> {
  final Value<String> id;
  final Value<int> amountCents;
  final Value<String> currency;
  final Value<String> direction;
  final Value<String> kind;
  final Value<DateTime> occurredAt;
  final Value<String?> merchant;
  final Value<String?> description;
  final Value<String?> bank;
  final Value<String?> accountId;
  final Value<String?> categoryId;
  final Value<String?> fiscalTag;
  final Value<String?> transferPairId;
  final Value<bool> transferAuto;
  final Value<String> parsedBy;
  final Value<double?> confidence;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> pendingPush;
  final Value<String> channels;
  final Value<int> rowid;
  const LocalTransactionsCompanion({
    this.id = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.currency = const Value.absent(),
    this.direction = const Value.absent(),
    this.kind = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.merchant = const Value.absent(),
    this.description = const Value.absent(),
    this.bank = const Value.absent(),
    this.accountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.fiscalTag = const Value.absent(),
    this.transferPairId = const Value.absent(),
    this.transferAuto = const Value.absent(),
    this.parsedBy = const Value.absent(),
    this.confidence = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingPush = const Value.absent(),
    this.channels = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTransactionsCompanion.insert({
    required String id,
    required int amountCents,
    required String currency,
    required String direction,
    required String kind,
    required DateTime occurredAt,
    this.merchant = const Value.absent(),
    this.description = const Value.absent(),
    this.bank = const Value.absent(),
    this.accountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.fiscalTag = const Value.absent(),
    this.transferPairId = const Value.absent(),
    this.transferAuto = const Value.absent(),
    required String parsedBy,
    this.confidence = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.pendingPush = const Value.absent(),
    this.channels = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       amountCents = Value(amountCents),
       currency = Value(currency),
       direction = Value(direction),
       kind = Value(kind),
       occurredAt = Value(occurredAt),
       parsedBy = Value(parsedBy),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalTransaction> custom({
    Expression<String>? id,
    Expression<int>? amountCents,
    Expression<String>? currency,
    Expression<String>? direction,
    Expression<String>? kind,
    Expression<DateTime>? occurredAt,
    Expression<String>? merchant,
    Expression<String>? description,
    Expression<String>? bank,
    Expression<String>? accountId,
    Expression<String>? categoryId,
    Expression<String>? fiscalTag,
    Expression<String>? transferPairId,
    Expression<bool>? transferAuto,
    Expression<String>? parsedBy,
    Expression<double>? confidence,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pendingPush,
    Expression<String>? channels,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amountCents != null) 'amount_cents': amountCents,
      if (currency != null) 'currency': currency,
      if (direction != null) 'direction': direction,
      if (kind != null) 'kind': kind,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (merchant != null) 'merchant': merchant,
      if (description != null) 'description': description,
      if (bank != null) 'bank': bank,
      if (accountId != null) 'account_id': accountId,
      if (categoryId != null) 'category_id': categoryId,
      if (fiscalTag != null) 'fiscal_tag': fiscalTag,
      if (transferPairId != null) 'transfer_pair_id': transferPairId,
      if (transferAuto != null) 'transfer_auto': transferAuto,
      if (parsedBy != null) 'parsed_by': parsedBy,
      if (confidence != null) 'confidence': confidence,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingPush != null) 'pending_push': pendingPush,
      if (channels != null) 'channels': channels,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTransactionsCompanion copyWith({
    Value<String>? id,
    Value<int>? amountCents,
    Value<String>? currency,
    Value<String>? direction,
    Value<String>? kind,
    Value<DateTime>? occurredAt,
    Value<String?>? merchant,
    Value<String?>? description,
    Value<String?>? bank,
    Value<String?>? accountId,
    Value<String?>? categoryId,
    Value<String?>? fiscalTag,
    Value<String?>? transferPairId,
    Value<bool>? transferAuto,
    Value<String>? parsedBy,
    Value<double?>? confidence,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? pendingPush,
    Value<String>? channels,
    Value<int>? rowid,
  }) {
    return LocalTransactionsCompanion(
      id: id ?? this.id,
      amountCents: amountCents ?? this.amountCents,
      currency: currency ?? this.currency,
      direction: direction ?? this.direction,
      kind: kind ?? this.kind,
      occurredAt: occurredAt ?? this.occurredAt,
      merchant: merchant ?? this.merchant,
      description: description ?? this.description,
      bank: bank ?? this.bank,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      fiscalTag: fiscalTag ?? this.fiscalTag,
      transferPairId: transferPairId ?? this.transferPairId,
      transferAuto: transferAuto ?? this.transferAuto,
      parsedBy: parsedBy ?? this.parsedBy,
      confidence: confidence ?? this.confidence,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingPush: pendingPush ?? this.pendingPush,
      channels: channels ?? this.channels,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (bank.present) {
      map['bank'] = Variable<String>(bank.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (fiscalTag.present) {
      map['fiscal_tag'] = Variable<String>(fiscalTag.value);
    }
    if (transferPairId.present) {
      map['transfer_pair_id'] = Variable<String>(transferPairId.value);
    }
    if (transferAuto.present) {
      map['transfer_auto'] = Variable<bool>(transferAuto.value);
    }
    if (parsedBy.present) {
      map['parsed_by'] = Variable<String>(parsedBy.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pendingPush.present) {
      map['pending_push'] = Variable<bool>(pendingPush.value);
    }
    if (channels.present) {
      map['channels'] = Variable<String>(channels.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('amountCents: $amountCents, ')
          ..write('currency: $currency, ')
          ..write('direction: $direction, ')
          ..write('kind: $kind, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('merchant: $merchant, ')
          ..write('description: $description, ')
          ..write('bank: $bank, ')
          ..write('accountId: $accountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('fiscalTag: $fiscalTag, ')
          ..write('transferPairId: $transferPairId, ')
          ..write('transferAuto: $transferAuto, ')
          ..write('parsedBy: $parsedBy, ')
          ..write('confidence: $confidence, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingPush: $pendingPush, ')
          ..write('channels: $channels, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCategoriesTable extends LocalCategories
    with TableInfo<$LocalCategoriesTable, LocalCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fiscalTagMeta = const VerificationMeta(
    'fiscalTag',
  );
  @override
  late final GeneratedColumn<String> fiscalTag = GeneratedColumn<String>(
    'fiscal_tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSystemMeta = const VerificationMeta(
    'isSystem',
  );
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
    'is_system',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    slug,
    name,
    icon,
    color,
    fiscalTag,
    isSystem,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('fiscal_tag')) {
      context.handle(
        _fiscalTagMeta,
        fiscalTag.isAcceptableOrUnknown(data['fiscal_tag']!, _fiscalTagMeta),
      );
    } else if (isInserting) {
      context.missing(_fiscalTagMeta);
    }
    if (data.containsKey('is_system')) {
      context.handle(
        _isSystemMeta,
        isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta),
      );
    } else if (isInserting) {
      context.missing(_isSystemMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      fiscalTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fiscal_tag'],
      )!,
      isSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system'],
      )!,
    );
  }

  @override
  $LocalCategoriesTable createAlias(String alias) {
    return $LocalCategoriesTable(attachedDatabase, alias);
  }
}

class LocalCategory extends DataClass implements Insertable<LocalCategory> {
  final String id;
  final String? userId;
  final String? slug;
  final String name;
  final String? icon;
  final String? color;
  final String fiscalTag;
  final bool isSystem;
  const LocalCategory({
    required this.id,
    this.userId,
    this.slug,
    required this.name,
    this.icon,
    this.color,
    required this.fiscalTag,
    required this.isSystem,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || slug != null) {
      map['slug'] = Variable<String>(slug);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['fiscal_tag'] = Variable<String>(fiscalTag);
    map['is_system'] = Variable<bool>(isSystem);
    return map;
  }

  LocalCategoriesCompanion toCompanion(bool nullToAbsent) {
    return LocalCategoriesCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      slug: slug == null && nullToAbsent ? const Value.absent() : Value(slug),
      name: Value(name),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      fiscalTag: Value(fiscalTag),
      isSystem: Value(isSystem),
    );
  }

  factory LocalCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCategory(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      slug: serializer.fromJson<String?>(json['slug']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String?>(json['icon']),
      color: serializer.fromJson<String?>(json['color']),
      fiscalTag: serializer.fromJson<String>(json['fiscalTag']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String?>(userId),
      'slug': serializer.toJson<String?>(slug),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String?>(icon),
      'color': serializer.toJson<String?>(color),
      'fiscalTag': serializer.toJson<String>(fiscalTag),
      'isSystem': serializer.toJson<bool>(isSystem),
    };
  }

  LocalCategory copyWith({
    String? id,
    Value<String?> userId = const Value.absent(),
    Value<String?> slug = const Value.absent(),
    String? name,
    Value<String?> icon = const Value.absent(),
    Value<String?> color = const Value.absent(),
    String? fiscalTag,
    bool? isSystem,
  }) => LocalCategory(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    slug: slug.present ? slug.value : this.slug,
    name: name ?? this.name,
    icon: icon.present ? icon.value : this.icon,
    color: color.present ? color.value : this.color,
    fiscalTag: fiscalTag ?? this.fiscalTag,
    isSystem: isSystem ?? this.isSystem,
  );
  LocalCategory copyWithCompanion(LocalCategoriesCompanion data) {
    return LocalCategory(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      slug: data.slug.present ? data.slug.value : this.slug,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      fiscalTag: data.fiscalTag.present ? data.fiscalTag.value : this.fiscalTag,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCategory(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('slug: $slug, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('fiscalTag: $fiscalTag, ')
          ..write('isSystem: $isSystem')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, slug, name, icon, color, fiscalTag, isSystem);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCategory &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.slug == this.slug &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.fiscalTag == this.fiscalTag &&
          other.isSystem == this.isSystem);
}

class LocalCategoriesCompanion extends UpdateCompanion<LocalCategory> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String?> slug;
  final Value<String> name;
  final Value<String?> icon;
  final Value<String?> color;
  final Value<String> fiscalTag;
  final Value<bool> isSystem;
  final Value<int> rowid;
  const LocalCategoriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.slug = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.fiscalTag = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCategoriesCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    this.slug = const Value.absent(),
    required String name,
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    required String fiscalTag,
    required bool isSystem,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       fiscalTag = Value(fiscalTag),
       isSystem = Value(isSystem);
  static Insertable<LocalCategory> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? slug,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<String>? color,
    Expression<String>? fiscalTag,
    Expression<bool>? isSystem,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (slug != null) 'slug': slug,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (fiscalTag != null) 'fiscal_tag': fiscalTag,
      if (isSystem != null) 'is_system': isSystem,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String?>? userId,
    Value<String?>? slug,
    Value<String>? name,
    Value<String?>? icon,
    Value<String?>? color,
    Value<String>? fiscalTag,
    Value<bool>? isSystem,
    Value<int>? rowid,
  }) {
    return LocalCategoriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      fiscalTag: fiscalTag ?? this.fiscalTag,
      isSystem: isSystem ?? this.isSystem,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (fiscalTag.present) {
      map['fiscal_tag'] = Variable<String>(fiscalTag.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('slug: $slug, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('fiscalTag: $fiscalTag, ')
          ..write('isSystem: $isSystem, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalAccountsTable extends LocalAccounts
    with TableInfo<$LocalAccountsTable, LocalAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankMeta = const VerificationMeta('bank');
  @override
  late final GeneratedColumn<String> bank = GeneratedColumn<String>(
    'bank',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _last4Meta = const VerificationMeta('last4');
  @override
  late final GeneratedColumn<String> last4 = GeneratedColumn<String>(
    'last4',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aliasMeta = const VerificationMeta('alias');
  @override
  late final GeneratedColumn<String> alias = GeneratedColumn<String>(
    'alias',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, bank, kind, last4, alias];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bank')) {
      context.handle(
        _bankMeta,
        bank.isAcceptableOrUnknown(data['bank']!, _bankMeta),
      );
    } else if (isInserting) {
      context.missing(_bankMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('last4')) {
      context.handle(
        _last4Meta,
        last4.isAcceptableOrUnknown(data['last4']!, _last4Meta),
      );
    }
    if (data.containsKey('alias')) {
      context.handle(
        _aliasMeta,
        alias.isAcceptableOrUnknown(data['alias']!, _aliasMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAccount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bank: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      last4: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last4'],
      ),
      alias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alias'],
      ),
    );
  }

  @override
  $LocalAccountsTable createAlias(String alias) {
    return $LocalAccountsTable(attachedDatabase, alias);
  }
}

class LocalAccount extends DataClass implements Insertable<LocalAccount> {
  final String id;
  final String bank;
  final String kind;
  final String? last4;
  final String? alias;
  const LocalAccount({
    required this.id,
    required this.bank,
    required this.kind,
    this.last4,
    this.alias,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bank'] = Variable<String>(bank);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || last4 != null) {
      map['last4'] = Variable<String>(last4);
    }
    if (!nullToAbsent || alias != null) {
      map['alias'] = Variable<String>(alias);
    }
    return map;
  }

  LocalAccountsCompanion toCompanion(bool nullToAbsent) {
    return LocalAccountsCompanion(
      id: Value(id),
      bank: Value(bank),
      kind: Value(kind),
      last4: last4 == null && nullToAbsent
          ? const Value.absent()
          : Value(last4),
      alias: alias == null && nullToAbsent
          ? const Value.absent()
          : Value(alias),
    );
  }

  factory LocalAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAccount(
      id: serializer.fromJson<String>(json['id']),
      bank: serializer.fromJson<String>(json['bank']),
      kind: serializer.fromJson<String>(json['kind']),
      last4: serializer.fromJson<String?>(json['last4']),
      alias: serializer.fromJson<String?>(json['alias']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bank': serializer.toJson<String>(bank),
      'kind': serializer.toJson<String>(kind),
      'last4': serializer.toJson<String?>(last4),
      'alias': serializer.toJson<String?>(alias),
    };
  }

  LocalAccount copyWith({
    String? id,
    String? bank,
    String? kind,
    Value<String?> last4 = const Value.absent(),
    Value<String?> alias = const Value.absent(),
  }) => LocalAccount(
    id: id ?? this.id,
    bank: bank ?? this.bank,
    kind: kind ?? this.kind,
    last4: last4.present ? last4.value : this.last4,
    alias: alias.present ? alias.value : this.alias,
  );
  LocalAccount copyWithCompanion(LocalAccountsCompanion data) {
    return LocalAccount(
      id: data.id.present ? data.id.value : this.id,
      bank: data.bank.present ? data.bank.value : this.bank,
      kind: data.kind.present ? data.kind.value : this.kind,
      last4: data.last4.present ? data.last4.value : this.last4,
      alias: data.alias.present ? data.alias.value : this.alias,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAccount(')
          ..write('id: $id, ')
          ..write('bank: $bank, ')
          ..write('kind: $kind, ')
          ..write('last4: $last4, ')
          ..write('alias: $alias')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, bank, kind, last4, alias);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAccount &&
          other.id == this.id &&
          other.bank == this.bank &&
          other.kind == this.kind &&
          other.last4 == this.last4 &&
          other.alias == this.alias);
}

class LocalAccountsCompanion extends UpdateCompanion<LocalAccount> {
  final Value<String> id;
  final Value<String> bank;
  final Value<String> kind;
  final Value<String?> last4;
  final Value<String?> alias;
  final Value<int> rowid;
  const LocalAccountsCompanion({
    this.id = const Value.absent(),
    this.bank = const Value.absent(),
    this.kind = const Value.absent(),
    this.last4 = const Value.absent(),
    this.alias = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalAccountsCompanion.insert({
    required String id,
    required String bank,
    required String kind,
    this.last4 = const Value.absent(),
    this.alias = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bank = Value(bank),
       kind = Value(kind);
  static Insertable<LocalAccount> custom({
    Expression<String>? id,
    Expression<String>? bank,
    Expression<String>? kind,
    Expression<String>? last4,
    Expression<String>? alias,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bank != null) 'bank': bank,
      if (kind != null) 'kind': kind,
      if (last4 != null) 'last4': last4,
      if (alias != null) 'alias': alias,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalAccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? bank,
    Value<String>? kind,
    Value<String?>? last4,
    Value<String?>? alias,
    Value<int>? rowid,
  }) {
    return LocalAccountsCompanion(
      id: id ?? this.id,
      bank: bank ?? this.bank,
      kind: kind ?? this.kind,
      last4: last4 ?? this.last4,
      alias: alias ?? this.alias,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bank.present) {
      map['bank'] = Variable<String>(bank.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (last4.present) {
      map['last4'] = Variable<String>(last4.value);
    }
    if (alias.present) {
      map['alias'] = Variable<String>(alias.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAccountsCompanion(')
          ..write('id: $id, ')
          ..write('bank: $bank, ')
          ..write('kind: $kind, ')
          ..write('last4: $last4, ')
          ..write('alias: $alias, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalReviewTable extends LocalReview
    with TableInfo<$LocalReviewTable, LocalReviewRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalReviewTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rawMessageIdMeta = const VerificationMeta(
    'rawMessageId',
  );
  @override
  late final GeneratedColumn<String> rawMessageId = GeneratedColumn<String>(
    'raw_message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelMeta = const VerificationMeta(
    'channel',
  );
  @override
  late final GeneratedColumn<String> channel = GeneratedColumn<String>(
    'channel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankMeta = const VerificationMeta('bank');
  @override
  late final GeneratedColumn<String> bank = GeneratedColumn<String>(
    'bank',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
    'sender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partialExtractMeta = const VerificationMeta(
    'partialExtract',
  );
  @override
  late final GeneratedColumn<String> partialExtract = GeneratedColumn<String>(
    'partial_extract',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageTextMeta = const VerificationMeta(
    'messageText',
  );
  @override
  late final GeneratedColumn<String> messageText = GeneratedColumn<String>(
    'message_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    rawMessageId,
    channel,
    bank,
    sender,
    receivedAt,
    reason,
    partialExtract,
    messageText,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_review';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalReviewRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('raw_message_id')) {
      context.handle(
        _rawMessageIdMeta,
        rawMessageId.isAcceptableOrUnknown(
          data['raw_message_id']!,
          _rawMessageIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rawMessageIdMeta);
    }
    if (data.containsKey('channel')) {
      context.handle(
        _channelMeta,
        channel.isAcceptableOrUnknown(data['channel']!, _channelMeta),
      );
    } else if (isInserting) {
      context.missing(_channelMeta);
    }
    if (data.containsKey('bank')) {
      context.handle(
        _bankMeta,
        bank.isAcceptableOrUnknown(data['bank']!, _bankMeta),
      );
    }
    if (data.containsKey('sender')) {
      context.handle(
        _senderMeta,
        sender.isAcceptableOrUnknown(data['sender']!, _senderMeta),
      );
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('partial_extract')) {
      context.handle(
        _partialExtractMeta,
        partialExtract.isAcceptableOrUnknown(
          data['partial_extract']!,
          _partialExtractMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_partialExtractMeta);
    }
    if (data.containsKey('message_text')) {
      context.handle(
        _messageTextMeta,
        messageText.isAcceptableOrUnknown(
          data['message_text']!,
          _messageTextMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rawMessageId};
  @override
  LocalReviewRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalReviewRow(
      rawMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_message_id'],
      )!,
      channel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel'],
      )!,
      bank: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank'],
      ),
      sender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender'],
      )!,
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      partialExtract: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}partial_extract'],
      )!,
      messageText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_text'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalReviewTable createAlias(String alias) {
    return $LocalReviewTable(attachedDatabase, alias);
  }
}

class LocalReviewRow extends DataClass implements Insertable<LocalReviewRow> {
  final String rawMessageId;
  final String channel;
  final String? bank;
  final String sender;
  final DateTime receivedAt;
  final String reason;

  /// JSON `{campo: valor}` de `partial_extract`.
  final String partialExtract;
  final String? messageText;
  final DateTime createdAt;
  const LocalReviewRow({
    required this.rawMessageId,
    required this.channel,
    this.bank,
    required this.sender,
    required this.receivedAt,
    required this.reason,
    required this.partialExtract,
    this.messageText,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['raw_message_id'] = Variable<String>(rawMessageId);
    map['channel'] = Variable<String>(channel);
    if (!nullToAbsent || bank != null) {
      map['bank'] = Variable<String>(bank);
    }
    map['sender'] = Variable<String>(sender);
    map['received_at'] = Variable<DateTime>(receivedAt);
    map['reason'] = Variable<String>(reason);
    map['partial_extract'] = Variable<String>(partialExtract);
    if (!nullToAbsent || messageText != null) {
      map['message_text'] = Variable<String>(messageText);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalReviewCompanion toCompanion(bool nullToAbsent) {
    return LocalReviewCompanion(
      rawMessageId: Value(rawMessageId),
      channel: Value(channel),
      bank: bank == null && nullToAbsent ? const Value.absent() : Value(bank),
      sender: Value(sender),
      receivedAt: Value(receivedAt),
      reason: Value(reason),
      partialExtract: Value(partialExtract),
      messageText: messageText == null && nullToAbsent
          ? const Value.absent()
          : Value(messageText),
      createdAt: Value(createdAt),
    );
  }

  factory LocalReviewRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalReviewRow(
      rawMessageId: serializer.fromJson<String>(json['rawMessageId']),
      channel: serializer.fromJson<String>(json['channel']),
      bank: serializer.fromJson<String?>(json['bank']),
      sender: serializer.fromJson<String>(json['sender']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      reason: serializer.fromJson<String>(json['reason']),
      partialExtract: serializer.fromJson<String>(json['partialExtract']),
      messageText: serializer.fromJson<String?>(json['messageText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rawMessageId': serializer.toJson<String>(rawMessageId),
      'channel': serializer.toJson<String>(channel),
      'bank': serializer.toJson<String?>(bank),
      'sender': serializer.toJson<String>(sender),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'reason': serializer.toJson<String>(reason),
      'partialExtract': serializer.toJson<String>(partialExtract),
      'messageText': serializer.toJson<String?>(messageText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalReviewRow copyWith({
    String? rawMessageId,
    String? channel,
    Value<String?> bank = const Value.absent(),
    String? sender,
    DateTime? receivedAt,
    String? reason,
    String? partialExtract,
    Value<String?> messageText = const Value.absent(),
    DateTime? createdAt,
  }) => LocalReviewRow(
    rawMessageId: rawMessageId ?? this.rawMessageId,
    channel: channel ?? this.channel,
    bank: bank.present ? bank.value : this.bank,
    sender: sender ?? this.sender,
    receivedAt: receivedAt ?? this.receivedAt,
    reason: reason ?? this.reason,
    partialExtract: partialExtract ?? this.partialExtract,
    messageText: messageText.present ? messageText.value : this.messageText,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalReviewRow copyWithCompanion(LocalReviewCompanion data) {
    return LocalReviewRow(
      rawMessageId: data.rawMessageId.present
          ? data.rawMessageId.value
          : this.rawMessageId,
      channel: data.channel.present ? data.channel.value : this.channel,
      bank: data.bank.present ? data.bank.value : this.bank,
      sender: data.sender.present ? data.sender.value : this.sender,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      reason: data.reason.present ? data.reason.value : this.reason,
      partialExtract: data.partialExtract.present
          ? data.partialExtract.value
          : this.partialExtract,
      messageText: data.messageText.present
          ? data.messageText.value
          : this.messageText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalReviewRow(')
          ..write('rawMessageId: $rawMessageId, ')
          ..write('channel: $channel, ')
          ..write('bank: $bank, ')
          ..write('sender: $sender, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('reason: $reason, ')
          ..write('partialExtract: $partialExtract, ')
          ..write('messageText: $messageText, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rawMessageId,
    channel,
    bank,
    sender,
    receivedAt,
    reason,
    partialExtract,
    messageText,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalReviewRow &&
          other.rawMessageId == this.rawMessageId &&
          other.channel == this.channel &&
          other.bank == this.bank &&
          other.sender == this.sender &&
          other.receivedAt == this.receivedAt &&
          other.reason == this.reason &&
          other.partialExtract == this.partialExtract &&
          other.messageText == this.messageText &&
          other.createdAt == this.createdAt);
}

class LocalReviewCompanion extends UpdateCompanion<LocalReviewRow> {
  final Value<String> rawMessageId;
  final Value<String> channel;
  final Value<String?> bank;
  final Value<String> sender;
  final Value<DateTime> receivedAt;
  final Value<String> reason;
  final Value<String> partialExtract;
  final Value<String?> messageText;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalReviewCompanion({
    this.rawMessageId = const Value.absent(),
    this.channel = const Value.absent(),
    this.bank = const Value.absent(),
    this.sender = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.reason = const Value.absent(),
    this.partialExtract = const Value.absent(),
    this.messageText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalReviewCompanion.insert({
    required String rawMessageId,
    required String channel,
    this.bank = const Value.absent(),
    required String sender,
    required DateTime receivedAt,
    required String reason,
    required String partialExtract,
    this.messageText = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : rawMessageId = Value(rawMessageId),
       channel = Value(channel),
       sender = Value(sender),
       receivedAt = Value(receivedAt),
       reason = Value(reason),
       partialExtract = Value(partialExtract),
       createdAt = Value(createdAt);
  static Insertable<LocalReviewRow> custom({
    Expression<String>? rawMessageId,
    Expression<String>? channel,
    Expression<String>? bank,
    Expression<String>? sender,
    Expression<DateTime>? receivedAt,
    Expression<String>? reason,
    Expression<String>? partialExtract,
    Expression<String>? messageText,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (rawMessageId != null) 'raw_message_id': rawMessageId,
      if (channel != null) 'channel': channel,
      if (bank != null) 'bank': bank,
      if (sender != null) 'sender': sender,
      if (receivedAt != null) 'received_at': receivedAt,
      if (reason != null) 'reason': reason,
      if (partialExtract != null) 'partial_extract': partialExtract,
      if (messageText != null) 'message_text': messageText,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalReviewCompanion copyWith({
    Value<String>? rawMessageId,
    Value<String>? channel,
    Value<String?>? bank,
    Value<String>? sender,
    Value<DateTime>? receivedAt,
    Value<String>? reason,
    Value<String>? partialExtract,
    Value<String?>? messageText,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalReviewCompanion(
      rawMessageId: rawMessageId ?? this.rawMessageId,
      channel: channel ?? this.channel,
      bank: bank ?? this.bank,
      sender: sender ?? this.sender,
      receivedAt: receivedAt ?? this.receivedAt,
      reason: reason ?? this.reason,
      partialExtract: partialExtract ?? this.partialExtract,
      messageText: messageText ?? this.messageText,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rawMessageId.present) {
      map['raw_message_id'] = Variable<String>(rawMessageId.value);
    }
    if (channel.present) {
      map['channel'] = Variable<String>(channel.value);
    }
    if (bank.present) {
      map['bank'] = Variable<String>(bank.value);
    }
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (partialExtract.present) {
      map['partial_extract'] = Variable<String>(partialExtract.value);
    }
    if (messageText.present) {
      map['message_text'] = Variable<String>(messageText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalReviewCompanion(')
          ..write('rawMessageId: $rawMessageId, ')
          ..write('channel: $channel, ')
          ..write('bank: $bank, ')
          ..write('sender: $sender, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('reason: $reason, ')
          ..write('partialExtract: $partialExtract, ')
          ..write('messageText: $messageText, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relatedIdMeta = const VerificationMeta(
    'relatedId',
  );
  @override
  late final GeneratedColumn<String> relatedId = GeneratedColumn<String>(
    'related_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    kind,
    targetId,
    relatedId,
    payload,
    idempotencyKey,
    status,
    attempts,
    lastError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('related_id')) {
      context.handle(
        _relatedIdMeta,
        relatedId.isAcceptableOrUnknown(data['related_id']!, _relatedIdMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
      relatedId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_id'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final int seq;
  final String kind;

  /// Registro que toca la operación; se reescribe al canjear un id local.
  final String targetId;
  final String? relatedId;

  /// Campos de la operación sin ids (JSON).
  final String payload;
  final String idempotencyKey;

  /// `pending` o `rejected` (resolución manual).
  final String status;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;
  const OutboxRow({
    required this.seq,
    required this.kind,
    required this.targetId,
    this.relatedId,
    required this.payload,
    required this.idempotencyKey,
    required this.status,
    required this.attempts,
    this.lastError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['kind'] = Variable<String>(kind);
    map['target_id'] = Variable<String>(targetId);
    if (!nullToAbsent || relatedId != null) {
      map['related_id'] = Variable<String>(relatedId);
    }
    map['payload'] = Variable<String>(payload);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      seq: Value(seq),
      kind: Value(kind),
      targetId: Value(targetId),
      relatedId: relatedId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedId),
      payload: Value(payload),
      idempotencyKey: Value(idempotencyKey),
      status: Value(status),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      seq: serializer.fromJson<int>(json['seq']),
      kind: serializer.fromJson<String>(json['kind']),
      targetId: serializer.fromJson<String>(json['targetId']),
      relatedId: serializer.fromJson<String?>(json['relatedId']),
      payload: serializer.fromJson<String>(json['payload']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'kind': serializer.toJson<String>(kind),
      'targetId': serializer.toJson<String>(targetId),
      'relatedId': serializer.toJson<String?>(relatedId),
      'payload': serializer.toJson<String>(payload),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OutboxRow copyWith({
    int? seq,
    String? kind,
    String? targetId,
    Value<String?> relatedId = const Value.absent(),
    String? payload,
    String? idempotencyKey,
    String? status,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
  }) => OutboxRow(
    seq: seq ?? this.seq,
    kind: kind ?? this.kind,
    targetId: targetId ?? this.targetId,
    relatedId: relatedId.present ? relatedId.value : this.relatedId,
    payload: payload ?? this.payload,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxRow copyWithCompanion(OutboxCompanion data) {
    return OutboxRow(
      seq: data.seq.present ? data.seq.value : this.seq,
      kind: data.kind.present ? data.kind.value : this.kind,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      relatedId: data.relatedId.present ? data.relatedId.value : this.relatedId,
      payload: data.payload.present ? data.payload.value : this.payload,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('seq: $seq, ')
          ..write('kind: $kind, ')
          ..write('targetId: $targetId, ')
          ..write('relatedId: $relatedId, ')
          ..write('payload: $payload, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    seq,
    kind,
    targetId,
    relatedId,
    payload,
    idempotencyKey,
    status,
    attempts,
    lastError,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.seq == this.seq &&
          other.kind == this.kind &&
          other.targetId == this.targetId &&
          other.relatedId == this.relatedId &&
          other.payload == this.payload &&
          other.idempotencyKey == this.idempotencyKey &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class OutboxCompanion extends UpdateCompanion<OutboxRow> {
  final Value<int> seq;
  final Value<String> kind;
  final Value<String> targetId;
  final Value<String?> relatedId;
  final Value<String> payload;
  final Value<String> idempotencyKey;
  final Value<String> status;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  const OutboxCompanion({
    this.seq = const Value.absent(),
    this.kind = const Value.absent(),
    this.targetId = const Value.absent(),
    this.relatedId = const Value.absent(),
    this.payload = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OutboxCompanion.insert({
    this.seq = const Value.absent(),
    required String kind,
    required String targetId,
    this.relatedId = const Value.absent(),
    required String payload,
    required String idempotencyKey,
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
  }) : kind = Value(kind),
       targetId = Value(targetId),
       payload = Value(payload),
       idempotencyKey = Value(idempotencyKey),
       createdAt = Value(createdAt);
  static Insertable<OutboxRow> custom({
    Expression<int>? seq,
    Expression<String>? kind,
    Expression<String>? targetId,
    Expression<String>? relatedId,
    Expression<String>? payload,
    Expression<String>? idempotencyKey,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (kind != null) 'kind': kind,
      if (targetId != null) 'target_id': targetId,
      if (relatedId != null) 'related_id': relatedId,
      if (payload != null) 'payload': payload,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OutboxCompanion copyWith({
    Value<int>? seq,
    Value<String>? kind,
    Value<String>? targetId,
    Value<String?>? relatedId,
    Value<String>? payload,
    Value<String>? idempotencyKey,
    Value<String>? status,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
  }) {
    return OutboxCompanion(
      seq: seq ?? this.seq,
      kind: kind ?? this.kind,
      targetId: targetId ?? this.targetId,
      relatedId: relatedId ?? this.relatedId,
      payload: payload ?? this.payload,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (relatedId.present) {
      map['related_id'] = Variable<String>(relatedId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('seq: $seq, ')
          ..write('kind: $kind, ')
          ..write('targetId: $targetId, ')
          ..write('relatedId: $relatedId, ')
          ..write('payload: $payload, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  final String key;
  final String value;
  const SyncStateRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(key: Value(key), value: Value(value));
  }

  factory SyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncStateRow copyWith({String? key, String? value}) =>
      SyncStateRow(key: key ?? this.key, value: value ?? this.value);
  SyncStateRow copyWithCompanion(SyncStateCompanion data) {
    return SyncStateRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncStateRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalNfcTagsTable extends LocalNfcTags
    with TableInfo<$LocalNfcTagsTable, LocalNfcTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalNfcTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, categoryId, accountId, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_nfc_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalNfcTagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalNfcTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalNfcTagRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $LocalNfcTagsTable createAlias(String alias) {
    return $LocalNfcTagsTable(attachedDatabase, alias);
  }
}

class LocalNfcTagRow extends DataClass implements Insertable<LocalNfcTagRow> {
  final String id;
  final String name;
  final String? categoryId;
  final String? accountId;
  final String? note;
  const LocalNfcTagRow({
    required this.id,
    required this.name,
    this.categoryId,
    this.accountId,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  LocalNfcTagsCompanion toCompanion(bool nullToAbsent) {
    return LocalNfcTagsCompanion(
      id: Value(id),
      name: Value(name),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory LocalNfcTagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalNfcTagRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'categoryId': serializer.toJson<String?>(categoryId),
      'accountId': serializer.toJson<String?>(accountId),
      'note': serializer.toJson<String?>(note),
    };
  }

  LocalNfcTagRow copyWith({
    String? id,
    String? name,
    Value<String?> categoryId = const Value.absent(),
    Value<String?> accountId = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => LocalNfcTagRow(
    id: id ?? this.id,
    name: name ?? this.name,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    accountId: accountId.present ? accountId.value : this.accountId,
    note: note.present ? note.value : this.note,
  );
  LocalNfcTagRow copyWithCompanion(LocalNfcTagsCompanion data) {
    return LocalNfcTagRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalNfcTagRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, categoryId, accountId, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalNfcTagRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.categoryId == this.categoryId &&
          other.accountId == this.accountId &&
          other.note == this.note);
}

class LocalNfcTagsCompanion extends UpdateCompanion<LocalNfcTagRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> categoryId;
  final Value<String?> accountId;
  final Value<String?> note;
  final Value<int> rowid;
  const LocalNfcTagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalNfcTagsCompanion.insert({
    required String id,
    required String name,
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<LocalNfcTagRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? categoryId,
    Expression<String>? accountId,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (categoryId != null) 'category_id': categoryId,
      if (accountId != null) 'account_id': accountId,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalNfcTagsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? categoryId,
    Value<String?>? accountId,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return LocalNfcTagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalNfcTagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalRecurringExpensesTable extends LocalRecurringExpenses
    with TableInfo<$LocalRecurringExpensesTable, LocalRecurringExpenseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalRecurringExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _merchantKeywordMeta = const VerificationMeta(
    'merchantKeyword',
  );
  @override
  late final GeneratedColumn<String> merchantKeyword = GeneratedColumn<String>(
    'merchant_keyword',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expectedAmountCentsMeta =
      const VerificationMeta('expectedAmountCents');
  @override
  late final GeneratedColumn<int> expectedAmountCents = GeneratedColumn<int>(
    'expected_amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tolerancePctMeta = const VerificationMeta(
    'tolerancePct',
  );
  @override
  late final GeneratedColumn<int> tolerancePct = GeneratedColumn<int>(
    'tolerance_pct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayOfMonthMeta = const VerificationMeta(
    'dayOfMonth',
  );
  @override
  late final GeneratedColumn<int> dayOfMonth = GeneratedColumn<int>(
    'day_of_month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remindDaysBeforeMeta = const VerificationMeta(
    'remindDaysBefore',
  );
  @override
  late final GeneratedColumn<int> remindDaysBefore = GeneratedColumn<int>(
    'remind_days_before',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    merchantKeyword,
    expectedAmountCents,
    tolerancePct,
    dayOfMonth,
    remindDaysBefore,
    active,
    categoryId,
    accountId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_recurring_expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalRecurringExpenseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('merchant_keyword')) {
      context.handle(
        _merchantKeywordMeta,
        merchantKeyword.isAcceptableOrUnknown(
          data['merchant_keyword']!,
          _merchantKeywordMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_merchantKeywordMeta);
    }
    if (data.containsKey('expected_amount_cents')) {
      context.handle(
        _expectedAmountCentsMeta,
        expectedAmountCents.isAcceptableOrUnknown(
          data['expected_amount_cents']!,
          _expectedAmountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expectedAmountCentsMeta);
    }
    if (data.containsKey('tolerance_pct')) {
      context.handle(
        _tolerancePctMeta,
        tolerancePct.isAcceptableOrUnknown(
          data['tolerance_pct']!,
          _tolerancePctMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tolerancePctMeta);
    }
    if (data.containsKey('day_of_month')) {
      context.handle(
        _dayOfMonthMeta,
        dayOfMonth.isAcceptableOrUnknown(
          data['day_of_month']!,
          _dayOfMonthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dayOfMonthMeta);
    }
    if (data.containsKey('remind_days_before')) {
      context.handle(
        _remindDaysBeforeMeta,
        remindDaysBefore.isAcceptableOrUnknown(
          data['remind_days_before']!,
          _remindDaysBeforeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remindDaysBeforeMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalRecurringExpenseRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalRecurringExpenseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      merchantKeyword: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant_keyword'],
      )!,
      expectedAmountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_amount_cents'],
      )!,
      tolerancePct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tolerance_pct'],
      )!,
      dayOfMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_month'],
      )!,
      remindDaysBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remind_days_before'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
    );
  }

  @override
  $LocalRecurringExpensesTable createAlias(String alias) {
    return $LocalRecurringExpensesTable(attachedDatabase, alias);
  }
}

class LocalRecurringExpenseRow extends DataClass
    implements Insertable<LocalRecurringExpenseRow> {
  final String id;
  final String name;
  final String merchantKeyword;
  final int expectedAmountCents;
  final int tolerancePct;
  final int dayOfMonth;
  final int remindDaysBefore;
  final bool active;
  final String? categoryId;
  final String? accountId;
  const LocalRecurringExpenseRow({
    required this.id,
    required this.name,
    required this.merchantKeyword,
    required this.expectedAmountCents,
    required this.tolerancePct,
    required this.dayOfMonth,
    required this.remindDaysBefore,
    required this.active,
    this.categoryId,
    this.accountId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['merchant_keyword'] = Variable<String>(merchantKeyword);
    map['expected_amount_cents'] = Variable<int>(expectedAmountCents);
    map['tolerance_pct'] = Variable<int>(tolerancePct);
    map['day_of_month'] = Variable<int>(dayOfMonth);
    map['remind_days_before'] = Variable<int>(remindDaysBefore);
    map['active'] = Variable<bool>(active);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    return map;
  }

  LocalRecurringExpensesCompanion toCompanion(bool nullToAbsent) {
    return LocalRecurringExpensesCompanion(
      id: Value(id),
      name: Value(name),
      merchantKeyword: Value(merchantKeyword),
      expectedAmountCents: Value(expectedAmountCents),
      tolerancePct: Value(tolerancePct),
      dayOfMonth: Value(dayOfMonth),
      remindDaysBefore: Value(remindDaysBefore),
      active: Value(active),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
    );
  }

  factory LocalRecurringExpenseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalRecurringExpenseRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      merchantKeyword: serializer.fromJson<String>(json['merchantKeyword']),
      expectedAmountCents: serializer.fromJson<int>(
        json['expectedAmountCents'],
      ),
      tolerancePct: serializer.fromJson<int>(json['tolerancePct']),
      dayOfMonth: serializer.fromJson<int>(json['dayOfMonth']),
      remindDaysBefore: serializer.fromJson<int>(json['remindDaysBefore']),
      active: serializer.fromJson<bool>(json['active']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      accountId: serializer.fromJson<String?>(json['accountId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'merchantKeyword': serializer.toJson<String>(merchantKeyword),
      'expectedAmountCents': serializer.toJson<int>(expectedAmountCents),
      'tolerancePct': serializer.toJson<int>(tolerancePct),
      'dayOfMonth': serializer.toJson<int>(dayOfMonth),
      'remindDaysBefore': serializer.toJson<int>(remindDaysBefore),
      'active': serializer.toJson<bool>(active),
      'categoryId': serializer.toJson<String?>(categoryId),
      'accountId': serializer.toJson<String?>(accountId),
    };
  }

  LocalRecurringExpenseRow copyWith({
    String? id,
    String? name,
    String? merchantKeyword,
    int? expectedAmountCents,
    int? tolerancePct,
    int? dayOfMonth,
    int? remindDaysBefore,
    bool? active,
    Value<String?> categoryId = const Value.absent(),
    Value<String?> accountId = const Value.absent(),
  }) => LocalRecurringExpenseRow(
    id: id ?? this.id,
    name: name ?? this.name,
    merchantKeyword: merchantKeyword ?? this.merchantKeyword,
    expectedAmountCents: expectedAmountCents ?? this.expectedAmountCents,
    tolerancePct: tolerancePct ?? this.tolerancePct,
    dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
    active: active ?? this.active,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    accountId: accountId.present ? accountId.value : this.accountId,
  );
  LocalRecurringExpenseRow copyWithCompanion(
    LocalRecurringExpensesCompanion data,
  ) {
    return LocalRecurringExpenseRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      merchantKeyword: data.merchantKeyword.present
          ? data.merchantKeyword.value
          : this.merchantKeyword,
      expectedAmountCents: data.expectedAmountCents.present
          ? data.expectedAmountCents.value
          : this.expectedAmountCents,
      tolerancePct: data.tolerancePct.present
          ? data.tolerancePct.value
          : this.tolerancePct,
      dayOfMonth: data.dayOfMonth.present
          ? data.dayOfMonth.value
          : this.dayOfMonth,
      remindDaysBefore: data.remindDaysBefore.present
          ? data.remindDaysBefore.value
          : this.remindDaysBefore,
      active: data.active.present ? data.active.value : this.active,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalRecurringExpenseRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('merchantKeyword: $merchantKeyword, ')
          ..write('expectedAmountCents: $expectedAmountCents, ')
          ..write('tolerancePct: $tolerancePct, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('remindDaysBefore: $remindDaysBefore, ')
          ..write('active: $active, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    merchantKeyword,
    expectedAmountCents,
    tolerancePct,
    dayOfMonth,
    remindDaysBefore,
    active,
    categoryId,
    accountId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalRecurringExpenseRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.merchantKeyword == this.merchantKeyword &&
          other.expectedAmountCents == this.expectedAmountCents &&
          other.tolerancePct == this.tolerancePct &&
          other.dayOfMonth == this.dayOfMonth &&
          other.remindDaysBefore == this.remindDaysBefore &&
          other.active == this.active &&
          other.categoryId == this.categoryId &&
          other.accountId == this.accountId);
}

class LocalRecurringExpensesCompanion
    extends UpdateCompanion<LocalRecurringExpenseRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> merchantKeyword;
  final Value<int> expectedAmountCents;
  final Value<int> tolerancePct;
  final Value<int> dayOfMonth;
  final Value<int> remindDaysBefore;
  final Value<bool> active;
  final Value<String?> categoryId;
  final Value<String?> accountId;
  final Value<int> rowid;
  const LocalRecurringExpensesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.merchantKeyword = const Value.absent(),
    this.expectedAmountCents = const Value.absent(),
    this.tolerancePct = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.remindDaysBefore = const Value.absent(),
    this.active = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalRecurringExpensesCompanion.insert({
    required String id,
    required String name,
    required String merchantKeyword,
    required int expectedAmountCents,
    required int tolerancePct,
    required int dayOfMonth,
    required int remindDaysBefore,
    required bool active,
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       merchantKeyword = Value(merchantKeyword),
       expectedAmountCents = Value(expectedAmountCents),
       tolerancePct = Value(tolerancePct),
       dayOfMonth = Value(dayOfMonth),
       remindDaysBefore = Value(remindDaysBefore),
       active = Value(active);
  static Insertable<LocalRecurringExpenseRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? merchantKeyword,
    Expression<int>? expectedAmountCents,
    Expression<int>? tolerancePct,
    Expression<int>? dayOfMonth,
    Expression<int>? remindDaysBefore,
    Expression<bool>? active,
    Expression<String>? categoryId,
    Expression<String>? accountId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (merchantKeyword != null) 'merchant_keyword': merchantKeyword,
      if (expectedAmountCents != null)
        'expected_amount_cents': expectedAmountCents,
      if (tolerancePct != null) 'tolerance_pct': tolerancePct,
      if (dayOfMonth != null) 'day_of_month': dayOfMonth,
      if (remindDaysBefore != null) 'remind_days_before': remindDaysBefore,
      if (active != null) 'active': active,
      if (categoryId != null) 'category_id': categoryId,
      if (accountId != null) 'account_id': accountId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalRecurringExpensesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? merchantKeyword,
    Value<int>? expectedAmountCents,
    Value<int>? tolerancePct,
    Value<int>? dayOfMonth,
    Value<int>? remindDaysBefore,
    Value<bool>? active,
    Value<String?>? categoryId,
    Value<String?>? accountId,
    Value<int>? rowid,
  }) {
    return LocalRecurringExpensesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      merchantKeyword: merchantKeyword ?? this.merchantKeyword,
      expectedAmountCents: expectedAmountCents ?? this.expectedAmountCents,
      tolerancePct: tolerancePct ?? this.tolerancePct,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
      active: active ?? this.active,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (merchantKeyword.present) {
      map['merchant_keyword'] = Variable<String>(merchantKeyword.value);
    }
    if (expectedAmountCents.present) {
      map['expected_amount_cents'] = Variable<int>(expectedAmountCents.value);
    }
    if (tolerancePct.present) {
      map['tolerance_pct'] = Variable<int>(tolerancePct.value);
    }
    if (dayOfMonth.present) {
      map['day_of_month'] = Variable<int>(dayOfMonth.value);
    }
    if (remindDaysBefore.present) {
      map['remind_days_before'] = Variable<int>(remindDaysBefore.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalRecurringExpensesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('merchantKeyword: $merchantKeyword, ')
          ..write('expectedAmountCents: $expectedAmountCents, ')
          ..write('tolerancePct: $tolerancePct, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('remindDaysBefore: $remindDaysBefore, ')
          ..write('active: $active, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalRecurringOccurrencesTable extends LocalRecurringOccurrences
    with
        TableInfo<
          $LocalRecurringOccurrencesTable,
          LocalRecurringOccurrenceRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalRecurringOccurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expenseIdMeta = const VerificationMeta(
    'expenseId',
  );
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
    'expense_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<String> period = GeneratedColumn<String>(
    'period',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matchedByMeta = const VerificationMeta(
    'matchedBy',
  );
  @override
  late final GeneratedColumn<String> matchedBy = GeneratedColumn<String>(
    'matched_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<DateTime> paidAt = GeneratedColumn<DateTime>(
    'paid_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionMerchantMeta =
      const VerificationMeta('transactionMerchant');
  @override
  late final GeneratedColumn<String> transactionMerchant =
      GeneratedColumn<String>(
        'transaction_merchant',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _transactionAmountCentsMeta =
      const VerificationMeta('transactionAmountCents');
  @override
  late final GeneratedColumn<int> transactionAmountCents = GeneratedColumn<int>(
    'transaction_amount_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionOccurredAtMeta =
      const VerificationMeta('transactionOccurredAt');
  @override
  late final GeneratedColumn<DateTime> transactionOccurredAt =
      GeneratedColumn<DateTime>(
        'transaction_occurred_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    expenseId,
    period,
    dueDate,
    status,
    matchedBy,
    paidAt,
    transactionId,
    transactionMerchant,
    transactionAmountCents,
    transactionOccurredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_recurring_occurrences';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalRecurringOccurrenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('expense_id')) {
      context.handle(
        _expenseIdMeta,
        expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('period')) {
      context.handle(
        _periodMeta,
        period.isAcceptableOrUnknown(data['period']!, _periodMeta),
      );
    } else if (isInserting) {
      context.missing(_periodMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('matched_by')) {
      context.handle(
        _matchedByMeta,
        matchedBy.isAcceptableOrUnknown(data['matched_by']!, _matchedByMeta),
      );
    }
    if (data.containsKey('paid_at')) {
      context.handle(
        _paidAtMeta,
        paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta),
      );
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    }
    if (data.containsKey('transaction_merchant')) {
      context.handle(
        _transactionMerchantMeta,
        transactionMerchant.isAcceptableOrUnknown(
          data['transaction_merchant']!,
          _transactionMerchantMeta,
        ),
      );
    }
    if (data.containsKey('transaction_amount_cents')) {
      context.handle(
        _transactionAmountCentsMeta,
        transactionAmountCents.isAcceptableOrUnknown(
          data['transaction_amount_cents']!,
          _transactionAmountCentsMeta,
        ),
      );
    }
    if (data.containsKey('transaction_occurred_at')) {
      context.handle(
        _transactionOccurredAtMeta,
        transactionOccurredAt.isAcceptableOrUnknown(
          data['transaction_occurred_at']!,
          _transactionOccurredAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalRecurringOccurrenceRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalRecurringOccurrenceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      expenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expense_id'],
      )!,
      period: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      matchedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}matched_by'],
      ),
      paidAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paid_at'],
      ),
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      ),
      transactionMerchant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_merchant'],
      ),
      transactionAmountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_amount_cents'],
      ),
      transactionOccurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}transaction_occurred_at'],
      ),
    );
  }

  @override
  $LocalRecurringOccurrencesTable createAlias(String alias) {
    return $LocalRecurringOccurrencesTable(attachedDatabase, alias);
  }
}

class LocalRecurringOccurrenceRow extends DataClass
    implements Insertable<LocalRecurringOccurrenceRow> {
  final String id;
  final String expenseId;
  final String period;
  final String dueDate;
  final String status;
  final String? matchedBy;
  final DateTime? paidAt;
  final String? transactionId;
  final String? transactionMerchant;
  final int? transactionAmountCents;
  final DateTime? transactionOccurredAt;
  const LocalRecurringOccurrenceRow({
    required this.id,
    required this.expenseId,
    required this.period,
    required this.dueDate,
    required this.status,
    this.matchedBy,
    this.paidAt,
    this.transactionId,
    this.transactionMerchant,
    this.transactionAmountCents,
    this.transactionOccurredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['expense_id'] = Variable<String>(expenseId);
    map['period'] = Variable<String>(period);
    map['due_date'] = Variable<String>(dueDate);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || matchedBy != null) {
      map['matched_by'] = Variable<String>(matchedBy);
    }
    if (!nullToAbsent || paidAt != null) {
      map['paid_at'] = Variable<DateTime>(paidAt);
    }
    if (!nullToAbsent || transactionId != null) {
      map['transaction_id'] = Variable<String>(transactionId);
    }
    if (!nullToAbsent || transactionMerchant != null) {
      map['transaction_merchant'] = Variable<String>(transactionMerchant);
    }
    if (!nullToAbsent || transactionAmountCents != null) {
      map['transaction_amount_cents'] = Variable<int>(transactionAmountCents);
    }
    if (!nullToAbsent || transactionOccurredAt != null) {
      map['transaction_occurred_at'] = Variable<DateTime>(
        transactionOccurredAt,
      );
    }
    return map;
  }

  LocalRecurringOccurrencesCompanion toCompanion(bool nullToAbsent) {
    return LocalRecurringOccurrencesCompanion(
      id: Value(id),
      expenseId: Value(expenseId),
      period: Value(period),
      dueDate: Value(dueDate),
      status: Value(status),
      matchedBy: matchedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(matchedBy),
      paidAt: paidAt == null && nullToAbsent
          ? const Value.absent()
          : Value(paidAt),
      transactionId: transactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionId),
      transactionMerchant: transactionMerchant == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionMerchant),
      transactionAmountCents: transactionAmountCents == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionAmountCents),
      transactionOccurredAt: transactionOccurredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionOccurredAt),
    );
  }

  factory LocalRecurringOccurrenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalRecurringOccurrenceRow(
      id: serializer.fromJson<String>(json['id']),
      expenseId: serializer.fromJson<String>(json['expenseId']),
      period: serializer.fromJson<String>(json['period']),
      dueDate: serializer.fromJson<String>(json['dueDate']),
      status: serializer.fromJson<String>(json['status']),
      matchedBy: serializer.fromJson<String?>(json['matchedBy']),
      paidAt: serializer.fromJson<DateTime?>(json['paidAt']),
      transactionId: serializer.fromJson<String?>(json['transactionId']),
      transactionMerchant: serializer.fromJson<String?>(
        json['transactionMerchant'],
      ),
      transactionAmountCents: serializer.fromJson<int?>(
        json['transactionAmountCents'],
      ),
      transactionOccurredAt: serializer.fromJson<DateTime?>(
        json['transactionOccurredAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'expenseId': serializer.toJson<String>(expenseId),
      'period': serializer.toJson<String>(period),
      'dueDate': serializer.toJson<String>(dueDate),
      'status': serializer.toJson<String>(status),
      'matchedBy': serializer.toJson<String?>(matchedBy),
      'paidAt': serializer.toJson<DateTime?>(paidAt),
      'transactionId': serializer.toJson<String?>(transactionId),
      'transactionMerchant': serializer.toJson<String?>(transactionMerchant),
      'transactionAmountCents': serializer.toJson<int?>(transactionAmountCents),
      'transactionOccurredAt': serializer.toJson<DateTime?>(
        transactionOccurredAt,
      ),
    };
  }

  LocalRecurringOccurrenceRow copyWith({
    String? id,
    String? expenseId,
    String? period,
    String? dueDate,
    String? status,
    Value<String?> matchedBy = const Value.absent(),
    Value<DateTime?> paidAt = const Value.absent(),
    Value<String?> transactionId = const Value.absent(),
    Value<String?> transactionMerchant = const Value.absent(),
    Value<int?> transactionAmountCents = const Value.absent(),
    Value<DateTime?> transactionOccurredAt = const Value.absent(),
  }) => LocalRecurringOccurrenceRow(
    id: id ?? this.id,
    expenseId: expenseId ?? this.expenseId,
    period: period ?? this.period,
    dueDate: dueDate ?? this.dueDate,
    status: status ?? this.status,
    matchedBy: matchedBy.present ? matchedBy.value : this.matchedBy,
    paidAt: paidAt.present ? paidAt.value : this.paidAt,
    transactionId: transactionId.present
        ? transactionId.value
        : this.transactionId,
    transactionMerchant: transactionMerchant.present
        ? transactionMerchant.value
        : this.transactionMerchant,
    transactionAmountCents: transactionAmountCents.present
        ? transactionAmountCents.value
        : this.transactionAmountCents,
    transactionOccurredAt: transactionOccurredAt.present
        ? transactionOccurredAt.value
        : this.transactionOccurredAt,
  );
  LocalRecurringOccurrenceRow copyWithCompanion(
    LocalRecurringOccurrencesCompanion data,
  ) {
    return LocalRecurringOccurrenceRow(
      id: data.id.present ? data.id.value : this.id,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      period: data.period.present ? data.period.value : this.period,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      status: data.status.present ? data.status.value : this.status,
      matchedBy: data.matchedBy.present ? data.matchedBy.value : this.matchedBy,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      transactionMerchant: data.transactionMerchant.present
          ? data.transactionMerchant.value
          : this.transactionMerchant,
      transactionAmountCents: data.transactionAmountCents.present
          ? data.transactionAmountCents.value
          : this.transactionAmountCents,
      transactionOccurredAt: data.transactionOccurredAt.present
          ? data.transactionOccurredAt.value
          : this.transactionOccurredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalRecurringOccurrenceRow(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('period: $period, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('matchedBy: $matchedBy, ')
          ..write('paidAt: $paidAt, ')
          ..write('transactionId: $transactionId, ')
          ..write('transactionMerchant: $transactionMerchant, ')
          ..write('transactionAmountCents: $transactionAmountCents, ')
          ..write('transactionOccurredAt: $transactionOccurredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    expenseId,
    period,
    dueDate,
    status,
    matchedBy,
    paidAt,
    transactionId,
    transactionMerchant,
    transactionAmountCents,
    transactionOccurredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalRecurringOccurrenceRow &&
          other.id == this.id &&
          other.expenseId == this.expenseId &&
          other.period == this.period &&
          other.dueDate == this.dueDate &&
          other.status == this.status &&
          other.matchedBy == this.matchedBy &&
          other.paidAt == this.paidAt &&
          other.transactionId == this.transactionId &&
          other.transactionMerchant == this.transactionMerchant &&
          other.transactionAmountCents == this.transactionAmountCents &&
          other.transactionOccurredAt == this.transactionOccurredAt);
}

class LocalRecurringOccurrencesCompanion
    extends UpdateCompanion<LocalRecurringOccurrenceRow> {
  final Value<String> id;
  final Value<String> expenseId;
  final Value<String> period;
  final Value<String> dueDate;
  final Value<String> status;
  final Value<String?> matchedBy;
  final Value<DateTime?> paidAt;
  final Value<String?> transactionId;
  final Value<String?> transactionMerchant;
  final Value<int?> transactionAmountCents;
  final Value<DateTime?> transactionOccurredAt;
  final Value<int> rowid;
  const LocalRecurringOccurrencesCompanion({
    this.id = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.period = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.matchedBy = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.transactionMerchant = const Value.absent(),
    this.transactionAmountCents = const Value.absent(),
    this.transactionOccurredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalRecurringOccurrencesCompanion.insert({
    required String id,
    required String expenseId,
    required String period,
    required String dueDate,
    required String status,
    this.matchedBy = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.transactionMerchant = const Value.absent(),
    this.transactionAmountCents = const Value.absent(),
    this.transactionOccurredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       expenseId = Value(expenseId),
       period = Value(period),
       dueDate = Value(dueDate),
       status = Value(status);
  static Insertable<LocalRecurringOccurrenceRow> custom({
    Expression<String>? id,
    Expression<String>? expenseId,
    Expression<String>? period,
    Expression<String>? dueDate,
    Expression<String>? status,
    Expression<String>? matchedBy,
    Expression<DateTime>? paidAt,
    Expression<String>? transactionId,
    Expression<String>? transactionMerchant,
    Expression<int>? transactionAmountCents,
    Expression<DateTime>? transactionOccurredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (expenseId != null) 'expense_id': expenseId,
      if (period != null) 'period': period,
      if (dueDate != null) 'due_date': dueDate,
      if (status != null) 'status': status,
      if (matchedBy != null) 'matched_by': matchedBy,
      if (paidAt != null) 'paid_at': paidAt,
      if (transactionId != null) 'transaction_id': transactionId,
      if (transactionMerchant != null)
        'transaction_merchant': transactionMerchant,
      if (transactionAmountCents != null)
        'transaction_amount_cents': transactionAmountCents,
      if (transactionOccurredAt != null)
        'transaction_occurred_at': transactionOccurredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalRecurringOccurrencesCompanion copyWith({
    Value<String>? id,
    Value<String>? expenseId,
    Value<String>? period,
    Value<String>? dueDate,
    Value<String>? status,
    Value<String?>? matchedBy,
    Value<DateTime?>? paidAt,
    Value<String?>? transactionId,
    Value<String?>? transactionMerchant,
    Value<int?>? transactionAmountCents,
    Value<DateTime?>? transactionOccurredAt,
    Value<int>? rowid,
  }) {
    return LocalRecurringOccurrencesCompanion(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      period: period ?? this.period,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      matchedBy: matchedBy ?? this.matchedBy,
      paidAt: paidAt ?? this.paidAt,
      transactionId: transactionId ?? this.transactionId,
      transactionMerchant: transactionMerchant ?? this.transactionMerchant,
      transactionAmountCents:
          transactionAmountCents ?? this.transactionAmountCents,
      transactionOccurredAt:
          transactionOccurredAt ?? this.transactionOccurredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (period.present) {
      map['period'] = Variable<String>(period.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (matchedBy.present) {
      map['matched_by'] = Variable<String>(matchedBy.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<DateTime>(paidAt.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (transactionMerchant.present) {
      map['transaction_merchant'] = Variable<String>(transactionMerchant.value);
    }
    if (transactionAmountCents.present) {
      map['transaction_amount_cents'] = Variable<int>(
        transactionAmountCents.value,
      );
    }
    if (transactionOccurredAt.present) {
      map['transaction_occurred_at'] = Variable<DateTime>(
        transactionOccurredAt.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalRecurringOccurrencesCompanion(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('period: $period, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('matchedBy: $matchedBy, ')
          ..write('paidAt: $paidAt, ')
          ..write('transactionId: $transactionId, ')
          ..write('transactionMerchant: $transactionMerchant, ')
          ..write('transactionAmountCents: $transactionAmountCents, ')
          ..write('transactionOccurredAt: $transactionOccurredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalTransactionsTable localTransactions =
      $LocalTransactionsTable(this);
  late final $LocalCategoriesTable localCategories = $LocalCategoriesTable(
    this,
  );
  late final $LocalAccountsTable localAccounts = $LocalAccountsTable(this);
  late final $LocalReviewTable localReview = $LocalReviewTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $LocalNfcTagsTable localNfcTags = $LocalNfcTagsTable(this);
  late final $LocalRecurringExpensesTable localRecurringExpenses =
      $LocalRecurringExpensesTable(this);
  late final $LocalRecurringOccurrencesTable localRecurringOccurrences =
      $LocalRecurringOccurrencesTable(this);
  late final Index outboxTargetId = Index(
    'outbox_target_id',
    'CREATE INDEX outbox_target_id ON outbox (target_id)',
  );
  late final Index outboxRelatedId = Index(
    'outbox_related_id',
    'CREATE INDEX outbox_related_id ON outbox (related_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localTransactions,
    localCategories,
    localAccounts,
    localReview,
    outbox,
    syncState,
    localNfcTags,
    localRecurringExpenses,
    localRecurringOccurrences,
    outboxTargetId,
    outboxRelatedId,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$LocalTransactionsTableCreateCompanionBuilder =
    LocalTransactionsCompanion Function({
      required String id,
      required int amountCents,
      required String currency,
      required String direction,
      required String kind,
      required DateTime occurredAt,
      Value<String?> merchant,
      Value<String?> description,
      Value<String?> bank,
      Value<String?> accountId,
      Value<String?> categoryId,
      Value<String?> fiscalTag,
      Value<String?> transferPairId,
      Value<bool> transferAuto,
      required String parsedBy,
      Value<double?> confidence,
      Value<String?> notes,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> pendingPush,
      Value<String> channels,
      Value<int> rowid,
    });
typedef $$LocalTransactionsTableUpdateCompanionBuilder =
    LocalTransactionsCompanion Function({
      Value<String> id,
      Value<int> amountCents,
      Value<String> currency,
      Value<String> direction,
      Value<String> kind,
      Value<DateTime> occurredAt,
      Value<String?> merchant,
      Value<String?> description,
      Value<String?> bank,
      Value<String?> accountId,
      Value<String?> categoryId,
      Value<String?> fiscalTag,
      Value<String?> transferPairId,
      Value<bool> transferAuto,
      Value<String> parsedBy,
      Value<double?> confidence,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> pendingPush,
      Value<String> channels,
      Value<int> rowid,
    });

class $$LocalTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTransactionsTable> {
  $$LocalTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bank => $composableBuilder(
    column: $table.bank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fiscalTag => $composableBuilder(
    column: $table.fiscalTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transferPairId => $composableBuilder(
    column: $table.transferPairId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get transferAuto => $composableBuilder(
    column: $table.transferAuto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parsedBy => $composableBuilder(
    column: $table.parsedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingPush => $composableBuilder(
    column: $table.pendingPush,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channels => $composableBuilder(
    column: $table.channels,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTransactionsTable> {
  $$LocalTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bank => $composableBuilder(
    column: $table.bank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fiscalTag => $composableBuilder(
    column: $table.fiscalTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transferPairId => $composableBuilder(
    column: $table.transferPairId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get transferAuto => $composableBuilder(
    column: $table.transferAuto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parsedBy => $composableBuilder(
    column: $table.parsedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingPush => $composableBuilder(
    column: $table.pendingPush,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channels => $composableBuilder(
    column: $table.channels,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTransactionsTable> {
  $$LocalTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bank =>
      $composableBuilder(column: $table.bank, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fiscalTag =>
      $composableBuilder(column: $table.fiscalTag, builder: (column) => column);

  GeneratedColumn<String> get transferPairId => $composableBuilder(
    column: $table.transferPairId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get transferAuto => $composableBuilder(
    column: $table.transferAuto,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parsedBy =>
      $composableBuilder(column: $table.parsedBy, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingPush => $composableBuilder(
    column: $table.pendingPush,
    builder: (column) => column,
  );

  GeneratedColumn<String> get channels =>
      $composableBuilder(column: $table.channels, builder: (column) => column);
}

class $$LocalTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalTransactionsTable,
          LocalTransaction,
          $$LocalTransactionsTableFilterComposer,
          $$LocalTransactionsTableOrderingComposer,
          $$LocalTransactionsTableAnnotationComposer,
          $$LocalTransactionsTableCreateCompanionBuilder,
          $$LocalTransactionsTableUpdateCompanionBuilder,
          (
            LocalTransaction,
            BaseReferences<
              _$AppDatabase,
              $LocalTransactionsTable,
              LocalTransaction
            >,
          ),
          LocalTransaction,
          PrefetchHooks Function()
        > {
  $$LocalTransactionsTableTableManager(
    _$AppDatabase db,
    $LocalTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String?> merchant = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> bank = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> fiscalTag = const Value.absent(),
                Value<String?> transferPairId = const Value.absent(),
                Value<bool> transferAuto = const Value.absent(),
                Value<String> parsedBy = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingPush = const Value.absent(),
                Value<String> channels = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTransactionsCompanion(
                id: id,
                amountCents: amountCents,
                currency: currency,
                direction: direction,
                kind: kind,
                occurredAt: occurredAt,
                merchant: merchant,
                description: description,
                bank: bank,
                accountId: accountId,
                categoryId: categoryId,
                fiscalTag: fiscalTag,
                transferPairId: transferPairId,
                transferAuto: transferAuto,
                parsedBy: parsedBy,
                confidence: confidence,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                pendingPush: pendingPush,
                channels: channels,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int amountCents,
                required String currency,
                required String direction,
                required String kind,
                required DateTime occurredAt,
                Value<String?> merchant = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> bank = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> fiscalTag = const Value.absent(),
                Value<String?> transferPairId = const Value.absent(),
                Value<bool> transferAuto = const Value.absent(),
                required String parsedBy,
                Value<double?> confidence = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> pendingPush = const Value.absent(),
                Value<String> channels = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTransactionsCompanion.insert(
                id: id,
                amountCents: amountCents,
                currency: currency,
                direction: direction,
                kind: kind,
                occurredAt: occurredAt,
                merchant: merchant,
                description: description,
                bank: bank,
                accountId: accountId,
                categoryId: categoryId,
                fiscalTag: fiscalTag,
                transferPairId: transferPairId,
                transferAuto: transferAuto,
                parsedBy: parsedBy,
                confidence: confidence,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                pendingPush: pendingPush,
                channels: channels,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalTransactionsTable,
      LocalTransaction,
      $$LocalTransactionsTableFilterComposer,
      $$LocalTransactionsTableOrderingComposer,
      $$LocalTransactionsTableAnnotationComposer,
      $$LocalTransactionsTableCreateCompanionBuilder,
      $$LocalTransactionsTableUpdateCompanionBuilder,
      (
        LocalTransaction,
        BaseReferences<
          _$AppDatabase,
          $LocalTransactionsTable,
          LocalTransaction
        >,
      ),
      LocalTransaction,
      PrefetchHooks Function()
    >;
typedef $$LocalCategoriesTableCreateCompanionBuilder =
    LocalCategoriesCompanion Function({
      required String id,
      Value<String?> userId,
      Value<String?> slug,
      required String name,
      Value<String?> icon,
      Value<String?> color,
      required String fiscalTag,
      required bool isSystem,
      Value<int> rowid,
    });
typedef $$LocalCategoriesTableUpdateCompanionBuilder =
    LocalCategoriesCompanion Function({
      Value<String> id,
      Value<String?> userId,
      Value<String?> slug,
      Value<String> name,
      Value<String?> icon,
      Value<String?> color,
      Value<String> fiscalTag,
      Value<bool> isSystem,
      Value<int> rowid,
    });

class $$LocalCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCategoriesTable> {
  $$LocalCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fiscalTag => $composableBuilder(
    column: $table.fiscalTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCategoriesTable> {
  $$LocalCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fiscalTag => $composableBuilder(
    column: $table.fiscalTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCategoriesTable> {
  $$LocalCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get fiscalTag =>
      $composableBuilder(column: $table.fiscalTag, builder: (column) => column);

  GeneratedColumn<bool> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);
}

class $$LocalCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCategoriesTable,
          LocalCategory,
          $$LocalCategoriesTableFilterComposer,
          $$LocalCategoriesTableOrderingComposer,
          $$LocalCategoriesTableAnnotationComposer,
          $$LocalCategoriesTableCreateCompanionBuilder,
          $$LocalCategoriesTableUpdateCompanionBuilder,
          (
            LocalCategory,
            BaseReferences<_$AppDatabase, $LocalCategoriesTable, LocalCategory>,
          ),
          LocalCategory,
          PrefetchHooks Function()
        > {
  $$LocalCategoriesTableTableManager(
    _$AppDatabase db,
    $LocalCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> slug = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String> fiscalTag = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCategoriesCompanion(
                id: id,
                userId: userId,
                slug: slug,
                name: name,
                icon: icon,
                color: color,
                fiscalTag: fiscalTag,
                isSystem: isSystem,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> userId = const Value.absent(),
                Value<String?> slug = const Value.absent(),
                required String name,
                Value<String?> icon = const Value.absent(),
                Value<String?> color = const Value.absent(),
                required String fiscalTag,
                required bool isSystem,
                Value<int> rowid = const Value.absent(),
              }) => LocalCategoriesCompanion.insert(
                id: id,
                userId: userId,
                slug: slug,
                name: name,
                icon: icon,
                color: color,
                fiscalTag: fiscalTag,
                isSystem: isSystem,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCategoriesTable,
      LocalCategory,
      $$LocalCategoriesTableFilterComposer,
      $$LocalCategoriesTableOrderingComposer,
      $$LocalCategoriesTableAnnotationComposer,
      $$LocalCategoriesTableCreateCompanionBuilder,
      $$LocalCategoriesTableUpdateCompanionBuilder,
      (
        LocalCategory,
        BaseReferences<_$AppDatabase, $LocalCategoriesTable, LocalCategory>,
      ),
      LocalCategory,
      PrefetchHooks Function()
    >;
typedef $$LocalAccountsTableCreateCompanionBuilder =
    LocalAccountsCompanion Function({
      required String id,
      required String bank,
      required String kind,
      Value<String?> last4,
      Value<String?> alias,
      Value<int> rowid,
    });
typedef $$LocalAccountsTableUpdateCompanionBuilder =
    LocalAccountsCompanion Function({
      Value<String> id,
      Value<String> bank,
      Value<String> kind,
      Value<String?> last4,
      Value<String?> alias,
      Value<int> rowid,
    });

class $$LocalAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalAccountsTable> {
  $$LocalAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bank => $composableBuilder(
    column: $table.bank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get last4 => $composableBuilder(
    column: $table.last4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalAccountsTable> {
  $$LocalAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bank => $composableBuilder(
    column: $table.bank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get last4 => $composableBuilder(
    column: $table.last4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalAccountsTable> {
  $$LocalAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bank =>
      $composableBuilder(column: $table.bank, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get last4 =>
      $composableBuilder(column: $table.last4, builder: (column) => column);

  GeneratedColumn<String> get alias =>
      $composableBuilder(column: $table.alias, builder: (column) => column);
}

class $$LocalAccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalAccountsTable,
          LocalAccount,
          $$LocalAccountsTableFilterComposer,
          $$LocalAccountsTableOrderingComposer,
          $$LocalAccountsTableAnnotationComposer,
          $$LocalAccountsTableCreateCompanionBuilder,
          $$LocalAccountsTableUpdateCompanionBuilder,
          (
            LocalAccount,
            BaseReferences<_$AppDatabase, $LocalAccountsTable, LocalAccount>,
          ),
          LocalAccount,
          PrefetchHooks Function()
        > {
  $$LocalAccountsTableTableManager(_$AppDatabase db, $LocalAccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bank = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> last4 = const Value.absent(),
                Value<String?> alias = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAccountsCompanion(
                id: id,
                bank: bank,
                kind: kind,
                last4: last4,
                alias: alias,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bank,
                required String kind,
                Value<String?> last4 = const Value.absent(),
                Value<String?> alias = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAccountsCompanion.insert(
                id: id,
                bank: bank,
                kind: kind,
                last4: last4,
                alias: alias,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalAccountsTable,
      LocalAccount,
      $$LocalAccountsTableFilterComposer,
      $$LocalAccountsTableOrderingComposer,
      $$LocalAccountsTableAnnotationComposer,
      $$LocalAccountsTableCreateCompanionBuilder,
      $$LocalAccountsTableUpdateCompanionBuilder,
      (
        LocalAccount,
        BaseReferences<_$AppDatabase, $LocalAccountsTable, LocalAccount>,
      ),
      LocalAccount,
      PrefetchHooks Function()
    >;
typedef $$LocalReviewTableCreateCompanionBuilder =
    LocalReviewCompanion Function({
      required String rawMessageId,
      required String channel,
      Value<String?> bank,
      required String sender,
      required DateTime receivedAt,
      required String reason,
      required String partialExtract,
      Value<String?> messageText,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LocalReviewTableUpdateCompanionBuilder =
    LocalReviewCompanion Function({
      Value<String> rawMessageId,
      Value<String> channel,
      Value<String?> bank,
      Value<String> sender,
      Value<DateTime> receivedAt,
      Value<String> reason,
      Value<String> partialExtract,
      Value<String?> messageText,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalReviewTableFilterComposer
    extends Composer<_$AppDatabase, $LocalReviewTable> {
  $$LocalReviewTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get rawMessageId => $composableBuilder(
    column: $table.rawMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bank => $composableBuilder(
    column: $table.bank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partialExtract => $composableBuilder(
    column: $table.partialExtract,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageText => $composableBuilder(
    column: $table.messageText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalReviewTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalReviewTable> {
  $$LocalReviewTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get rawMessageId => $composableBuilder(
    column: $table.rawMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bank => $composableBuilder(
    column: $table.bank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partialExtract => $composableBuilder(
    column: $table.partialExtract,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageText => $composableBuilder(
    column: $table.messageText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalReviewTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalReviewTable> {
  $$LocalReviewTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get rawMessageId => $composableBuilder(
    column: $table.rawMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => column);

  GeneratedColumn<String> get bank =>
      $composableBuilder(column: $table.bank, builder: (column) => column);

  GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get partialExtract => $composableBuilder(
    column: $table.partialExtract,
    builder: (column) => column,
  );

  GeneratedColumn<String> get messageText => $composableBuilder(
    column: $table.messageText,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalReviewTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalReviewTable,
          LocalReviewRow,
          $$LocalReviewTableFilterComposer,
          $$LocalReviewTableOrderingComposer,
          $$LocalReviewTableAnnotationComposer,
          $$LocalReviewTableCreateCompanionBuilder,
          $$LocalReviewTableUpdateCompanionBuilder,
          (
            LocalReviewRow,
            BaseReferences<_$AppDatabase, $LocalReviewTable, LocalReviewRow>,
          ),
          LocalReviewRow,
          PrefetchHooks Function()
        > {
  $$LocalReviewTableTableManager(_$AppDatabase db, $LocalReviewTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalReviewTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalReviewTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalReviewTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> rawMessageId = const Value.absent(),
                Value<String> channel = const Value.absent(),
                Value<String?> bank = const Value.absent(),
                Value<String> sender = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> partialExtract = const Value.absent(),
                Value<String?> messageText = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalReviewCompanion(
                rawMessageId: rawMessageId,
                channel: channel,
                bank: bank,
                sender: sender,
                receivedAt: receivedAt,
                reason: reason,
                partialExtract: partialExtract,
                messageText: messageText,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String rawMessageId,
                required String channel,
                Value<String?> bank = const Value.absent(),
                required String sender,
                required DateTime receivedAt,
                required String reason,
                required String partialExtract,
                Value<String?> messageText = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalReviewCompanion.insert(
                rawMessageId: rawMessageId,
                channel: channel,
                bank: bank,
                sender: sender,
                receivedAt: receivedAt,
                reason: reason,
                partialExtract: partialExtract,
                messageText: messageText,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalReviewTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalReviewTable,
      LocalReviewRow,
      $$LocalReviewTableFilterComposer,
      $$LocalReviewTableOrderingComposer,
      $$LocalReviewTableAnnotationComposer,
      $$LocalReviewTableCreateCompanionBuilder,
      $$LocalReviewTableUpdateCompanionBuilder,
      (
        LocalReviewRow,
        BaseReferences<_$AppDatabase, $LocalReviewTable, LocalReviewRow>,
      ),
      LocalReviewRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder =
    OutboxCompanion Function({
      Value<int> seq,
      required String kind,
      required String targetId,
      Value<String?> relatedId,
      required String payload,
      required String idempotencyKey,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      required DateTime createdAt,
    });
typedef $$OutboxTableUpdateCompanionBuilder =
    OutboxCompanion Function({
      Value<int> seq,
      Value<String> kind,
      Value<String> targetId,
      Value<String?> relatedId,
      Value<String> payload,
      Value<String> idempotencyKey,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime> createdAt,
    });

class $$OutboxTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedId => $composableBuilder(
    column: $table.relatedId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedId => $composableBuilder(
    column: $table.relatedId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<String> get relatedId =>
      $composableBuilder(column: $table.relatedId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTable,
          OutboxRow,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (OutboxRow, BaseReferences<_$AppDatabase, $OutboxTable, OutboxRow>),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$AppDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<String?> relatedId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OutboxCompanion(
                seq: seq,
                kind: kind,
                targetId: targetId,
                relatedId: relatedId,
                payload: payload,
                idempotencyKey: idempotencyKey,
                status: status,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String kind,
                required String targetId,
                Value<String?> relatedId = const Value.absent(),
                required String payload,
                required String idempotencyKey,
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required DateTime createdAt,
              }) => OutboxCompanion.insert(
                seq: seq,
                kind: kind,
                targetId: targetId,
                relatedId: relatedId,
                payload: payload,
                idempotencyKey: idempotencyKey,
                status: status,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTable,
      OutboxRow,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxRow, BaseReferences<_$AppDatabase, $OutboxTable, OutboxRow>),
      OutboxRow,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder =
    SyncStateCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SyncStateTableUpdateCompanionBuilder =
    SyncStateCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTable,
          SyncStateRow,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateRow,
            BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateRow>,
          ),
          SyncStateRow,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTable,
      SyncStateRow,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateRow,
        BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateRow>,
      ),
      SyncStateRow,
      PrefetchHooks Function()
    >;
typedef $$LocalNfcTagsTableCreateCompanionBuilder =
    LocalNfcTagsCompanion Function({
      required String id,
      required String name,
      Value<String?> categoryId,
      Value<String?> accountId,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$LocalNfcTagsTableUpdateCompanionBuilder =
    LocalNfcTagsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> categoryId,
      Value<String?> accountId,
      Value<String?> note,
      Value<int> rowid,
    });

class $$LocalNfcTagsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalNfcTagsTable> {
  $$LocalNfcTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalNfcTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalNfcTagsTable> {
  $$LocalNfcTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalNfcTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalNfcTagsTable> {
  $$LocalNfcTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$LocalNfcTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalNfcTagsTable,
          LocalNfcTagRow,
          $$LocalNfcTagsTableFilterComposer,
          $$LocalNfcTagsTableOrderingComposer,
          $$LocalNfcTagsTableAnnotationComposer,
          $$LocalNfcTagsTableCreateCompanionBuilder,
          $$LocalNfcTagsTableUpdateCompanionBuilder,
          (
            LocalNfcTagRow,
            BaseReferences<_$AppDatabase, $LocalNfcTagsTable, LocalNfcTagRow>,
          ),
          LocalNfcTagRow,
          PrefetchHooks Function()
        > {
  $$LocalNfcTagsTableTableManager(_$AppDatabase db, $LocalNfcTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalNfcTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalNfcTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalNfcTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalNfcTagsCompanion(
                id: id,
                name: name,
                categoryId: categoryId,
                accountId: accountId,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> categoryId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalNfcTagsCompanion.insert(
                id: id,
                name: name,
                categoryId: categoryId,
                accountId: accountId,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalNfcTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalNfcTagsTable,
      LocalNfcTagRow,
      $$LocalNfcTagsTableFilterComposer,
      $$LocalNfcTagsTableOrderingComposer,
      $$LocalNfcTagsTableAnnotationComposer,
      $$LocalNfcTagsTableCreateCompanionBuilder,
      $$LocalNfcTagsTableUpdateCompanionBuilder,
      (
        LocalNfcTagRow,
        BaseReferences<_$AppDatabase, $LocalNfcTagsTable, LocalNfcTagRow>,
      ),
      LocalNfcTagRow,
      PrefetchHooks Function()
    >;
typedef $$LocalRecurringExpensesTableCreateCompanionBuilder =
    LocalRecurringExpensesCompanion Function({
      required String id,
      required String name,
      required String merchantKeyword,
      required int expectedAmountCents,
      required int tolerancePct,
      required int dayOfMonth,
      required int remindDaysBefore,
      required bool active,
      Value<String?> categoryId,
      Value<String?> accountId,
      Value<int> rowid,
    });
typedef $$LocalRecurringExpensesTableUpdateCompanionBuilder =
    LocalRecurringExpensesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> merchantKeyword,
      Value<int> expectedAmountCents,
      Value<int> tolerancePct,
      Value<int> dayOfMonth,
      Value<int> remindDaysBefore,
      Value<bool> active,
      Value<String?> categoryId,
      Value<String?> accountId,
      Value<int> rowid,
    });

class $$LocalRecurringExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalRecurringExpensesTable> {
  $$LocalRecurringExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchantKeyword => $composableBuilder(
    column: $table.merchantKeyword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expectedAmountCents => $composableBuilder(
    column: $table.expectedAmountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tolerancePct => $composableBuilder(
    column: $table.tolerancePct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remindDaysBefore => $composableBuilder(
    column: $table.remindDaysBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalRecurringExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalRecurringExpensesTable> {
  $$LocalRecurringExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchantKeyword => $composableBuilder(
    column: $table.merchantKeyword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectedAmountCents => $composableBuilder(
    column: $table.expectedAmountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tolerancePct => $composableBuilder(
    column: $table.tolerancePct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remindDaysBefore => $composableBuilder(
    column: $table.remindDaysBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalRecurringExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalRecurringExpensesTable> {
  $$LocalRecurringExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get merchantKeyword => $composableBuilder(
    column: $table.merchantKeyword,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expectedAmountCents => $composableBuilder(
    column: $table.expectedAmountCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tolerancePct => $composableBuilder(
    column: $table.tolerancePct,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remindDaysBefore => $composableBuilder(
    column: $table.remindDaysBefore,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);
}

class $$LocalRecurringExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalRecurringExpensesTable,
          LocalRecurringExpenseRow,
          $$LocalRecurringExpensesTableFilterComposer,
          $$LocalRecurringExpensesTableOrderingComposer,
          $$LocalRecurringExpensesTableAnnotationComposer,
          $$LocalRecurringExpensesTableCreateCompanionBuilder,
          $$LocalRecurringExpensesTableUpdateCompanionBuilder,
          (
            LocalRecurringExpenseRow,
            BaseReferences<
              _$AppDatabase,
              $LocalRecurringExpensesTable,
              LocalRecurringExpenseRow
            >,
          ),
          LocalRecurringExpenseRow,
          PrefetchHooks Function()
        > {
  $$LocalRecurringExpensesTableTableManager(
    _$AppDatabase db,
    $LocalRecurringExpensesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalRecurringExpensesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalRecurringExpensesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalRecurringExpensesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> merchantKeyword = const Value.absent(),
                Value<int> expectedAmountCents = const Value.absent(),
                Value<int> tolerancePct = const Value.absent(),
                Value<int> dayOfMonth = const Value.absent(),
                Value<int> remindDaysBefore = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalRecurringExpensesCompanion(
                id: id,
                name: name,
                merchantKeyword: merchantKeyword,
                expectedAmountCents: expectedAmountCents,
                tolerancePct: tolerancePct,
                dayOfMonth: dayOfMonth,
                remindDaysBefore: remindDaysBefore,
                active: active,
                categoryId: categoryId,
                accountId: accountId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String merchantKeyword,
                required int expectedAmountCents,
                required int tolerancePct,
                required int dayOfMonth,
                required int remindDaysBefore,
                required bool active,
                Value<String?> categoryId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalRecurringExpensesCompanion.insert(
                id: id,
                name: name,
                merchantKeyword: merchantKeyword,
                expectedAmountCents: expectedAmountCents,
                tolerancePct: tolerancePct,
                dayOfMonth: dayOfMonth,
                remindDaysBefore: remindDaysBefore,
                active: active,
                categoryId: categoryId,
                accountId: accountId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalRecurringExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalRecurringExpensesTable,
      LocalRecurringExpenseRow,
      $$LocalRecurringExpensesTableFilterComposer,
      $$LocalRecurringExpensesTableOrderingComposer,
      $$LocalRecurringExpensesTableAnnotationComposer,
      $$LocalRecurringExpensesTableCreateCompanionBuilder,
      $$LocalRecurringExpensesTableUpdateCompanionBuilder,
      (
        LocalRecurringExpenseRow,
        BaseReferences<
          _$AppDatabase,
          $LocalRecurringExpensesTable,
          LocalRecurringExpenseRow
        >,
      ),
      LocalRecurringExpenseRow,
      PrefetchHooks Function()
    >;
typedef $$LocalRecurringOccurrencesTableCreateCompanionBuilder =
    LocalRecurringOccurrencesCompanion Function({
      required String id,
      required String expenseId,
      required String period,
      required String dueDate,
      required String status,
      Value<String?> matchedBy,
      Value<DateTime?> paidAt,
      Value<String?> transactionId,
      Value<String?> transactionMerchant,
      Value<int?> transactionAmountCents,
      Value<DateTime?> transactionOccurredAt,
      Value<int> rowid,
    });
typedef $$LocalRecurringOccurrencesTableUpdateCompanionBuilder =
    LocalRecurringOccurrencesCompanion Function({
      Value<String> id,
      Value<String> expenseId,
      Value<String> period,
      Value<String> dueDate,
      Value<String> status,
      Value<String?> matchedBy,
      Value<DateTime?> paidAt,
      Value<String?> transactionId,
      Value<String?> transactionMerchant,
      Value<int?> transactionAmountCents,
      Value<DateTime?> transactionOccurredAt,
      Value<int> rowid,
    });

class $$LocalRecurringOccurrencesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalRecurringOccurrencesTable> {
  $$LocalRecurringOccurrencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expenseId => $composableBuilder(
    column: $table.expenseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchedBy => $composableBuilder(
    column: $table.matchedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionMerchant => $composableBuilder(
    column: $table.transactionMerchant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transactionAmountCents => $composableBuilder(
    column: $table.transactionAmountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get transactionOccurredAt => $composableBuilder(
    column: $table.transactionOccurredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalRecurringOccurrencesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalRecurringOccurrencesTable> {
  $$LocalRecurringOccurrencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expenseId => $composableBuilder(
    column: $table.expenseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchedBy => $composableBuilder(
    column: $table.matchedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionMerchant => $composableBuilder(
    column: $table.transactionMerchant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transactionAmountCents => $composableBuilder(
    column: $table.transactionAmountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get transactionOccurredAt => $composableBuilder(
    column: $table.transactionOccurredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalRecurringOccurrencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalRecurringOccurrencesTable> {
  $$LocalRecurringOccurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get expenseId =>
      $composableBuilder(column: $table.expenseId, builder: (column) => column);

  GeneratedColumn<String> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get matchedBy =>
      $composableBuilder(column: $table.matchedBy, builder: (column) => column);

  GeneratedColumn<DateTime> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transactionMerchant => $composableBuilder(
    column: $table.transactionMerchant,
    builder: (column) => column,
  );

  GeneratedColumn<int> get transactionAmountCents => $composableBuilder(
    column: $table.transactionAmountCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get transactionOccurredAt => $composableBuilder(
    column: $table.transactionOccurredAt,
    builder: (column) => column,
  );
}

class $$LocalRecurringOccurrencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalRecurringOccurrencesTable,
          LocalRecurringOccurrenceRow,
          $$LocalRecurringOccurrencesTableFilterComposer,
          $$LocalRecurringOccurrencesTableOrderingComposer,
          $$LocalRecurringOccurrencesTableAnnotationComposer,
          $$LocalRecurringOccurrencesTableCreateCompanionBuilder,
          $$LocalRecurringOccurrencesTableUpdateCompanionBuilder,
          (
            LocalRecurringOccurrenceRow,
            BaseReferences<
              _$AppDatabase,
              $LocalRecurringOccurrencesTable,
              LocalRecurringOccurrenceRow
            >,
          ),
          LocalRecurringOccurrenceRow,
          PrefetchHooks Function()
        > {
  $$LocalRecurringOccurrencesTableTableManager(
    _$AppDatabase db,
    $LocalRecurringOccurrencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalRecurringOccurrencesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalRecurringOccurrencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalRecurringOccurrencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> expenseId = const Value.absent(),
                Value<String> period = const Value.absent(),
                Value<String> dueDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> matchedBy = const Value.absent(),
                Value<DateTime?> paidAt = const Value.absent(),
                Value<String?> transactionId = const Value.absent(),
                Value<String?> transactionMerchant = const Value.absent(),
                Value<int?> transactionAmountCents = const Value.absent(),
                Value<DateTime?> transactionOccurredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalRecurringOccurrencesCompanion(
                id: id,
                expenseId: expenseId,
                period: period,
                dueDate: dueDate,
                status: status,
                matchedBy: matchedBy,
                paidAt: paidAt,
                transactionId: transactionId,
                transactionMerchant: transactionMerchant,
                transactionAmountCents: transactionAmountCents,
                transactionOccurredAt: transactionOccurredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String expenseId,
                required String period,
                required String dueDate,
                required String status,
                Value<String?> matchedBy = const Value.absent(),
                Value<DateTime?> paidAt = const Value.absent(),
                Value<String?> transactionId = const Value.absent(),
                Value<String?> transactionMerchant = const Value.absent(),
                Value<int?> transactionAmountCents = const Value.absent(),
                Value<DateTime?> transactionOccurredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalRecurringOccurrencesCompanion.insert(
                id: id,
                expenseId: expenseId,
                period: period,
                dueDate: dueDate,
                status: status,
                matchedBy: matchedBy,
                paidAt: paidAt,
                transactionId: transactionId,
                transactionMerchant: transactionMerchant,
                transactionAmountCents: transactionAmountCents,
                transactionOccurredAt: transactionOccurredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalRecurringOccurrencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalRecurringOccurrencesTable,
      LocalRecurringOccurrenceRow,
      $$LocalRecurringOccurrencesTableFilterComposer,
      $$LocalRecurringOccurrencesTableOrderingComposer,
      $$LocalRecurringOccurrencesTableAnnotationComposer,
      $$LocalRecurringOccurrencesTableCreateCompanionBuilder,
      $$LocalRecurringOccurrencesTableUpdateCompanionBuilder,
      (
        LocalRecurringOccurrenceRow,
        BaseReferences<
          _$AppDatabase,
          $LocalRecurringOccurrencesTable,
          LocalRecurringOccurrenceRow
        >,
      ),
      LocalRecurringOccurrenceRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalTransactionsTableTableManager get localTransactions =>
      $$LocalTransactionsTableTableManager(_db, _db.localTransactions);
  $$LocalCategoriesTableTableManager get localCategories =>
      $$LocalCategoriesTableTableManager(_db, _db.localCategories);
  $$LocalAccountsTableTableManager get localAccounts =>
      $$LocalAccountsTableTableManager(_db, _db.localAccounts);
  $$LocalReviewTableTableManager get localReview =>
      $$LocalReviewTableTableManager(_db, _db.localReview);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
  $$LocalNfcTagsTableTableManager get localNfcTags =>
      $$LocalNfcTagsTableTableManager(_db, _db.localNfcTags);
  $$LocalRecurringExpensesTableTableManager get localRecurringExpenses =>
      $$LocalRecurringExpensesTableTableManager(
        _db,
        _db.localRecurringExpenses,
      );
  $$LocalRecurringOccurrencesTableTableManager get localRecurringOccurrences =>
      $$LocalRecurringOccurrencesTableTableManager(
        _db,
        _db.localRecurringOccurrences,
      );
}
