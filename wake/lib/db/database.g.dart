// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AlarmTable extends Alarm with TableInfo<$AlarmTable, AlarmData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlarmTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _ringAtMeta = const VerificationMeta('ringAt');
  @override
  late final GeneratedColumn<DateTime> ringAt = GeneratedColumn<DateTime>(
    'ring_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 6,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, ringAt, message, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alarm';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlarmData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ring_at')) {
      context.handle(
        _ringAtMeta,
        ringAt.isAcceptableOrUnknown(data['ring_at']!, _ringAtMeta),
      );
    } else if (isInserting) {
      context.missing(_ringAtMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AlarmData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlarmData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ringAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ring_at'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $AlarmTable createAlias(String alias) {
    return $AlarmTable(attachedDatabase, alias);
  }
}

class AlarmData extends DataClass implements Insertable<AlarmData> {
  final int id;
  final DateTime ringAt;
  final String message;
  final DateTime? createdAt;
  const AlarmData({
    required this.id,
    required this.ringAt,
    required this.message,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ring_at'] = Variable<DateTime>(ringAt);
    map['message'] = Variable<String>(message);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  AlarmCompanion toCompanion(bool nullToAbsent) {
    return AlarmCompanion(
      id: Value(id),
      ringAt: Value(ringAt),
      message: Value(message),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory AlarmData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlarmData(
      id: serializer.fromJson<int>(json['id']),
      ringAt: serializer.fromJson<DateTime>(json['ringAt']),
      message: serializer.fromJson<String>(json['message']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ringAt': serializer.toJson<DateTime>(ringAt),
      'message': serializer.toJson<String>(message),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  AlarmData copyWith({
    int? id,
    DateTime? ringAt,
    String? message,
    Value<DateTime?> createdAt = const Value.absent(),
  }) => AlarmData(
    id: id ?? this.id,
    ringAt: ringAt ?? this.ringAt,
    message: message ?? this.message,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  AlarmData copyWithCompanion(AlarmCompanion data) {
    return AlarmData(
      id: data.id.present ? data.id.value : this.id,
      ringAt: data.ringAt.present ? data.ringAt.value : this.ringAt,
      message: data.message.present ? data.message.value : this.message,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlarmData(')
          ..write('id: $id, ')
          ..write('ringAt: $ringAt, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ringAt, message, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlarmData &&
          other.id == this.id &&
          other.ringAt == this.ringAt &&
          other.message == this.message &&
          other.createdAt == this.createdAt);
}

class AlarmCompanion extends UpdateCompanion<AlarmData> {
  final Value<int> id;
  final Value<DateTime> ringAt;
  final Value<String> message;
  final Value<DateTime?> createdAt;
  const AlarmCompanion({
    this.id = const Value.absent(),
    this.ringAt = const Value.absent(),
    this.message = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AlarmCompanion.insert({
    this.id = const Value.absent(),
    required DateTime ringAt,
    required String message,
    this.createdAt = const Value.absent(),
  }) : ringAt = Value(ringAt),
       message = Value(message);
  static Insertable<AlarmData> custom({
    Expression<int>? id,
    Expression<DateTime>? ringAt,
    Expression<String>? message,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ringAt != null) 'ring_at': ringAt,
      if (message != null) 'message': message,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AlarmCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? ringAt,
    Value<String>? message,
    Value<DateTime?>? createdAt,
  }) {
    return AlarmCompanion(
      id: id ?? this.id,
      ringAt: ringAt ?? this.ringAt,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ringAt.present) {
      map['ring_at'] = Variable<DateTime>(ringAt.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlarmCompanion(')
          ..write('id: $id, ')
          ..write('ringAt: $ringAt, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AlarmTable alarm = $AlarmTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [alarm];
}

typedef $$AlarmTableCreateCompanionBuilder =
    AlarmCompanion Function({
      Value<int> id,
      required DateTime ringAt,
      required String message,
      Value<DateTime?> createdAt,
    });
typedef $$AlarmTableUpdateCompanionBuilder =
    AlarmCompanion Function({
      Value<int> id,
      Value<DateTime> ringAt,
      Value<String> message,
      Value<DateTime?> createdAt,
    });

class $$AlarmTableFilterComposer extends Composer<_$AppDatabase, $AlarmTable> {
  $$AlarmTableFilterComposer({
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

  ColumnFilters<DateTime> get ringAt => $composableBuilder(
    column: $table.ringAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlarmTableOrderingComposer
    extends Composer<_$AppDatabase, $AlarmTable> {
  $$AlarmTableOrderingComposer({
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

  ColumnOrderings<DateTime> get ringAt => $composableBuilder(
    column: $table.ringAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlarmTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlarmTable> {
  $$AlarmTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get ringAt =>
      $composableBuilder(column: $table.ringAt, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AlarmTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlarmTable,
          AlarmData,
          $$AlarmTableFilterComposer,
          $$AlarmTableOrderingComposer,
          $$AlarmTableAnnotationComposer,
          $$AlarmTableCreateCompanionBuilder,
          $$AlarmTableUpdateCompanionBuilder,
          (AlarmData, BaseReferences<_$AppDatabase, $AlarmTable, AlarmData>),
          AlarmData,
          PrefetchHooks Function()
        > {
  $$AlarmTableTableManager(_$AppDatabase db, $AlarmTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlarmTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlarmTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlarmTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> ringAt = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
              }) => AlarmCompanion(
                id: id,
                ringAt: ringAt,
                message: message,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime ringAt,
                required String message,
                Value<DateTime?> createdAt = const Value.absent(),
              }) => AlarmCompanion.insert(
                id: id,
                ringAt: ringAt,
                message: message,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlarmTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlarmTable,
      AlarmData,
      $$AlarmTableFilterComposer,
      $$AlarmTableOrderingComposer,
      $$AlarmTableAnnotationComposer,
      $$AlarmTableCreateCompanionBuilder,
      $$AlarmTableUpdateCompanionBuilder,
      (AlarmData, BaseReferences<_$AppDatabase, $AlarmTable, AlarmData>),
      AlarmData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AlarmTableTableManager get alarm =>
      $$AlarmTableTableManager(_db, _db.alarm);
}
