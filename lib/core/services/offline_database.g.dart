// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_database.dart';

// ignore_for_file: type=lint
class $PendingTransactionsTable extends PendingTransactions
    with TableInfo<$PendingTransactionsTable, PendingTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _transactionJsonMeta = const VerificationMeta(
    'transactionJson',
  );
  @override
  late final GeneratedColumn<String> transactionJson = GeneratedColumn<String>(
    'transaction_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientUpdatedAtMeta = const VerificationMeta(
    'clientUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientUpdatedAt =
      GeneratedColumn<DateTime>(
        'client_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionJson,
    clientUpdatedAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('transaction_json')) {
      context.handle(
        _transactionJsonMeta,
        transactionJson.isAcceptableOrUnknown(
          data['transaction_json']!,
          _transactionJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionJsonMeta);
    }
    if (data.containsKey('client_updated_at')) {
      context.handle(
        _clientUpdatedAtMeta,
        clientUpdatedAt.isAcceptableOrUnknown(
          data['client_updated_at']!,
          _clientUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientUpdatedAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      transactionJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_json'],
      )!,
      clientUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_updated_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $PendingTransactionsTable createAlias(String alias) {
    return $PendingTransactionsTable(attachedDatabase, alias);
  }
}

class PendingTransaction extends DataClass
    implements Insertable<PendingTransaction> {
  final int id;
  final String transactionJson;
  final DateTime clientUpdatedAt;
  final bool synced;
  const PendingTransaction({
    required this.id,
    required this.transactionJson,
    required this.clientUpdatedAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['transaction_json'] = Variable<String>(transactionJson);
    map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  PendingTransactionsCompanion toCompanion(bool nullToAbsent) {
    return PendingTransactionsCompanion(
      id: Value(id),
      transactionJson: Value(transactionJson),
      clientUpdatedAt: Value(clientUpdatedAt),
      synced: Value(synced),
    );
  }

  factory PendingTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingTransaction(
      id: serializer.fromJson<int>(json['id']),
      transactionJson: serializer.fromJson<String>(json['transactionJson']),
      clientUpdatedAt: serializer.fromJson<DateTime>(json['clientUpdatedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'transactionJson': serializer.toJson<String>(transactionJson),
      'clientUpdatedAt': serializer.toJson<DateTime>(clientUpdatedAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  PendingTransaction copyWith({
    int? id,
    String? transactionJson,
    DateTime? clientUpdatedAt,
    bool? synced,
  }) => PendingTransaction(
    id: id ?? this.id,
    transactionJson: transactionJson ?? this.transactionJson,
    clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
    synced: synced ?? this.synced,
  );
  PendingTransaction copyWithCompanion(PendingTransactionsCompanion data) {
    return PendingTransaction(
      id: data.id.present ? data.id.value : this.id,
      transactionJson: data.transactionJson.present
          ? data.transactionJson.value
          : this.transactionJson,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingTransaction(')
          ..write('id: $id, ')
          ..write('transactionJson: $transactionJson, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, transactionJson, clientUpdatedAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingTransaction &&
          other.id == this.id &&
          other.transactionJson == this.transactionJson &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.synced == this.synced);
}

class PendingTransactionsCompanion extends UpdateCompanion<PendingTransaction> {
  final Value<int> id;
  final Value<String> transactionJson;
  final Value<DateTime> clientUpdatedAt;
  final Value<bool> synced;
  const PendingTransactionsCompanion({
    this.id = const Value.absent(),
    this.transactionJson = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.synced = const Value.absent(),
  });
  PendingTransactionsCompanion.insert({
    this.id = const Value.absent(),
    required String transactionJson,
    required DateTime clientUpdatedAt,
    this.synced = const Value.absent(),
  }) : transactionJson = Value(transactionJson),
       clientUpdatedAt = Value(clientUpdatedAt);
  static Insertable<PendingTransaction> custom({
    Expression<int>? id,
    Expression<String>? transactionJson,
    Expression<DateTime>? clientUpdatedAt,
    Expression<bool>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionJson != null) 'transaction_json': transactionJson,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (synced != null) 'synced': synced,
    });
  }

  PendingTransactionsCompanion copyWith({
    Value<int>? id,
    Value<String>? transactionJson,
    Value<DateTime>? clientUpdatedAt,
    Value<bool>? synced,
  }) {
    return PendingTransactionsCompanion(
      id: id ?? this.id,
      transactionJson: transactionJson ?? this.transactionJson,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (transactionJson.present) {
      map['transaction_json'] = Variable<String>(transactionJson.value);
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('transactionJson: $transactionJson, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

class $ScanRateLogTable extends ScanRateLog
    with TableInfo<$ScanRateLogTable, ScanRateLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScanRateLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _callMsMeta = const VerificationMeta('callMs');
  @override
  late final GeneratedColumn<int> callMs = GeneratedColumn<int>(
    'call_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, callMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan_rate_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScanRateLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('call_ms')) {
      context.handle(
        _callMsMeta,
        callMs.isAcceptableOrUnknown(data['call_ms']!, _callMsMeta),
      );
    } else if (isInserting) {
      context.missing(_callMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScanRateLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanRateLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      callMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}call_ms'],
      )!,
    );
  }

  @override
  $ScanRateLogTable createAlias(String alias) {
    return $ScanRateLogTable(attachedDatabase, alias);
  }
}

class ScanRateLogData extends DataClass implements Insertable<ScanRateLogData> {
  final int id;
  final int callMs;
  const ScanRateLogData({required this.id, required this.callMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['call_ms'] = Variable<int>(callMs);
    return map;
  }

  ScanRateLogCompanion toCompanion(bool nullToAbsent) {
    return ScanRateLogCompanion(id: Value(id), callMs: Value(callMs));
  }

  factory ScanRateLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanRateLogData(
      id: serializer.fromJson<int>(json['id']),
      callMs: serializer.fromJson<int>(json['callMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'callMs': serializer.toJson<int>(callMs),
    };
  }

  ScanRateLogData copyWith({int? id, int? callMs}) =>
      ScanRateLogData(id: id ?? this.id, callMs: callMs ?? this.callMs);
  ScanRateLogData copyWithCompanion(ScanRateLogCompanion data) {
    return ScanRateLogData(
      id: data.id.present ? data.id.value : this.id,
      callMs: data.callMs.present ? data.callMs.value : this.callMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanRateLogData(')
          ..write('id: $id, ')
          ..write('callMs: $callMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, callMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanRateLogData &&
          other.id == this.id &&
          other.callMs == this.callMs);
}

class ScanRateLogCompanion extends UpdateCompanion<ScanRateLogData> {
  final Value<int> id;
  final Value<int> callMs;
  const ScanRateLogCompanion({
    this.id = const Value.absent(),
    this.callMs = const Value.absent(),
  });
  ScanRateLogCompanion.insert({
    this.id = const Value.absent(),
    required int callMs,
  }) : callMs = Value(callMs);
  static Insertable<ScanRateLogData> custom({
    Expression<int>? id,
    Expression<int>? callMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (callMs != null) 'call_ms': callMs,
    });
  }

  ScanRateLogCompanion copyWith({Value<int>? id, Value<int>? callMs}) {
    return ScanRateLogCompanion(
      id: id ?? this.id,
      callMs: callMs ?? this.callMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (callMs.present) {
      map['call_ms'] = Variable<int>(callMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScanRateLogCompanion(')
          ..write('id: $id, ')
          ..write('callMs: $callMs')
          ..write(')'))
        .toString();
  }
}

class $PendingScanCountsTable extends PendingScanCounts
    with TableInfo<$PendingScanCountsTable, PendingScanCount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingScanCountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _atMsMeta = const VerificationMeta('atMs');
  @override
  late final GeneratedColumn<int> atMs = GeneratedColumn<int>(
    'at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, atMs, synced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_scan_counts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingScanCount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at_ms')) {
      context.handle(
        _atMsMeta,
        atMs.isAcceptableOrUnknown(data['at_ms']!, _atMsMeta),
      );
    } else if (isInserting) {
      context.missing(_atMsMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingScanCount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingScanCount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      atMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at_ms'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $PendingScanCountsTable createAlias(String alias) {
    return $PendingScanCountsTable(attachedDatabase, alias);
  }
}

class PendingScanCount extends DataClass
    implements Insertable<PendingScanCount> {
  final int id;
  final int atMs;
  final bool synced;
  const PendingScanCount({
    required this.id,
    required this.atMs,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at_ms'] = Variable<int>(atMs);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  PendingScanCountsCompanion toCompanion(bool nullToAbsent) {
    return PendingScanCountsCompanion(
      id: Value(id),
      atMs: Value(atMs),
      synced: Value(synced),
    );
  }

  factory PendingScanCount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingScanCount(
      id: serializer.fromJson<int>(json['id']),
      atMs: serializer.fromJson<int>(json['atMs']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'atMs': serializer.toJson<int>(atMs),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  PendingScanCount copyWith({int? id, int? atMs, bool? synced}) =>
      PendingScanCount(
        id: id ?? this.id,
        atMs: atMs ?? this.atMs,
        synced: synced ?? this.synced,
      );
  PendingScanCount copyWithCompanion(PendingScanCountsCompanion data) {
    return PendingScanCount(
      id: data.id.present ? data.id.value : this.id,
      atMs: data.atMs.present ? data.atMs.value : this.atMs,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingScanCount(')
          ..write('id: $id, ')
          ..write('atMs: $atMs, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, atMs, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingScanCount &&
          other.id == this.id &&
          other.atMs == this.atMs &&
          other.synced == this.synced);
}

class PendingScanCountsCompanion extends UpdateCompanion<PendingScanCount> {
  final Value<int> id;
  final Value<int> atMs;
  final Value<bool> synced;
  const PendingScanCountsCompanion({
    this.id = const Value.absent(),
    this.atMs = const Value.absent(),
    this.synced = const Value.absent(),
  });
  PendingScanCountsCompanion.insert({
    this.id = const Value.absent(),
    required int atMs,
    this.synced = const Value.absent(),
  }) : atMs = Value(atMs);
  static Insertable<PendingScanCount> custom({
    Expression<int>? id,
    Expression<int>? atMs,
    Expression<bool>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (atMs != null) 'at_ms': atMs,
      if (synced != null) 'synced': synced,
    });
  }

  PendingScanCountsCompanion copyWith({
    Value<int>? id,
    Value<int>? atMs,
    Value<bool>? synced,
  }) {
    return PendingScanCountsCompanion(
      id: id ?? this.id,
      atMs: atMs ?? this.atMs,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (atMs.present) {
      map['at_ms'] = Variable<int>(atMs.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingScanCountsCompanion(')
          ..write('id: $id, ')
          ..write('atMs: $atMs, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

abstract class _$OfflineDatabase extends GeneratedDatabase {
  _$OfflineDatabase(QueryExecutor e) : super(e);
  $OfflineDatabaseManager get managers => $OfflineDatabaseManager(this);
  late final $PendingTransactionsTable pendingTransactions =
      $PendingTransactionsTable(this);
  late final $ScanRateLogTable scanRateLog = $ScanRateLogTable(this);
  late final $PendingScanCountsTable pendingScanCounts =
      $PendingScanCountsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    pendingTransactions,
    scanRateLog,
    pendingScanCounts,
  ];
}

typedef $$PendingTransactionsTableCreateCompanionBuilder =
    PendingTransactionsCompanion Function({
      Value<int> id,
      required String transactionJson,
      required DateTime clientUpdatedAt,
      Value<bool> synced,
    });
typedef $$PendingTransactionsTableUpdateCompanionBuilder =
    PendingTransactionsCompanion Function({
      Value<int> id,
      Value<String> transactionJson,
      Value<DateTime> clientUpdatedAt,
      Value<bool> synced,
    });

class $$PendingTransactionsTableFilterComposer
    extends Composer<_$OfflineDatabase, $PendingTransactionsTable> {
  $$PendingTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionJson => $composableBuilder(
    column: $table.transactionJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingTransactionsTableOrderingComposer
    extends Composer<_$OfflineDatabase, $PendingTransactionsTable> {
  $$PendingTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionJson => $composableBuilder(
    column: $table.transactionJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingTransactionsTableAnnotationComposer
    extends Composer<_$OfflineDatabase, $PendingTransactionsTable> {
  $$PendingTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transactionJson => $composableBuilder(
    column: $table.transactionJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get clientUpdatedAt => $composableBuilder(
    column: $table.clientUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$PendingTransactionsTableTableManager
    extends
        RootTableManager<
          _$OfflineDatabase,
          $PendingTransactionsTable,
          PendingTransaction,
          $$PendingTransactionsTableFilterComposer,
          $$PendingTransactionsTableOrderingComposer,
          $$PendingTransactionsTableAnnotationComposer,
          $$PendingTransactionsTableCreateCompanionBuilder,
          $$PendingTransactionsTableUpdateCompanionBuilder,
          (
            PendingTransaction,
            BaseReferences<
              _$OfflineDatabase,
              $PendingTransactionsTable,
              PendingTransaction
            >,
          ),
          PendingTransaction,
          PrefetchHooks Function()
        > {
  $$PendingTransactionsTableTableManager(
    _$OfflineDatabase db,
    $PendingTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingTransactionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PendingTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> transactionJson = const Value.absent(),
                Value<DateTime> clientUpdatedAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
              }) => PendingTransactionsCompanion(
                id: id,
                transactionJson: transactionJson,
                clientUpdatedAt: clientUpdatedAt,
                synced: synced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String transactionJson,
                required DateTime clientUpdatedAt,
                Value<bool> synced = const Value.absent(),
              }) => PendingTransactionsCompanion.insert(
                id: id,
                transactionJson: transactionJson,
                clientUpdatedAt: clientUpdatedAt,
                synced: synced,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$OfflineDatabase,
      $PendingTransactionsTable,
      PendingTransaction,
      $$PendingTransactionsTableFilterComposer,
      $$PendingTransactionsTableOrderingComposer,
      $$PendingTransactionsTableAnnotationComposer,
      $$PendingTransactionsTableCreateCompanionBuilder,
      $$PendingTransactionsTableUpdateCompanionBuilder,
      (
        PendingTransaction,
        BaseReferences<
          _$OfflineDatabase,
          $PendingTransactionsTable,
          PendingTransaction
        >,
      ),
      PendingTransaction,
      PrefetchHooks Function()
    >;
typedef $$ScanRateLogTableCreateCompanionBuilder =
    ScanRateLogCompanion Function({Value<int> id, required int callMs});
typedef $$ScanRateLogTableUpdateCompanionBuilder =
    ScanRateLogCompanion Function({Value<int> id, Value<int> callMs});

class $$ScanRateLogTableFilterComposer
    extends Composer<_$OfflineDatabase, $ScanRateLogTable> {
  $$ScanRateLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get callMs => $composableBuilder(
    column: $table.callMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScanRateLogTableOrderingComposer
    extends Composer<_$OfflineDatabase, $ScanRateLogTable> {
  $$ScanRateLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get callMs => $composableBuilder(
    column: $table.callMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScanRateLogTableAnnotationComposer
    extends Composer<_$OfflineDatabase, $ScanRateLogTable> {
  $$ScanRateLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get callMs =>
      $composableBuilder(column: $table.callMs, builder: (column) => column);
}

class $$ScanRateLogTableTableManager
    extends
        RootTableManager<
          _$OfflineDatabase,
          $ScanRateLogTable,
          ScanRateLogData,
          $$ScanRateLogTableFilterComposer,
          $$ScanRateLogTableOrderingComposer,
          $$ScanRateLogTableAnnotationComposer,
          $$ScanRateLogTableCreateCompanionBuilder,
          $$ScanRateLogTableUpdateCompanionBuilder,
          (
            ScanRateLogData,
            BaseReferences<
              _$OfflineDatabase,
              $ScanRateLogTable,
              ScanRateLogData
            >,
          ),
          ScanRateLogData,
          PrefetchHooks Function()
        > {
  $$ScanRateLogTableTableManager(_$OfflineDatabase db, $ScanRateLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScanRateLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScanRateLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScanRateLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> callMs = const Value.absent(),
              }) => ScanRateLogCompanion(id: id, callMs: callMs),
          createCompanionCallback:
              ({Value<int> id = const Value.absent(), required int callMs}) =>
                  ScanRateLogCompanion.insert(id: id, callMs: callMs),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScanRateLogTableProcessedTableManager =
    ProcessedTableManager<
      _$OfflineDatabase,
      $ScanRateLogTable,
      ScanRateLogData,
      $$ScanRateLogTableFilterComposer,
      $$ScanRateLogTableOrderingComposer,
      $$ScanRateLogTableAnnotationComposer,
      $$ScanRateLogTableCreateCompanionBuilder,
      $$ScanRateLogTableUpdateCompanionBuilder,
      (
        ScanRateLogData,
        BaseReferences<_$OfflineDatabase, $ScanRateLogTable, ScanRateLogData>,
      ),
      ScanRateLogData,
      PrefetchHooks Function()
    >;
typedef $$PendingScanCountsTableCreateCompanionBuilder =
    PendingScanCountsCompanion Function({
      Value<int> id,
      required int atMs,
      Value<bool> synced,
    });
typedef $$PendingScanCountsTableUpdateCompanionBuilder =
    PendingScanCountsCompanion Function({
      Value<int> id,
      Value<int> atMs,
      Value<bool> synced,
    });

class $$PendingScanCountsTableFilterComposer
    extends Composer<_$OfflineDatabase, $PendingScanCountsTable> {
  $$PendingScanCountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get atMs => $composableBuilder(
    column: $table.atMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingScanCountsTableOrderingComposer
    extends Composer<_$OfflineDatabase, $PendingScanCountsTable> {
  $$PendingScanCountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get atMs => $composableBuilder(
    column: $table.atMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingScanCountsTableAnnotationComposer
    extends Composer<_$OfflineDatabase, $PendingScanCountsTable> {
  $$PendingScanCountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get atMs =>
      $composableBuilder(column: $table.atMs, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$PendingScanCountsTableTableManager
    extends
        RootTableManager<
          _$OfflineDatabase,
          $PendingScanCountsTable,
          PendingScanCount,
          $$PendingScanCountsTableFilterComposer,
          $$PendingScanCountsTableOrderingComposer,
          $$PendingScanCountsTableAnnotationComposer,
          $$PendingScanCountsTableCreateCompanionBuilder,
          $$PendingScanCountsTableUpdateCompanionBuilder,
          (
            PendingScanCount,
            BaseReferences<
              _$OfflineDatabase,
              $PendingScanCountsTable,
              PendingScanCount
            >,
          ),
          PendingScanCount,
          PrefetchHooks Function()
        > {
  $$PendingScanCountsTableTableManager(
    _$OfflineDatabase db,
    $PendingScanCountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingScanCountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingScanCountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingScanCountsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> atMs = const Value.absent(),
                Value<bool> synced = const Value.absent(),
              }) => PendingScanCountsCompanion(
                id: id,
                atMs: atMs,
                synced: synced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int atMs,
                Value<bool> synced = const Value.absent(),
              }) => PendingScanCountsCompanion.insert(
                id: id,
                atMs: atMs,
                synced: synced,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingScanCountsTableProcessedTableManager =
    ProcessedTableManager<
      _$OfflineDatabase,
      $PendingScanCountsTable,
      PendingScanCount,
      $$PendingScanCountsTableFilterComposer,
      $$PendingScanCountsTableOrderingComposer,
      $$PendingScanCountsTableAnnotationComposer,
      $$PendingScanCountsTableCreateCompanionBuilder,
      $$PendingScanCountsTableUpdateCompanionBuilder,
      (
        PendingScanCount,
        BaseReferences<
          _$OfflineDatabase,
          $PendingScanCountsTable,
          PendingScanCount
        >,
      ),
      PendingScanCount,
      PrefetchHooks Function()
    >;

class $OfflineDatabaseManager {
  final _$OfflineDatabase _db;
  $OfflineDatabaseManager(this._db);
  $$PendingTransactionsTableTableManager get pendingTransactions =>
      $$PendingTransactionsTableTableManager(_db, _db.pendingTransactions);
  $$ScanRateLogTableTableManager get scanRateLog =>
      $$ScanRateLogTableTableManager(_db, _db.scanRateLog);
  $$PendingScanCountsTableTableManager get pendingScanCounts =>
      $$PendingScanCountsTableTableManager(_db, _db.pendingScanCounts);
}
