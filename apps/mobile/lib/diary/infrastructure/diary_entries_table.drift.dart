// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:lean_tracker/diary/infrastructure/diary_entries_table.drift.dart'
    as i1;
import 'package:lean_tracker/diary/infrastructure/diary_entries_table.dart'
    as i2;

typedef $$DiaryEntriesTableCreateCompanionBuilder =
    i1.DiaryEntriesCompanion Function({
      required String id,
      required String userId,
      required String entryDate,
      required String meal,
      required String productName,
      required String source,
      i0.Value<String?> sourceRef,
      required String baseUnit,
      required double kcalPer100,
      required double proteinPer100,
      required double fatPer100,
      required double carbsPer100,
      required double quantity,
      required String unit,
      i0.Value<double?> servingSize,
      required DateTime updatedAt,
      i0.Value<DateTime?> deletedAt,
      i0.Value<int> rowid,
    });
typedef $$DiaryEntriesTableUpdateCompanionBuilder =
    i1.DiaryEntriesCompanion Function({
      i0.Value<String> id,
      i0.Value<String> userId,
      i0.Value<String> entryDate,
      i0.Value<String> meal,
      i0.Value<String> productName,
      i0.Value<String> source,
      i0.Value<String?> sourceRef,
      i0.Value<String> baseUnit,
      i0.Value<double> kcalPer100,
      i0.Value<double> proteinPer100,
      i0.Value<double> fatPer100,
      i0.Value<double> carbsPer100,
      i0.Value<double> quantity,
      i0.Value<String> unit,
      i0.Value<double?> servingSize,
      i0.Value<DateTime> updatedAt,
      i0.Value<DateTime?> deletedAt,
      i0.Value<int> rowid,
    });

