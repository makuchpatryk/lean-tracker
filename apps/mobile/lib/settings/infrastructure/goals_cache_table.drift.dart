// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:lean_tracker/settings/infrastructure/goals_cache_table.drift.dart'
    as i1;
import 'package:lean_tracker/settings/infrastructure/goals_cache_table.dart'
    as i2;

typedef $$CachedGoalsTableCreateCompanionBuilder =
    i1.CachedGoalsCompanion Function({
      required String userId,
      required int goalKcal,
      required int goalProteinG,
      required int goalFatG,
      required int goalCarbsG,
      i0.Value<int> rowid,
    });
typedef $$CachedGoalsTableUpdateCompanionBuilder =
    i1.CachedGoalsCompanion Function({
      i0.Value<String> userId,
      i0.Value<int> goalKcal,
      i0.Value<int> goalProteinG,
      i0.Value<int> goalFatG,
      i0.Value<int> goalCarbsG,
      i0.Value<int> rowid,
    });

class $$CachedGoalsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$CachedGoalsTable> {
  $$CachedGoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get goalKcal => $composableBuilder(
    column: $table.goalKcal,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get goalProteinG => $composableBuilder(
    column: $table.goalProteinG,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get goalFatG => $composableBuilder(
    column: $table.goalFatG,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get goalCarbsG => $composableBuilder(
    column: $table.goalCarbsG,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $$CachedGoalsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$CachedGoalsTable> {
  $$CachedGoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get goalKcal => $composableBuilder(
    column: $table.goalKcal,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get goalProteinG => $composableBuilder(
    column: $table.goalProteinG,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get goalFatG => $composableBuilder(
    column: $table.goalFatG,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get goalCarbsG => $composableBuilder(
    column: $table.goalCarbsG,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$CachedGoalsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$CachedGoalsTable> {
  $$CachedGoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  i0.GeneratedColumn<int> get goalKcal =>
      $composableBuilder(column: $table.goalKcal, builder: (column) => column);

  i0.GeneratedColumn<int> get goalProteinG => $composableBuilder(
    column: $table.goalProteinG,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get goalFatG =>
      $composableBuilder(column: $table.goalFatG, builder: (column) => column);

  i0.GeneratedColumn<int> get goalCarbsG => $composableBuilder(
    column: $table.goalCarbsG,
    builder: (column) => column,
  );
}

class $$CachedGoalsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$CachedGoalsTable,
          i1.CachedGoalsRow,
          i1.$$CachedGoalsTableFilterComposer,
          i1.$$CachedGoalsTableOrderingComposer,
          i1.$$CachedGoalsTableAnnotationComposer,
          $$CachedGoalsTableCreateCompanionBuilder,
          $$CachedGoalsTableUpdateCompanionBuilder,
          (
            i1.CachedGoalsRow,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.$CachedGoalsTable,
              i1.CachedGoalsRow
            >,
          ),
          i1.CachedGoalsRow,
          i0.PrefetchHooks Function()
        > {
  $$CachedGoalsTableTableManager(
    i0.GeneratedDatabase db,
    i1.$CachedGoalsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$CachedGoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$CachedGoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$CachedGoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> userId = const i0.Value.absent(),
                i0.Value<int> goalKcal = const i0.Value.absent(),
                i0.Value<int> goalProteinG = const i0.Value.absent(),
                i0.Value<int> goalFatG = const i0.Value.absent(),
                i0.Value<int> goalCarbsG = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.CachedGoalsCompanion(
                userId: userId,
                goalKcal: goalKcal,
                goalProteinG: goalProteinG,
                goalFatG: goalFatG,
                goalCarbsG: goalCarbsG,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required int goalKcal,
                required int goalProteinG,
                required int goalFatG,
                required int goalCarbsG,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.CachedGoalsCompanion.insert(
                userId: userId,
                goalKcal: goalKcal,
                goalProteinG: goalProteinG,
                goalFatG: goalFatG,
                goalCarbsG: goalCarbsG,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedGoalsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$CachedGoalsTable,
      i1.CachedGoalsRow,
      i1.$$CachedGoalsTableFilterComposer,
      i1.$$CachedGoalsTableOrderingComposer,
      i1.$$CachedGoalsTableAnnotationComposer,
      $$CachedGoalsTableCreateCompanionBuilder,
      $$CachedGoalsTableUpdateCompanionBuilder,
      (
        i1.CachedGoalsRow,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$CachedGoalsTable,
          i1.CachedGoalsRow
        >,
      ),
      i1.CachedGoalsRow,
      i0.PrefetchHooks Function()
    >;

class $CachedGoalsTable extends i2.CachedGoals
    with i0.TableInfo<$CachedGoalsTable, i1.CachedGoalsRow> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedGoalsTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _userIdMeta = const i0.VerificationMeta(
    'userId',
  );
  @override
  late final i0.GeneratedColumn<String> userId = i0.GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _goalKcalMeta = const i0.VerificationMeta(
    'goalKcal',
  );
  @override
  late final i0.GeneratedColumn<int> goalKcal = i0.GeneratedColumn<int>(
    'goal_kcal',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _goalProteinGMeta =
      const i0.VerificationMeta('goalProteinG');
  @override
  late final i0.GeneratedColumn<int> goalProteinG = i0.GeneratedColumn<int>(
    'goal_protein_g',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _goalFatGMeta = const i0.VerificationMeta(
    'goalFatG',
  );
  @override
  late final i0.GeneratedColumn<int> goalFatG = i0.GeneratedColumn<int>(
    'goal_fat_g',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _goalCarbsGMeta = const i0.VerificationMeta(
    'goalCarbsG',
  );
  @override
  late final i0.GeneratedColumn<int> goalCarbsG = i0.GeneratedColumn<int>(
    'goal_carbs_g',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    userId,
    goalKcal,
    goalProteinG,
    goalFatG,
    goalCarbsG,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.CachedGoalsRow> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('goal_kcal')) {
      context.handle(
        _goalKcalMeta,
        goalKcal.isAcceptableOrUnknown(data['goal_kcal']!, _goalKcalMeta),
      );
    } else if (isInserting) {
      context.missing(_goalKcalMeta);
    }
    if (data.containsKey('goal_protein_g')) {
      context.handle(
        _goalProteinGMeta,
        goalProteinG.isAcceptableOrUnknown(
          data['goal_protein_g']!,
          _goalProteinGMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_goalProteinGMeta);
    }
    if (data.containsKey('goal_fat_g')) {
      context.handle(
        _goalFatGMeta,
        goalFatG.isAcceptableOrUnknown(data['goal_fat_g']!, _goalFatGMeta),
      );
    } else if (isInserting) {
      context.missing(_goalFatGMeta);
    }
    if (data.containsKey('goal_carbs_g')) {
      context.handle(
        _goalCarbsGMeta,
        goalCarbsG.isAcceptableOrUnknown(
          data['goal_carbs_g']!,
          _goalCarbsGMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_goalCarbsGMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {userId};
  @override
  i1.CachedGoalsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.CachedGoalsRow(
      userId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      goalKcal: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}goal_kcal'],
      )!,
      goalProteinG: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}goal_protein_g'],
      )!,
      goalFatG: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}goal_fat_g'],
      )!,
      goalCarbsG: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}goal_carbs_g'],
      )!,
    );
  }

  @override
  $CachedGoalsTable createAlias(String alias) {
    return $CachedGoalsTable(attachedDatabase, alias);
  }
}

class CachedGoalsRow extends i0.DataClass
    implements i0.Insertable<i1.CachedGoalsRow> {
  final String userId;
  final int goalKcal;
  final int goalProteinG;
  final int goalFatG;
  final int goalCarbsG;
  const CachedGoalsRow({
    required this.userId,
    required this.goalKcal,
    required this.goalProteinG,
    required this.goalFatG,
    required this.goalCarbsG,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['user_id'] = i0.Variable<String>(userId);
    map['goal_kcal'] = i0.Variable<int>(goalKcal);
    map['goal_protein_g'] = i0.Variable<int>(goalProteinG);
    map['goal_fat_g'] = i0.Variable<int>(goalFatG);
    map['goal_carbs_g'] = i0.Variable<int>(goalCarbsG);
    return map;
  }

  i1.CachedGoalsCompanion toCompanion(bool nullToAbsent) {
    return i1.CachedGoalsCompanion(
      userId: i0.Value(userId),
      goalKcal: i0.Value(goalKcal),
      goalProteinG: i0.Value(goalProteinG),
      goalFatG: i0.Value(goalFatG),
      goalCarbsG: i0.Value(goalCarbsG),
    );
  }

  factory CachedGoalsRow.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return CachedGoalsRow(
      userId: serializer.fromJson<String>(json['userId']),
      goalKcal: serializer.fromJson<int>(json['goalKcal']),
      goalProteinG: serializer.fromJson<int>(json['goalProteinG']),
      goalFatG: serializer.fromJson<int>(json['goalFatG']),
      goalCarbsG: serializer.fromJson<int>(json['goalCarbsG']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'goalKcal': serializer.toJson<int>(goalKcal),
      'goalProteinG': serializer.toJson<int>(goalProteinG),
      'goalFatG': serializer.toJson<int>(goalFatG),
      'goalCarbsG': serializer.toJson<int>(goalCarbsG),
    };
  }

  i1.CachedGoalsRow copyWith({
    String? userId,
    int? goalKcal,
    int? goalProteinG,
    int? goalFatG,
    int? goalCarbsG,
  }) => i1.CachedGoalsRow(
    userId: userId ?? this.userId,
    goalKcal: goalKcal ?? this.goalKcal,
    goalProteinG: goalProteinG ?? this.goalProteinG,
    goalFatG: goalFatG ?? this.goalFatG,
    goalCarbsG: goalCarbsG ?? this.goalCarbsG,
  );
  CachedGoalsRow copyWithCompanion(i1.CachedGoalsCompanion data) {
    return CachedGoalsRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      goalKcal: data.goalKcal.present ? data.goalKcal.value : this.goalKcal,
      goalProteinG: data.goalProteinG.present
          ? data.goalProteinG.value
          : this.goalProteinG,
      goalFatG: data.goalFatG.present ? data.goalFatG.value : this.goalFatG,
      goalCarbsG: data.goalCarbsG.present
          ? data.goalCarbsG.value
          : this.goalCarbsG,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedGoalsRow(')
          ..write('userId: $userId, ')
          ..write('goalKcal: $goalKcal, ')
          ..write('goalProteinG: $goalProteinG, ')
          ..write('goalFatG: $goalFatG, ')
          ..write('goalCarbsG: $goalCarbsG')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(userId, goalKcal, goalProteinG, goalFatG, goalCarbsG);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.CachedGoalsRow &&
          other.userId == this.userId &&
          other.goalKcal == this.goalKcal &&
          other.goalProteinG == this.goalProteinG &&
          other.goalFatG == this.goalFatG &&
          other.goalCarbsG == this.goalCarbsG);
}

class CachedGoalsCompanion extends i0.UpdateCompanion<i1.CachedGoalsRow> {
  final i0.Value<String> userId;
  final i0.Value<int> goalKcal;
  final i0.Value<int> goalProteinG;
  final i0.Value<int> goalFatG;
  final i0.Value<int> goalCarbsG;
  final i0.Value<int> rowid;
  const CachedGoalsCompanion({
    this.userId = const i0.Value.absent(),
    this.goalKcal = const i0.Value.absent(),
    this.goalProteinG = const i0.Value.absent(),
    this.goalFatG = const i0.Value.absent(),
    this.goalCarbsG = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  CachedGoalsCompanion.insert({
    required String userId,
    required int goalKcal,
    required int goalProteinG,
    required int goalFatG,
    required int goalCarbsG,
    this.rowid = const i0.Value.absent(),
  }) : userId = i0.Value(userId),
       goalKcal = i0.Value(goalKcal),
       goalProteinG = i0.Value(goalProteinG),
       goalFatG = i0.Value(goalFatG),
       goalCarbsG = i0.Value(goalCarbsG);
  static i0.Insertable<i1.CachedGoalsRow> custom({
    i0.Expression<String>? userId,
    i0.Expression<int>? goalKcal,
    i0.Expression<int>? goalProteinG,
    i0.Expression<int>? goalFatG,
    i0.Expression<int>? goalCarbsG,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (goalKcal != null) 'goal_kcal': goalKcal,
      if (goalProteinG != null) 'goal_protein_g': goalProteinG,
      if (goalFatG != null) 'goal_fat_g': goalFatG,
      if (goalCarbsG != null) 'goal_carbs_g': goalCarbsG,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.CachedGoalsCompanion copyWith({
    i0.Value<String>? userId,
    i0.Value<int>? goalKcal,
    i0.Value<int>? goalProteinG,
    i0.Value<int>? goalFatG,
    i0.Value<int>? goalCarbsG,
    i0.Value<int>? rowid,
  }) {
    return i1.CachedGoalsCompanion(
      userId: userId ?? this.userId,
      goalKcal: goalKcal ?? this.goalKcal,
      goalProteinG: goalProteinG ?? this.goalProteinG,
      goalFatG: goalFatG ?? this.goalFatG,
      goalCarbsG: goalCarbsG ?? this.goalCarbsG,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (userId.present) {
      map['user_id'] = i0.Variable<String>(userId.value);
    }
    if (goalKcal.present) {
      map['goal_kcal'] = i0.Variable<int>(goalKcal.value);
    }
    if (goalProteinG.present) {
      map['goal_protein_g'] = i0.Variable<int>(goalProteinG.value);
    }
    if (goalFatG.present) {
      map['goal_fat_g'] = i0.Variable<int>(goalFatG.value);
    }
    if (goalCarbsG.present) {
      map['goal_carbs_g'] = i0.Variable<int>(goalCarbsG.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedGoalsCompanion(')
          ..write('userId: $userId, ')
          ..write('goalKcal: $goalKcal, ')
          ..write('goalProteinG: $goalProteinG, ')
          ..write('goalFatG: $goalFatG, ')
          ..write('goalCarbsG: $goalCarbsG, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}