class $$DiaryEntriesTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$DiaryEntriesTable> {
  $$DiaryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get entryDate => $composableBuilder(
    column: $table.entryDate,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get meal => $composableBuilder(
    column: $table.meal,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get sourceRef => $composableBuilder(
    column: $table.sourceRef,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get baseUnit => $composableBuilder(
    column: $table.baseUnit,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<double> get kcalPer100 => $composableBuilder(
    column: $table.kcalPer100,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<double> get proteinPer100 => $composableBuilder(
    column: $table.proteinPer100,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<double> get fatPer100 => $composableBuilder(
    column: $table.fatPer100,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<double> get carbsPer100 => $composableBuilder(
    column: $table.carbsPer100,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<double> get servingSize => $composableBuilder(
    column: $table.servingSize,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $$DiaryEntriesTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$DiaryEntriesTable> {
  $$DiaryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get entryDate => $composableBuilder(
    column: $table.entryDate,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get meal => $composableBuilder(
    column: $table.meal,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get sourceRef => $composableBuilder(
    column: $table.sourceRef,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get baseUnit => $composableBuilder(
    column: $table.baseUnit,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<double> get kcalPer100 => $composableBuilder(
    column: $table.kcalPer100,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<double> get proteinPer100 => $composableBuilder(
    column: $table.proteinPer100,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<double> get fatPer100 => $composableBuilder(
    column: $table.fatPer100,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<double> get carbsPer100 => $composableBuilder(
    column: $table.carbsPer100,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<double> get servingSize => $composableBuilder(
    column: $table.servingSize,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$DiaryEntriesTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$DiaryEntriesTable> {
  $$DiaryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  i0.GeneratedColumn<String> get entryDate =>
      $composableBuilder(column: $table.entryDate, builder: (column) => column);

  i0.GeneratedColumn<String> get meal =>
      $composableBuilder(column: $table.meal, builder: (column) => column);

  i0.GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  i0.GeneratedColumn<String> get sourceRef =>
      $composableBuilder(column: $table.sourceRef, builder: (column) => column);

  i0.GeneratedColumn<String> get baseUnit =>
      $composableBuilder(column: $table.baseUnit, builder: (column) => column);

  i0.GeneratedColumn<double> get kcalPer100 => $composableBuilder(
    column: $table.kcalPer100,
    builder: (column) => column,
  );

  i0.GeneratedColumn<double> get proteinPer100 => $composableBuilder(
    column: $table.proteinPer100,
    builder: (column) => column,
  );

  i0.GeneratedColumn<double> get fatPer100 =>
      $composableBuilder(column: $table.fatPer100, builder: (column) => column);

  i0.GeneratedColumn<double> get carbsPer100 => $composableBuilder(
    column: $table.carbsPer100,
    builder: (column) => column,
  );

  i0.GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  i0.GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  i0.GeneratedColumn<double> get servingSize => $composableBuilder(
    column: $table.servingSize,
    builder: (column) => column,
  );

  i0.GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$DiaryEntriesTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$DiaryEntriesTable,
          i1.DiaryEntryRow,
          i1.$$DiaryEntriesTableFilterComposer,
          i1.$$DiaryEntriesTableOrderingComposer,
          i1.$$DiaryEntriesTableAnnotationComposer,
          $$DiaryEntriesTableCreateCompanionBuilder,
          $$DiaryEntriesTableUpdateCompanionBuilder,
          (
            i1.DiaryEntryRow,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.$DiaryEntriesTable,
              i1.DiaryEntryRow
            >,
          ),
          i1.DiaryEntryRow,
          i0.PrefetchHooks Function()
        > {
  $$DiaryEntriesTableTableManager(
    i0.GeneratedDatabase db,
    i1.$DiaryEntriesTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$DiaryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$DiaryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$DiaryEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String> userId = const i0.Value.absent(),
                i0.Value<String> entryDate = const i0.Value.absent(),
                i0.Value<String> meal = const i0.Value.absent(),
                i0.Value<String> productName = const i0.Value.absent(),
                i0.Value<String> source = const i0.Value.absent(),
                i0.Value<String?> sourceRef = const i0.Value.absent(),
                i0.Value<String> baseUnit = const i0.Value.absent(),
                i0.Value<double> kcalPer100 = const i0.Value.absent(),
                i0.Value<double> proteinPer100 = const i0.Value.absent(),
                i0.Value<double> fatPer100 = const i0.Value.absent(),
                i0.Value<double> carbsPer100 = const i0.Value.absent(),
                i0.Value<double> quantity = const i0.Value.absent(),
                i0.Value<String> unit = const i0.Value.absent(),
                i0.Value<double?> servingSize = const i0.Value.absent(),
                i0.Value<DateTime> updatedAt = const i0.Value.absent(),
                i0.Value<DateTime?> deletedAt = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.DiaryEntriesCompanion(
                id: id,
                userId: userId,
                entryDate: entryDate,
                meal: meal,
                productName: productName,
                source: source,
                sourceRef: sourceRef,
                baseUnit: baseUnit,
                kcalPer100: kcalPer100,
                proteinPer100: proteinPer100,
                fatPer100: fatPer100,
                carbsPer100: carbsPer100,
                quantity: quantity,
                unit: unit,
                servingSize: servingSize,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String entryDate,
                required String meal,
                required String productName,
                required String source,
                i0.Value<String?> sourceRef = const i0.Value.absent(),
                required String baseUnit,
                required double kcalPer100,
                required double proteinPer100,
                required double fatPer100,
                required double carbsPer100,
                required double quantity,
                required String unit,
                i0.Value<double?> servingSize = const i0.Value.absent(),
                required DateTime updatedAt,
                i0.Value<DateTime?> deletedAt = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.DiaryEntriesCompanion.insert(
                id: id,
                userId: userId,
                entryDate: entryDate,
                meal: meal,
                productName: productName,
                source: source,
                sourceRef: sourceRef,
                baseUnit: baseUnit,
                kcalPer100: kcalPer100,
                proteinPer100: proteinPer100,
                fatPer100: fatPer100,
                carbsPer100: carbsPer100,
                quantity: quantity,
                unit: unit,
                servingSize: servingSize,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DiaryEntriesTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$DiaryEntriesTable,
      i1.DiaryEntryRow,
      i1.$$DiaryEntriesTableFilterComposer,
      i1.$$DiaryEntriesTableOrderingComposer,
      i1.$$DiaryEntriesTableAnnotationComposer,
      $$DiaryEntriesTableCreateCompanionBuilder,
      $$DiaryEntriesTableUpdateCompanionBuilder,
      (
        i1.DiaryEntryRow,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$DiaryEntriesTable,
          i1.DiaryEntryRow
        >,
      ),
      i1.DiaryEntryRow,
      i0.PrefetchHooks Function()
    >;
i0.Index get diaryEntriesUserDateIdx => i0.Index(
  'diary_entries_user_date_idx',
  'CREATE INDEX diary_entries_user_date_idx ON diary_entries (user_id, entry_date)',
);

class $DiaryEntriesTable extends i2.DiaryEntries
    with i0.TableInfo<$DiaryEntriesTable, i1.DiaryEntryRow> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiaryEntriesTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<String> id = i0.GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
  static const i0.VerificationMeta _entryDateMeta = const i0.VerificationMeta(
    'entryDate',
  );
  @override
  late final i0.GeneratedColumn<String> entryDate = i0.GeneratedColumn<String>(
    'entry_date',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _mealMeta = const i0.VerificationMeta(
    'meal',
  );
  @override
  late final i0.GeneratedColumn<String> meal = i0.GeneratedColumn<String>(
    'meal',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _productNameMeta = const i0.VerificationMeta(
    'productName',
  );
  @override
  late final i0.GeneratedColumn<String> productName =
      i0.GeneratedColumn<String>(
        'product_name',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const i0.VerificationMeta _sourceMeta = const i0.VerificationMeta(
    'source',
  );
  @override
  late final i0.GeneratedColumn<String> source = i0.GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _sourceRefMeta = const i0.VerificationMeta(
    'sourceRef',
  );
  @override
  late final i0.GeneratedColumn<String> sourceRef = i0.GeneratedColumn<String>(
    'source_ref',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _baseUnitMeta = const i0.VerificationMeta(
    'baseUnit',
  );
  @override
  late final i0.GeneratedColumn<String> baseUnit = i0.GeneratedColumn<String>(
    'base_unit',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _kcalPer100Meta = const i0.VerificationMeta(
    'kcalPer100',
  );
  @override
  late final i0.GeneratedColumn<double> kcalPer100 = i0.GeneratedColumn<double>(
    'kcal_per100',
    aliasedName,
    false,
    type: i0.DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _proteinPer100Meta =
      const i0.VerificationMeta('proteinPer100');
  @override
  late final i0.GeneratedColumn<double> proteinPer100 =
      i0.GeneratedColumn<double>(
        'protein_per100',
        aliasedName,
        false,
        type: i0.DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const i0.VerificationMeta _fatPer100Meta = const i0.VerificationMeta(
    'fatPer100',
  );
  @override
  late final i0.GeneratedColumn<double> fatPer100 = i0.GeneratedColumn<double>(
    'fat_per100',
    aliasedName,
    false,
    type: i0.DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _carbsPer100Meta = const i0.VerificationMeta(
    'carbsPer100',
  );
  @override
  late final i0.GeneratedColumn<double> carbsPer100 =
      i0.GeneratedColumn<double>(
        'carbs_per100',
        aliasedName,
        false,
        type: i0.DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const i0.VerificationMeta _quantityMeta = const i0.VerificationMeta(
    'quantity',
  );
  @override
  late final i0.GeneratedColumn<double> quantity = i0.GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: i0.DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _unitMeta = const i0.VerificationMeta(
    'unit',
  );
  @override
  late final i0.GeneratedColumn<String> unit = i0.GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _servingSizeMeta = const i0.VerificationMeta(
    'servingSize',
  );
  @override
  late final i0.GeneratedColumn<double> servingSize =
      i0.GeneratedColumn<double>(
        'serving_size',
        aliasedName,
        true,
        type: i0.DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _updatedAtMeta = const i0.VerificationMeta(
    'updatedAt',
  );
  @override
  late final i0.GeneratedColumn<DateTime> updatedAt =
      i0.GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        false,
        type: i0.DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const i0.VerificationMeta _deletedAtMeta = const i0.VerificationMeta(
    'deletedAt',
  );
  @override
  late final i0.GeneratedColumn<DateTime> deletedAt =
      i0.GeneratedColumn<DateTime>(
        'deleted_at',
        aliasedName,
        true,
        type: i0.DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<i0.GeneratedColumn> get $columns => [
    id,
    userId,
    entryDate,
    meal,
    productName,
    source,
    sourceRef,
    baseUnit,
    kcalPer100,
    proteinPer100,
    fatPer100,
    carbsPer100,
    quantity,
    unit,
    servingSize,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diary_entries';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.DiaryEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
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
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('entry_date')) {
      context.handle(
        _entryDateMeta,
        entryDate.isAcceptableOrUnknown(data['entry_date']!, _entryDateMeta),
      );
    } else if (isInserting) {
      context.missing(_entryDateMeta);
    }
    if (data.containsKey('meal')) {
      context.handle(
        _mealMeta,
        meal.isAcceptableOrUnknown(data['meal']!, _mealMeta),
      );
    } else if (isInserting) {
      context.missing(_mealMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('source_ref')) {
      context.handle(
        _sourceRefMeta,
        sourceRef.isAcceptableOrUnknown(data['source_ref']!, _sourceRefMeta),
      );
    }
    if (data.containsKey('base_unit')) {
      context.handle(
        _baseUnitMeta,
        baseUnit.isAcceptableOrUnknown(data['base_unit']!, _baseUnitMeta),
      );
    } else if (isInserting) {
      context.missing(_baseUnitMeta);
    }
    if (data.containsKey('kcal_per100')) {
      context.handle(
        _kcalPer100Meta,
        kcalPer100.isAcceptableOrUnknown(data['kcal_per100']!, _kcalPer100Meta),
      );
    } else if (isInserting) {
      context.missing(_kcalPer100Meta);
    }
    if (data.containsKey('protein_per100')) {
      context.handle(
        _proteinPer100Meta,
        proteinPer100.isAcceptableOrUnknown(
          data['protein_per100']!,
          _proteinPer100Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_proteinPer100Meta);
    }
    if (data.containsKey('fat_per100')) {
      context.handle(
        _fatPer100Meta,
        fatPer100.isAcceptableOrUnknown(data['fat_per100']!, _fatPer100Meta),
      );
    } else if (isInserting) {
      context.missing(_fatPer100Meta);
    }
    if (data.containsKey('carbs_per100')) {
      context.handle(
        _carbsPer100Meta,
        carbsPer100.isAcceptableOrUnknown(
          data['carbs_per100']!,
          _carbsPer100Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_carbsPer100Meta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('serving_size')) {
      context.handle(
        _servingSizeMeta,
        servingSize.isAcceptableOrUnknown(
          data['serving_size']!,
          _servingSizeMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.DiaryEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.DiaryEntryRow(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      entryDate: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}entry_date'],
      )!,
      meal: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}meal'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      source: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceRef: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}source_ref'],
      ),
      baseUnit: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}base_unit'],
      )!,
      kcalPer100: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.double,
        data['${effectivePrefix}kcal_per100'],
      )!,
      proteinPer100: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.double,
        data['${effectivePrefix}protein_per100'],
      )!,
      fatPer100: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.double,
        data['${effectivePrefix}fat_per100'],
      )!,
      carbsPer100: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.double,
        data['${effectivePrefix}carbs_per100'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      servingSize: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.double,
        data['${effectivePrefix}serving_size'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $DiaryEntriesTable createAlias(String alias) {
    return $DiaryEntriesTable(attachedDatabase, alias);
  }
}

class DiaryEntryRow extends i0.DataClass
    implements i0.Insertable<i1.DiaryEntryRow> {
  final String id;
  final String userId;
  final String entryDate;
  final String meal;
  final String productName;
  final String source;
  final String? sourceRef;
  final String baseUnit;
  final double kcalPer100;
  final double proteinPer100;
  final double fatPer100;
  final double carbsPer100;
  final double quantity;
  final String unit;
  final double? servingSize;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const DiaryEntryRow({
    required this.id,
    required this.userId,
    required this.entryDate,
    required this.meal,
    required this.productName,
    required this.source,
    this.sourceRef,
    required this.baseUnit,
    required this.kcalPer100,
    required this.proteinPer100,
    required this.fatPer100,
    required this.carbsPer100,
    required this.quantity,
    required this.unit,
    this.servingSize,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<String>(id);
    map['user_id'] = i0.Variable<String>(userId);
    map['entry_date'] = i0.Variable<String>(entryDate);
    map['meal'] = i0.Variable<String>(meal);
    map['product_name'] = i0.Variable<String>(productName);
    map['source'] = i0.Variable<String>(source);
    if (!nullToAbsent || sourceRef != null) {
      map['source_ref'] = i0.Variable<String>(sourceRef);
    }
    map['base_unit'] = i0.Variable<String>(baseUnit);
    map['kcal_per100'] = i0.Variable<double>(kcalPer100);
    map['protein_per100'] = i0.Variable<double>(proteinPer100);
    map['fat_per100'] = i0.Variable<double>(fatPer100);
    map['carbs_per100'] = i0.Variable<double>(carbsPer100);
    map['quantity'] = i0.Variable<double>(quantity);
    map['unit'] = i0.Variable<String>(unit);
    if (!nullToAbsent || servingSize != null) {
      map['serving_size'] = i0.Variable<double>(servingSize);
    }
    map['updated_at'] = i0.Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = i0.Variable<DateTime>(deletedAt);
    }
    return map;
  }

  i1.DiaryEntriesCompanion toCompanion(bool nullToAbsent) {
    return i1.DiaryEntriesCompanion(
      id: i0.Value(id),
      userId: i0.Value(userId),
      entryDate: i0.Value(entryDate),
      meal: i0.Value(meal),
      productName: i0.Value(productName),
      source: i0.Value(source),
      sourceRef: sourceRef == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(sourceRef),
      baseUnit: i0.Value(baseUnit),
      kcalPer100: i0.Value(kcalPer100),
      proteinPer100: i0.Value(proteinPer100),
      fatPer100: i0.Value(fatPer100),
      carbsPer100: i0.Value(carbsPer100),
      quantity: i0.Value(quantity),
      unit: i0.Value(unit),
      servingSize: servingSize == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(servingSize),
      updatedAt: i0.Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(deletedAt),
    );
  }

  factory DiaryEntryRow.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return DiaryEntryRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      entryDate: serializer.fromJson<String>(json['entryDate']),
      meal: serializer.fromJson<String>(json['meal']),
      productName: serializer.fromJson<String>(json['productName']),
      source: serializer.fromJson<String>(json['source']),
      sourceRef: serializer.fromJson<String?>(json['sourceRef']),
      baseUnit: serializer.fromJson<String>(json['baseUnit']),
      kcalPer100: serializer.fromJson<double>(json['kcalPer100']),
      proteinPer100: serializer.fromJson<double>(json['proteinPer100']),
      fatPer100: serializer.fromJson<double>(json['fatPer100']),
      carbsPer100: serializer.fromJson<double>(json['carbsPer100']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unit: serializer.fromJson<String>(json['unit']),
      servingSize: serializer.fromJson<double?>(json['servingSize']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'entryDate': serializer.toJson<String>(entryDate),
      'meal': serializer.toJson<String>(meal),
      'productName': serializer.toJson<String>(productName),
      'source': serializer.toJson<String>(source),
      'sourceRef': serializer.toJson<String?>(sourceRef),
      'baseUnit': serializer.toJson<String>(baseUnit),
      'kcalPer100': serializer.toJson<double>(kcalPer100),
      'proteinPer100': serializer.toJson<double>(proteinPer100),
      'fatPer100': serializer.toJson<double>(fatPer100),
      'carbsPer100': serializer.toJson<double>(carbsPer100),
      'quantity': serializer.toJson<double>(quantity),
      'unit': serializer.toJson<String>(unit),
      'servingSize': serializer.toJson<double?>(servingSize),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  i1.DiaryEntryRow copyWith({
    String? id,
    String? userId,
    String? entryDate,
    String? meal,
    String? productName,
    String? source,
    i0.Value<String?> sourceRef = const i0.Value.absent(),
    String? baseUnit,
    double? kcalPer100,
    double? proteinPer100,
    double? fatPer100,
    double? carbsPer100,
    double? quantity,
    String? unit,
    i0.Value<double?> servingSize = const i0.Value.absent(),
    DateTime? updatedAt,
    i0.Value<DateTime?> deletedAt = const i0.Value.absent(),
  }) => i1.DiaryEntryRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    entryDate: entryDate ?? this.entryDate,
    meal: meal ?? this.meal,
    productName: productName ?? this.productName,
    source: source ?? this.source,
    sourceRef: sourceRef.present ? sourceRef.value : this.sourceRef,
    baseUnit: baseUnit ?? this.baseUnit,
    kcalPer100: kcalPer100 ?? this.kcalPer100,
    proteinPer100: proteinPer100 ?? this.proteinPer100,
    fatPer100: fatPer100 ?? this.fatPer100,
    carbsPer100: carbsPer100 ?? this.carbsPer100,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    servingSize: servingSize.present ? servingSize.value : this.servingSize,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  DiaryEntryRow copyWithCompanion(i1.DiaryEntriesCompanion data) {
    return DiaryEntryRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      entryDate: data.entryDate.present ? data.entryDate.value : this.entryDate,
      meal: data.meal.present ? data.meal.value : this.meal,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      source: data.source.present ? data.source.value : this.source,
      sourceRef: data.sourceRef.present ? data.sourceRef.value : this.sourceRef,
      baseUnit: data.baseUnit.present ? data.baseUnit.value : this.baseUnit,
      kcalPer100: data.kcalPer100.present
          ? data.kcalPer100.value
          : this.kcalPer100,
      proteinPer100: data.proteinPer100.present
          ? data.proteinPer100.value
          : this.proteinPer100,
      fatPer100: data.fatPer100.present ? data.fatPer100.value : this.fatPer100,
      carbsPer100: data.carbsPer100.present
          ? data.carbsPer100.value
          : this.carbsPer100,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      servingSize: data.servingSize.present
          ? data.servingSize.value
          : this.servingSize,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiaryEntryRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('entryDate: $entryDate, ')
          ..write('meal: $meal, ')
          ..write('productName: $productName, ')
          ..write('source: $source, ')
          ..write('sourceRef: $sourceRef, ')
          ..write('baseUnit: $baseUnit, ')
          ..write('kcalPer100: $kcalPer100, ')
          ..write('proteinPer100: $proteinPer100, ')
          ..write('fatPer100: $fatPer100, ')
          ..write('carbsPer100: $carbsPer100, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('servingSize: $servingSize, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    entryDate,
    meal,
    productName,
    source,
    sourceRef,
    baseUnit,
    kcalPer100,
    proteinPer100,
    fatPer100,
    carbsPer100,
    quantity,
    unit,
    servingSize,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.DiaryEntryRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.entryDate == this.entryDate &&
          other.meal == this.meal &&
          other.productName == this.productName &&
          other.source == this.source &&
          other.sourceRef == this.sourceRef &&
          other.baseUnit == this.baseUnit &&
          other.kcalPer100 == this.kcalPer100 &&
          other.proteinPer100 == this.proteinPer100 &&
          other.fatPer100 == this.fatPer100 &&
          other.carbsPer100 == this.carbsPer100 &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.servingSize == this.servingSize &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class DiaryEntriesCompanion extends i0.UpdateCompanion<i1.DiaryEntryRow> {
  final i0.Value<String> id;
  final i0.Value<String> userId;
  final i0.Value<String> entryDate;
  final i0.Value<String> meal;
  final i0.Value<String> productName;
  final i0.Value<String> source;
  final i0.Value<String?> sourceRef;
  final i0.Value<String> baseUnit;
  final i0.Value<double> kcalPer100;
  final i0.Value<double> proteinPer100;
  final i0.Value<double> fatPer100;
  final i0.Value<double> carbsPer100;
  final i0.Value<double> quantity;
  final i0.Value<String> unit;
  final i0.Value<double?> servingSize;
  final i0.Value<DateTime> updatedAt;
  final i0.Value<DateTime?> deletedAt;
  final i0.Value<int> rowid;
  const DiaryEntriesCompanion({
    this.id = const i0.Value.absent(),
    this.userId = const i0.Value.absent(),
    this.entryDate = const i0.Value.absent(),
    this.meal = const i0.Value.absent(),
    this.productName = const i0.Value.absent(),
    this.source = const i0.Value.absent(),
    this.sourceRef = const i0.Value.absent(),
    this.baseUnit = const i0.Value.absent(),
    this.kcalPer100 = const i0.Value.absent(),
    this.proteinPer100 = const i0.Value.absent(),
    this.fatPer100 = const i0.Value.absent(),
    this.carbsPer100 = const i0.Value.absent(),
    this.quantity = const i0.Value.absent(),
    this.unit = const i0.Value.absent(),
    this.servingSize = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
    this.deletedAt = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  DiaryEntriesCompanion.insert({
    required String id,
    required String userId,
    required String entryDate,
    required String meal,
    required String productName,
    required String source,
    this.sourceRef = const i0.Value.absent(),
    required String baseUnit,
    required double kcalPer100,
    required double proteinPer100,
    required double fatPer100,
    required double carbsPer100,
    required double quantity,
    required String unit,
    this.servingSize = const i0.Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  }) : id = i0.Value(id),
       userId = i0.Value(userId),
       entryDate = i0.Value(entryDate),
       meal = i0.Value(meal),
       productName = i0.Value(productName),
       source = i0.Value(source),
       baseUnit = i0.Value(baseUnit),
       kcalPer100 = i0.Value(kcalPer100),
       proteinPer100 = i0.Value(proteinPer100),
       fatPer100 = i0.Value(fatPer100),
       carbsPer100 = i0.Value(carbsPer100),
       quantity = i0.Value(quantity),
       unit = i0.Value(unit),
       updatedAt = i0.Value(updatedAt);
  static i0.Insertable<i1.DiaryEntryRow> custom({
    i0.Expression<String>? id,
    i0.Expression<String>? userId,
    i0.Expression<String>? entryDate,
    i0.Expression<String>? meal,
    i0.Expression<String>? productName,
    i0.Expression<String>? source,
    i0.Expression<String>? sourceRef,
    i0.Expression<String>? baseUnit,
    i0.Expression<double>? kcalPer100,
    i0.Expression<double>? proteinPer100,
    i0.Expression<double>? fatPer100,
    i0.Expression<double>? carbsPer100,
    i0.Expression<double>? quantity,
    i0.Expression<String>? unit,
    i0.Expression<double>? servingSize,
    i0.Expression<DateTime>? updatedAt,
    i0.Expression<DateTime>? deletedAt,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (entryDate != null) 'entry_date': entryDate,
      if (meal != null) 'meal': meal,
      if (productName != null) 'product_name': productName,
      if (source != null) 'source': source,
      if (sourceRef != null) 'source_ref': sourceRef,
      if (baseUnit != null) 'base_unit': baseUnit,
      if (kcalPer100 != null) 'kcal_per100': kcalPer100,
      if (proteinPer100 != null) 'protein_per100': proteinPer100,
      if (fatPer100 != null) 'fat_per100': fatPer100,
      if (carbsPer100 != null) 'carbs_per100': carbsPer100,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (servingSize != null) 'serving_size': servingSize,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.DiaryEntriesCompanion copyWith({
    i0.Value<String>? id,
    i0.Value<String>? userId,
    i0.Value<String>? entryDate,
    i0.Value<String>? meal,
    i0.Value<String>? productName,
    i0.Value<String>? source,
    i0.Value<String?>? sourceRef,
    i0.Value<String>? baseUnit,
    i0.Value<double>? kcalPer100,
    i0.Value<double>? proteinPer100,
    i0.Value<double>? fatPer100,
    i0.Value<double>? carbsPer100,
    i0.Value<double>? quantity,
    i0.Value<String>? unit,
    i0.Value<double?>? servingSize,
    i0.Value<DateTime>? updatedAt,
    i0.Value<DateTime?>? deletedAt,
    i0.Value<int>? rowid,
  }) {
    return i1.DiaryEntriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entryDate: entryDate ?? this.entryDate,
      meal: meal ?? this.meal,
      productName: productName ?? this.productName,
      source: source ?? this.source,
      sourceRef: sourceRef ?? this.sourceRef,
      baseUnit: baseUnit ?? this.baseUnit,
      kcalPer100: kcalPer100 ?? this.kcalPer100,
      proteinPer100: proteinPer100 ?? this.proteinPer100,
      fatPer100: fatPer100 ?? this.fatPer100,
      carbsPer100: carbsPer100 ?? this.carbsPer100,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      servingSize: servingSize ?? this.servingSize,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = i0.Variable<String>(userId.value);
    }
    if (entryDate.present) {
      map['entry_date'] = i0.Variable<String>(entryDate.value);
    }
    if (meal.present) {
      map['meal'] = i0.Variable<String>(meal.value);
    }
    if (productName.present) {
      map['product_name'] = i0.Variable<String>(productName.value);
    }
    if (source.present) {
      map['source'] = i0.Variable<String>(source.value);
    }
    if (sourceRef.present) {
      map['source_ref'] = i0.Variable<String>(sourceRef.value);
    }
    if (baseUnit.present) {
      map['base_unit'] = i0.Variable<String>(baseUnit.value);
    }
    if (kcalPer100.present) {
      map['kcal_per100'] = i0.Variable<double>(kcalPer100.value);
    }
    if (proteinPer100.present) {
      map['protein_per100'] = i0.Variable<double>(proteinPer100.value);
    }
    if (fatPer100.present) {
      map['fat_per100'] = i0.Variable<double>(fatPer100.value);
    }
    if (carbsPer100.present) {
      map['carbs_per100'] = i0.Variable<double>(carbsPer100.value);
    }
    if (quantity.present) {
      map['quantity'] = i0.Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = i0.Variable<String>(unit.value);
    }
    if (servingSize.present) {
      map['serving_size'] = i0.Variable<double>(servingSize.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = i0.Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = i0.Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiaryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('entryDate: $entryDate, ')
          ..write('meal: $meal, ')
          ..write('productName: $productName, ')
          ..write('source: $source, ')
          ..write('sourceRef: $sourceRef, ')
          ..write('baseUnit: $baseUnit, ')
          ..write('kcalPer100: $kcalPer100, ')
          ..write('proteinPer100: $proteinPer100, ')
          ..write('fatPer100: $fatPer100, ')
          ..write('carbsPer100: $carbsPer100, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('servingSize: $servingSize, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}
