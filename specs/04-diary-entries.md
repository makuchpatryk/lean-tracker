# Local Database, Diary and Entries (M3) — Implementation Plan

## Summary
M3 gives the app its first local data. A Drift (SQLite) database holds diary entries and a cache of the daily goals, so the Diary works without network. The Diary screen shows the selected day with totals, remaining kcal and four meal cards. A meal opens its details. Entries are created from a debug-only seed list through the quantity form, and they can be edited and soft-deleted, all offline. There is no API or contract change: diary endpoints come with sync in M6. Milestone **M3** (PRD §19). Base: `main` at `220188c`, clean tree. No unmerged branch is relied on.

## Success Criteria
- FR-003 (covered, tests written): given entries of 300 kcal and 200 kcal and a goal of 2000, the day shows consumed 500 and remaining 1500. A day over the goal shows remaining with a minus sign. Evidence: `test/diary/domain/day_totals_test.dart` and `test/diary/presentation/diary_screen_test.dart`.
- FR-004 (covered, tests written): 150 g of a 200 kcal/100 g product saves an entry of 300 kcal. 2 servings of a product with `serving_size` 30 g and 100 kcal/100 g give 60 g and 60 kcal. Editing changes only quantity, unit, meal and date, never the snapshot (BR-007). Evidence: `test/diary/domain/nutrition_test.dart`, `test/diary/application/*_test.dart`.
- BR-004 to BR-007 have unit tests that need no network, database or widgets (NFR-008).
- M3 definition of done: create, edit and delete work against the local database with no network, and the goals come from the local cache when the API is unreachable. Evidence: `test/diary/infrastructure/drift_entry_repository_test.dart`, `test/settings/infrastructure/caching_goals_repository_test.dart`.
- `make lint` clean and `make test` green. `apps/api/` and both `openapi.yaml` copies are unchanged.

## Scope & Constraints
- **In scope:**
  - Drift schema v1 with `diary_entries` and a goals cache table.
  - FR-003 and FR-004.
  - UF-002: date arrows and a date picker, summary card, four meal cards, meal details, tap an entry to edit or delete.
  - UF-003 step 3, the quantity form with quantity, unit, meal, date and a live preview. The product comes from a debug-only seed list.
  - Goals read from the cache when offline (BR-014).
  - BR-004, BR-005, BR-006, BR-007 and the quantity part of BR-003.
  - ARB keys in EN and PL.
- **Out of scope:**
  - M4: the products table, own-product form, scan, name search, and the Search, Favorites and Recents tabs.
  - M5: favorites, recents (BR-010), copy meal (its button on Meal details), the Tydzień tab and weekly summary.
  - M6: sync, the diary API, `SyncSource`.
  - M7: reminders, account deletion and wiping the local database.
  - Goal edits while offline: they stay online-only (`PUT /v1/settings`) until M6.
  - The 5-day strip and the 50/100/150/200 quick-amount chips from DESIGN, left out by user choice.
  - PRD §10.3 and §23 items.
- **Hard constraints:**
  - BR-001: every local row carries `user_id`, and one repository instance, scoped to the signed-in user, filters every query by it.
  - BR-003: quantity from 0.1 to 10000 with at most one decimal.
  - BR-004: the day is the local device date, and the default date is today from an injected `Clock`.
  - BR-005: four fixed meals.
  - BR-006: `serving` only when the snapshot has `serving_size`, and no conversion between g and ml.
  - BR-007: the snapshot is copied on save.
  - BR-014: no network needed for the diary.
  - NFR-002: local save in ≤ 300 ms (one indexed write, not measured here).
  - §16: works at 360 dp and at 200 % font, has `Semantics` labels, light and dark themes.
  - FR-017: PL and EN.
  - Soft delete through `deleted_at` (PRD §13).
- **Trade-offs:**
  - Numbers are `REAL`/`double` (user choice) rather than integer tenths: column names stay 1:1 with PRD §13 and the code stays simpler. Domain code rounds the quantity to one decimal, and display code rounds once.
  - One database file with `user_id` (user choice) rather than one file per user: the server shape stays the same and M6 is simpler.
  - The cached goals can be stale while offline. This is accepted because edits are online-only.
  - Release builds have no product source in M3. M3 is not distributed (M8).

## Architecture & Design

### High-Level Flow
```
DiaryScreen ── watch ── dayProvider(date) ── WatchDay ── EntryRepository.watchDay(date)
   │                                          + DailyGoals (app/ maps settings goalsProvider)
   ├─ tap meal card ─▶ MealDetailsScreen(date, meal) ── same day stream, filtered to one meal
   │                      └─ tap entry ─▶ EntryFormScreen(edit) ─▶ EditEntry / DeleteEntry
   └─ plus / "Dodaj produkt" ─▶ AddEntryScreen(meal, date) ── ProductSource.products()
                                   └─ tap product ─▶ EntryFormScreen(create) ─▶ AddEntry
AddEntry / EditEntry / DeleteEntry ─▶ EntryRepository (port) ─▶ DriftEntryRepository(db, userId) ─▶ SQLite

Goals: goalsProvider ─▶ LoadGoals ─▶ CachingGoalsRepository
          ├─ ApiGoalsRepository (GET /v1/settings) ── found ─▶ write cache ─▶ GoalsFound
          │                                         ── missing ─▶ clear cache ─▶ GoalsMissing
          └─ unavailable ─▶ GoalsCache.read(userId) ─▶ GoalsFound | GoalsUnavailable
```
The API is not involved in M3 except for the existing `GET/PUT /v1/settings`.

### Key Changes

**Dependencies (`apps/mobile/pubspec.yaml`)**
- `drift` and `drift_flutter` in `dependencies`, and `drift_dev` in `dev_dependencies` (`build_runner` already present).
  - Drift is PRD §18 and D-29.
  - `drift_flutter` is not in §18. The owner approved it (2026-11-27) and it is recorded as D-75. It opens the database in a background isolate in the app documents directory and bundles SQLite, so no `path_provider` or `sqlite3_flutter_libs` are added by hand.
  - No `uuid` package: `kernel/uuid.dart` is about 15 lines over `Random.secure()`, which is enough (KISS).
- `apps/mobile/build.yaml` (new) turns on Drift modular generation, so that each module's table file gets its own `*.drift.dart` with a typed table class that a repository can query through a plain `GeneratedDatabase`, without importing `app/` (user choice: typed queries):
  ```yaml
  targets:
    $default:
      builders:
        drift_dev:
          enabled: false
        drift_dev:analyzer:
          enabled: true
          options: &options
            store_date_time_values_as_text: false
        drift_dev:modular:
          enabled: true
          options: *options
  ```
- `Makefile` `lint-dart`: add `lib/diary` to the `dart format` path list.
- `analysis_options.yaml`: exclude `lib/**/*.drift.dart` from the analyzer (generated, never edited, like `lib/gen/**`).

**Kernel (`apps/mobile/lib/kernel/`)**
- `clock.dart`: `abstract interface class Clock { DateTime now(); }` and `final class SystemClock implements Clock`.
- `uuid.dart`: `abstract interface class Uuid { String v4(); }` and `final class RandomUuid implements Uuid`, which uses `Random.secure()` and sets the version and variant bits.
- `local_date.dart`: `final class LocalDate implements Comparable<LocalDate>` with these members:
  - `year`, `month`, `day`.
  - `LocalDate.of(DateTime local)`: local fields only (BR-004).
  - `addDays(int)`: computed through `DateTime.utc(y, m, d + n)`, so DST cannot shift the date.
  - `toIso()` returns `yyyy-MM-dd`, and `LocalDate.parseIso(String)` reads it back.
  - `==`, `hashCode`, `compareTo`.
- `limits/limits.dart`: add `quantityMin = 0.1`, `quantityMax = 10000` and `quantityDecimals = 1` (BR-003). These are app-side for now, like `passwordMinLength`, because the contract has no diary schema until M6, when they become AD6-checked.

**Diary module (`apps/mobile/lib/diary/`, new)**
- `diary.dart`: the only public file. It exports the providers and screens `app/` uses, `DriftEntryRepository`, `DevSeedProductSource`, the `DiaryEntries` table, `DailyGoals`, `ProductSource` and `ProductSnapshot`.
- `domain/` (pure Dart and `kernel` only):
  - `meal.dart`: `enum Meal { breakfast, lunch, dinner, snack }` (BR-005).
  - `units.dart`: `enum BaseUnit { g, ml }` and `enum EntryUnit { g, ml, serving }`. `List<EntryUnit> unitsFor(ProductSnapshot p)` returns the base unit, plus `serving` only when `p.servingSize != null` (BR-006).
  - `product_snapshot.dart`: `final class ProductSnapshot` with these fields:
    - `name`, `baseUnit`.
    - `kcalPer100`, `proteinPer100`, `fatPer100`, `carbsPer100` (double).
    - `servingSize` (double?).
    - `source` (`EntrySource { off, own, manual }`) and `sourceRef` (String?).
  - `quantity.dart`: `sealed class QuantityInput` with `ValidQuantity(double value)` and `InvalidQuantity`. `QuantityInput parseQuantity(String raw)` works as follows:
    - It trims the text and accepts `,` or `.` as the separator.
    - It rejects empty text, non-numbers, more than one decimal and values outside `Limits.quantityMin..quantityMax`.
    - The value is kept as `(v * 10).round() / 10`.
  - `quantity.dart` also has `double stepQuantity(double current, EntryUnit unit, int direction)` for the −/+ buttons: ±10 for g and ml, ±1 for serving, clamped to the limits (user choice). The result is rounded to one decimal.
  - `nutrition.dart` (BR-006):
    - `final class Nutrition { kcal, protein, fat, carbs }` (double), with `operator +` and `Nutrition.zero`.
    - `double baseQuantity(ProductSnapshot p, double quantity, EntryUnit unit)`: `quantity * servingSize` for `serving`, otherwise `quantity`.
    - `Nutrition entryNutrition(ProductSnapshot p, double quantity, EntryUnit unit)`: `valuePer100 * baseQuantity / 100` for each value. No rounding.
  - `diary_entry.dart`: `final class DiaryEntry` with these fields:
    - `id`, `entryDate` (`LocalDate`), `meal`.
    - `snapshot` (`ProductSnapshot`), `quantity`, `unit`.
    - `updatedAt`, `deletedAt?`.
    - The getter `nutrition` calls `entryNutrition`.

    It has these operations:
    - `DiaryEntry.create(...)` returns `EntryResult` (sealed: `EntryOk(DiaryEntry)`, or `EntryRejected(EntryError)` with `EntryError { servingUnavailable, unitMismatch }`, BR-006).
    - `revise({quantity, unit, meal, entryDate, now})` keeps the snapshot (FR-004 edge case, BR-007) and checks the unit again.
    - `delete(now)` sets `deletedAt` and `updatedAt` to `now`.
  - `day_totals.dart` (FR-003):
    - `final class DayTotals { Map<Meal, Nutrition> perMeal; Nutrition total; double remainingKcal; }`.
    - `DayTotals.of(List<DiaryEntry> entries, int goalKcal)`: all four meals are always present, sums use unrounded values, and `remainingKcal = goalKcal - total.kcal`.
- `application/` (own `domain` and `kernel` only):
  - `entry_repository.dart`: the port. `Stream<List<DiaryEntry>> watchDay(LocalDate date)`, `Future<DiaryEntry?> findById(String id)` and `Future<SaveResult> save(DiaryEntry entry)` (sealed: `Saved` or `SaveFailed`, AD5). There is no user id parameter: the adapter is scoped to one user (BR-001).
  - `product_source.dart`: the port `abstract interface class ProductSource { List<ProductSnapshot> products(); }`, which M4 replaces.
  - `daily_goals.dart`: `final class DailyGoals { kcal, protein, fat, carbs }` (int). The diary declares its own shape (AD3), and `app/` maps the settings `Goals` to it.
  - `add_entry.dart`: `AddEntry(repository, clock, uuid)`. `call({snapshot, quantityText, unit, meal, date})` parses the quantity, creates the entry with a new id and `updatedAt = clock.now().toUtc()`, and saves it. It returns `AddEntryResult` (sealed): `EntryAdded`, `QuantityRejected`, `UnitRejected` or `EntryNotSaved`.
  - `edit_entry.dart`: `EditEntry(repository, clock)`. `call({id, quantityText, unit, meal, date})` finds the entry and calls `revise`. It returns `EntryEdited`, `QuantityRejected`, `UnitRejected`, `EntryNotFound` or `EntryNotSaved`.
  - `delete_entry.dart`: `DeleteEntry(repository, clock)`. It finds the entry, calls `delete(now)` and saves it. It returns `EntryDeleted`, `EntryNotFound` or `EntryNotSaved`.
  - `watch_day.dart`: `WatchDay(repository)`. `Stream<DiaryDay> call(LocalDate date, DailyGoals goals)`, where `DiaryDay { date, goals, Map<Meal, List<DiaryEntry>> entriesByMeal, DayTotals totals }`.
- `infrastructure/`:
  - `diary_entries_table.dart`: `@DataClassName('DiaryEntryRow')` (so it does not clash with the domain `DiaryEntry`) and `@TableIndex(name: 'diary_entries_user_date_idx', columns: {#userId, #entryDate})`. `class DiaryEntries extends Table` has these columns:
    - `id` text, the primary key.
    - `user_id` text, `entry_date` text `yyyy-MM-dd`, `meal` text.
    - `product_name` text, `source` text, `source_ref` text nullable, `base_unit` text.
    - `kcal_per_100`, `protein_per_100`, `fat_per_100`, `carbs_per_100` real.
    - `quantity` real, `unit` text, `serving_size` real nullable.
    - `updated_at` datetime (unix), `deleted_at` datetime nullable.
  - `drift_entry_repository.dart`: `DriftEntryRepository(GeneratedDatabase db, String userId)`, typed queries on the modular `DiaryEntries` table:
    - `watchDay`: `user_id = userId AND entry_date = date AND deleted_at IS NULL`, ordered by `updated_at`, then `id`.
    - `findById`: `id AND user_id AND deleted_at IS NULL`.
    - `save`: `insert(..., onConflict: DoUpdate((_) => companion, where: (old) => old.userId.equals(userId)))`, so another user's row with the same id is never overwritten (BR-001). A `DriftWrappedException` or `SqliteException` becomes `SaveFailed`. No error crosses outward (AD5).
    - Enums are mapped by `name`, and invalid stored values are rejected at read (untrusted boundary).
  - `dev_seed_products.dart`: `DevSeedProductSource implements ProductSource` with 4 constant snapshots, all `source: manual`. The values are dev placeholders: one g product without a serving, one g product with `servingSize: 150`, one ml product, and one product with 200 kcal/100 g for the FR-004 example. The file says "debug-only, removed in M4".
- `presentation/`:
  - `diary_providers.dart`: the override points (AD9), each throwing `UnimplementedError` when not overridden: `entryRepositoryProvider`, `productSourceProvider`, `dailyGoalsProvider` (`Provider<DailyGoals?>`), `clockProvider` and `uuidProvider`. It also declares:
    - `selectedDateProvider` (`NotifierProvider<SelectedDate, LocalDate>`, starts at `LocalDate.of(clock.now())`, with `next()`, `previous()` and `set()`).
    - `dayProvider` (`StreamProvider.family<DiaryDay, LocalDate>`).
    - `addEntryProvider`, `editEntryProvider`, `deleteEntryProvider`, and `entryProvider` (`FutureProvider.family<DiaryEntry?, String>`).
  - `diary_format.dart`: one place for rounding and formatting. kcal and the macros in the summary and entry lines use `round()`, and the form's live preview shows one decimal (DESIGN "6,2 g"). Numbers go through `NumberFormat.decimalPattern(locale)` (DESIGN "2 200", "6,2"). A negative remaining value uses the minus sign `−` (U+2212), with a `Semantics` value that reads as "minus".
  - `diary_screen.dart` (board **Dziennik**):
    - The header has the greeting "Cześć!" / "Hi!" and the date (`DateFormat.MMMMEEEEd(locale)`, "Środa, 25 listopada"), with previous and next arrows and a calendar button that opens `showDatePicker` (any past or future day, D-16).
    - `day_summary_card.dart`: remaining kcal ("kcal zostało"), "Zjedzone" consumed "z {goal} kcal", and protein, fat and carbs as "77 / 150 g" in a `Wrap`, so the card wraps at 360 dp and 200 %.
    - `meal_card.dart` ×4: the meal name, "319 kcal · 2 wpisy" (ICU plural), the entry names joined with ", ", and a plus button. An empty meal shows "No entries" and the plus button (UF-002). Meal accents come from the `tokens.dart` meal colors. Tapping the card opens Meal details.
    - States: loading shows a progress indicator in the card area, and an empty day shows zeros (FR-003 edge case). With no goals (`null`), the screen shows the start screen redirect path; the guard already prevents that.
  - `meal_details_screen.dart` (board **Szczegóły posiłku**):
    - The header shows the meal name, then the kcal total with "kcal w tym posiłku".
    - Each entry tile shows the name, "150 g · B 18 · T 0 · W 6" and "96 kcal". Tapping a tile opens the edit form.
    - The "Dodaj produkt" button opens Add entry for this meal and date, and "No entries" shows when the meal is empty.
  - `add_entry_screen.dart` (board **Dodaj wpis**, M3 subset): the header "Dodaj do: {meal}", then the `ProductSource` list as tiles ("64 kcal / 100 g"). Tapping a product opens the quantity form. The screen is only reachable when `app/` gives a source; the list is empty in release (no source → "No products yet").
  - `entry_form_screen.dart` (board **Ilość**), one screen for create and edit:
    - The product header shows "64 kcal / 100 g · porcja 150 g".
    - The live preview card shows kcal plus protein, fat and carbs (`entryNutrition`), and updates on every change.
    - The quantity field takes a decimal keyboard, with − and + buttons (`stepQuantity`).
    - Unit `ChoiceChip`s come from `unitsFor`, e.g. "g" and "porcja (150 g)". There are also four meal chips and the date field (`showDatePicker`).
    - Save is enabled only for a valid quantity. An invalid one shows "Enter a quantity from 0.1 to 10000." (UF-003).
    - In edit mode the form adds a "Delete entry" button, which opens a confirmation dialog (user choice) with Cancel and Delete.
    - A failed save shows a SnackBar "Could not save entry." (UF-002), and a successful save pops back.

**Settings module (`apps/mobile/lib/settings/`, existing)**
- `application/goals_cache.dart`: the port `abstract interface class GoalsCache { Future<Goals?> read(String userId); Future<void> write(String userId, Goals goals); Future<void> clear(String userId); }`.
- `infrastructure/goals_cache_table.dart`: `@DataClassName('CachedGoalsRow') class CachedGoals extends Table` with the SQL name `user_settings`, `user_id` text as the primary key, and `goal_kcal`, `goal_protein_g`, `goal_fat_g` and `goal_carbs_g` as int. There is no timestamp: M2's `Settings` has none (D-73), and M6 adds it with sync.
- `infrastructure/drift_goals_cache.dart`: `DriftGoalsCache(GeneratedDatabase db)`, with typed queries filtered by `user_id`. `write` is an upsert on `user_id`. Values that fail `validateGoals` on read are treated as no cache.
- `infrastructure/caching_goals_repository.dart`: `CachingGoalsRepository implements GoalsRepository`, which decorates the remote repository so `LoadGoals`, `SaveGoals` and the M2 tests stay unchanged. Its constructor is `(GoalsRepository remote, GoalsCache cache, String userId)`.
  - `load`: remote `GoalsFound` writes the cache and returns the goals. Remote `GoalsMissing` clears the cache and returns `GoalsMissing`. Remote `GoalsUnavailable` returns the cached `GoalsFound`, or `GoalsUnavailable` if there is none.
  - `save`: `GoalsSaved` writes the cache. Other results pass through unchanged, because edits stay online-only.
- `settings.dart`: export the new port, the table, `DriftGoalsCache` and `CachingGoalsRepository`.

**Auth module (existing)**
- `application/auth_gateway.dart`: add `String? get currentUserId;`. `infrastructure/supabase_auth_gateway.dart` returns `_auth.currentUser?.id`. `test/support/fakes.dart` gives `FakeAuthGateway` a settable `currentUserId`.

**Composition root (`apps/mobile/lib/app/`)**
- `database.dart`: `@DriftDatabase(tables: [DiaryEntries, CachedGoals]) class AppDatabase extends $AppDatabase` with `schemaVersion => 1` and `MigrationStrategy(onCreate: (m) => m.createAll())`. `AppDatabase.open()` uses `driftDatabase(name: 'lean_tracker')`, and `AppDatabase(QueryExecutor)` is for tests.
- `providers.dart`:
  - `appDatabaseProvider` creates `AppDatabase.open()` and closes it in `onDispose`.
  - `currentUserIdProvider` watches `authStatusProvider` and reads `authGateway.currentUserId`.
  - `goalsRepositoryProvider` overrides to `CachingGoalsRepository(ApiGoalsRepository(...), DriftGoalsCache(db), userId)` when a user id exists, otherwise to the plain API repository.
  - `entryRepositoryProvider` overrides to `DriftEntryRepository(db, userId)`. It is rebuilt when the user changes, so a new user never reads the old scope.
  - `productSourceProvider` overrides to `kDebugMode ? const DevSeedProductSource() : const NoProducts()`. `NoProducts` is a two-line class in `app/`, so the module ships no release stub.
  - `dailyGoalsProvider` maps `goalsProvider`'s `GoalsFound` to `DailyGoals`, and anything else to `null`.
  - `clockProvider` → `SystemClock()`, `uuidProvider` → `RandomUuid()`.
- `route_guard.dart` `Routes`: add `diaryMeal = '/diary/meal'`, `diaryAdd = '/diary/add'`, `diaryAddQuantity = '/diary/add/quantity'` and `diaryEntry = '/diary/entry'`. The guard logic is unchanged: these child paths are not entry screens, so a signed-in user with goals stays on them.
- `router.dart`: the Diary branch uses `DiaryScreen`, with these child routes:
  - `meal/:meal?date=yyyy-MM-dd` → `MealDetailsScreen`.
  - `add?meal=&date=` → `AddEntryScreen`, and its child `quantity` → `EntryFormScreen.create`. The snapshot is passed in `extra`; a missing `extra` redirects to `/diary`.
  - `entry/:id` → `EntryFormScreen.edit`.
  - Unknown `meal` or `date` values redirect to `/diary` (untrusted boundary).
- Delete `diary_placeholder_screen.dart` and the ARB key `diaryPlaceholder`.

**Contract.** No change. M3 is local only (§19), and diary routes come with the sync contract in M6 (ARCHITECTURE open item 1). Adding them now would leave them with no caller (YAGNI). `make check-contract` stays green.

**Data model.**
- Server: no migration. `0003_diary_entries.sql` already matches §13. `0001_user_settings.sql` is unchanged.
- Device: Drift schema **v1** with two tables. `diary_entries` mirrors §13 (same column names, REAL for numerics, `id`, `updated_at`, `deleted_at` for M6). The local `user_settings` holds only the goals cache.
- There are no local CHECK constraints: the domain validates, and the server has its own checks.
- M4 and M5 add their tables as v2+ with `onUpgrade` steps.

**Limits.** `quantityMin`, `quantityMax` and `quantityDecimals` go in `lib/kernel/limits/limits.dart` (app-side, as noted). No Go change, and the contract test is unchanged until M6.

**UI texts (ARB, EN and PL).** §11 wins over DESIGN for text. Where §11 has no text, the DESIGN Polish text is used, with an English translation.

| Key | EN | PL | Source |
| --- | --- | --- | --- |
| diaryGreeting | Hi! | Cześć! | DESIGN |
| diaryKcalLeft | kcal left | kcal zostało | DESIGN |
| diaryEaten | Eaten | Zjedzone | DESIGN |
| diaryOfGoal | of {goal} kcal | z {goal} kcal | DESIGN |
| macroProtein / macroFat / macroCarbs | Protein / Fat / Carbs | Białko / Tłuszcz / Węgle | DESIGN |
| macroOfGoal | {value} / {goal} g | {value} / {goal} g | DESIGN |
| mealBreakfast / mealLunch / mealDinner / mealSnack | Breakfast / Lunch / Dinner / Snacks | Śniadanie / Obiad / Kolacja / Przekąski | DESIGN |
| mealSummary | {kcal} kcal · {count, plural, one{1 entry} other{{count} entries}} | {kcal} kcal · {count, plural, one{1 wpis} few{{count} wpisy} many{{count} wpisów} other{{count} wpisu}} | DESIGN |
| noEntries | No entries | Brak wpisów | §11 UF-002 |
| mealKcalLabel | kcal in this meal | kcal w tym posiłku | DESIGN |
| entryLine | {quantity} · P {protein} · F {fat} · C {carbs} | {quantity} · B {protein} · T {fat} · W {carbs} | DESIGN |
| addProduct | Add product | Dodaj produkt | DESIGN |
| addTo | Add to: {meal} | Dodaj do: {meal} | DESIGN |
| noProducts | No products yet | Brak produktów | M3 (release has no source) |
| per100 | {kcal} kcal / 100 {unit} | {kcal} kcal / 100 {unit} | DESIGN |
| servingInfo | serving {size} {unit} | porcja {size} {unit} | DESIGN |
| unitServingWithSize | serving ({size} {unit}) | porcja ({size} {unit}) | DESIGN |
| unitMl | ml | ml | DESIGN (`unitGram`, `unitKcal` exist) |
| quantityTitle / quantityLabel | Quantity | Ilość | DESIGN |
| mealLabel / dateLabel | Meal / Date | Posiłek / Data | DESIGN |
| save | Save | Zapisz | DESIGN |
| errorQuantityRange | Enter a quantity from 0.1 to 10000. | Podaj ilość od 0,1 do 10000. | §11 UF-003 |
| errorEntryNotSaved | Could not save entry. | Nie udało się zapisać wpisu. | §11 UF-002 |
| deleteEntry | Delete entry | Usuń wpis | M3 (user choice) |
| deleteEntryQuestion | Delete this entry? | Usunąć ten wpis? | M3 |
| cancel / delete | Cancel / Delete | Anuluj / Usuń | M3 |
| a11yPreviousDay / a11yNextDay / a11yPickDate | Previous day / Next day / Pick a date | Poprzedni dzień / Następny dzień / Wybierz datę | Semantics |
| a11yAddToMeal | Add entry to {meal} | Dodaj wpis do: {meal} | Semantics |
| a11yDecrease / a11yIncrease | Decrease quantity / Increase quantity | Zmniejsz ilość / Zwiększ ilość | Semantics |

Polish texts the PRD does not give, marked M3, are proposals for the owner to review.

### Fit with Project Docs
- **PRD:**
  - Implements FR-003, FR-004, UF-002, UF-003 (quantity form) and BR-004 to BR-007, and the quantity range of BR-003.
  - Adds the offline goals read for BR-014.
  - FR-002's criterion "the Diary shows the new goals" is now testable.
  - The design is bent in two places by user choice: no 5-day strip, no quick-amount chips.
- **ARCHITECTURE.md:**
  - The new `diary` module has four layers. Drift lives in `infrastructure` and `app/`, and `presentation` never imports infrastructure (screens read providers).
  - AD3: `DailyGoals` and `ProductSource` are declared by the diary.
  - AD4: the diary does not know whether it is online. The goals fallback lives in the settings adapter.
  - AD5: sealed results, mapped to text in presentation. AD9: providers with override points.
  - New AD12: each module owns its Drift tables in `infrastructure/`, generated in modular mode and exported through its public file. `app/` composes the single `AppDatabase` and passes a `GeneratedDatabase` (plus the user id) to each module's adapter.
- **CODE_QUALITY.md:**
  - KISS: one database, one repository per user scope, no uuid package.
  - YAGNI: no products or favorites tables, no diary API.
  - DRY: rounding and formatting in `diary_format.dart` only, and the limits in `kernel/limits`.
  - `Clock` and `Uuid` are injected, and there is no `SELECT *` (typed Drift).
  - Bent: the dev seed is code that ships until M4 (listed as known debt).
- **Docs to update:**
  - PRD §20: add D-75 for the M3 choices:
    - goals cache in Drift, online-only edits
    - one DB with `user_id`
    - REAL numbers
    - debug seed products
    - soft delete
    - `drift_flutter` approved
    - no day strip or quick chips
    - delete confirmation
  - PRD §11 UF-002: an "M3 scope" note like the one on UF-006.
  - ARCHITECTURE: AD12, the Layout section (`lib/app/database.dart`, `build.yaml`, `*.drift.dart` committed), and an update to the dependency-rules line about Drift.
  - CODE_QUALITY: known debt "dev seed products in `diary/infrastructure/dev_seed_products.dart`, removed in M4". The single-sources row for the device schema becomes "Drift tables in each module's `infrastructure/`, composed in `app/database.dart`".

### Alternative Approaches Considered
- **Local data scope:** one database file with `user_id` and a per-user repository (**chosen**: same shape as the server, simple M6) vs one file per user (isolation by structure, but more open and close code at sign-in and in M7) vs wipe at sign-out (loses unsynced entries before M6).
- **Numbers:** REAL (**chosen**: 1:1 with §13, simpler) vs integer ×10 (exact, but conversions and different column names) vs ×1000 (precision the PRD does not need).
- **Queries:** typed Drift through modular generation (**chosen**: compiler-checked) vs raw `customSelect` SQL (no generator setup, but typos surface only in tests) vs a classic DAO (needs the concrete `AppDatabase`, which breaks the module rule).
- **Opening the database:** `drift_flutter` (**chosen**: one package, background isolate, bundled SQLite) vs `drift` + `path_provider` + `NativeDatabase.createInBackground` (a few more lines, and SQLite bundling verified by hand).
- **Goals offline:** a decorator in settings infrastructure (**chosen**: use cases and M2 tests unchanged) vs a cache inside the diary (two sources of goals) vs API only (breaks BR-014).
- **Entry source in M3:** a debug seed behind the `ProductSource` port (**chosen**, user choice: M4 swaps one override) vs a manual product form (built twice) vs an add-screen shell with dead tabs.
- **Meal layout:** DESIGN cards plus Meal details (**chosen**, user choice: layout follows DESIGN, and M5 copy goes there) vs entries listed inline on the Diary.

## Implementation Steps
1. [x] In `apps/mobile/pubspec.yaml` add `drift` and `drift_flutter` (dependencies) and `drift_dev` (dev_dependencies). Create `apps/mobile/build.yaml` (modular Drift, as above). Exclude `lib/**/*.drift.dart` in `analysis_options.yaml`. Add `lib/diary` to the `dart format` list of `lint-dart` in the root `Makefile`. Run `make gen-dart`.
2. [x] Add `lib/kernel/clock.dart`, `lib/kernel/uuid.dart` and `lib/kernel/local_date.dart`, and the quantity limits in `lib/kernel/limits/limits.dart`.
3. [x] Tests: `test/kernel/local_date_test.dart` (BR-004: 23:59:59 and 00:00 local are different days; `addDays` across month and year ends and a DST change; ISO round trip) and `test/kernel/uuid_test.dart` (format, version 4, variant, two calls differ).
4. [x] Diary domain: `lib/diary/domain/meal.dart`, `units.dart`, `product_snapshot.dart`, `quantity.dart` (`parseQuantity`, `stepQuantity`), `nutrition.dart`, `diary_entry.dart` and `day_totals.dart`, as in Key Changes.
5. [x] Domain tests in `test/diary/domain/`:
   - `quantity_test.dart`: `0.1`, `10000` and `1,5` are valid; `0`, `10000.1`, `1.25`, `-1`, `abc` and empty are invalid; the step is ±10 g/ml and ±1 serving and is clamped.
   - `nutrition_test.dart`: the FR-004 criteria 1 and 2; ml uses the same formula with no conversion.
   - `diary_entry_test.dart`: BR-005 has four meals; BR-006 rejects `serving` without `servingSize` and a g/ml mismatch; BR-007 keeps the snapshot after `revise`; `delete` sets both timestamps.
   - `day_totals_test.dart`: the FR-003 criterion; a negative remaining value; an empty day has zeros and four meals.
6. [x] Diary application: `lib/diary/application/entry_repository.dart`, `product_source.dart`, `daily_goals.dart`, `add_entry.dart`, `edit_entry.dart`, `delete_entry.dart` and `watch_day.dart`.
7. [x] Add an in-memory `FakeEntryRepository` (hides `deletedAt`, like the real one), `FakeClock`, `FakeUuid` and `FakeProductSource` to `test/support/fakes.dart`. Application tests in `test/diary/application/`:
   - `add_entry_test.dart`: id from `Uuid`, `updatedAt` from `Clock`, snapshot copied, invalid quantity saves nothing, `SaveFailed` → `EntryNotSaved`.
   - `edit_entry_test.dart`: only the 4 fields change, an unknown id → `EntryNotFound`.
   - `delete_entry_test.dart`: soft delete, and the entry is gone from `watchDay`.
   - `watch_day_test.dart`: grouping by meal and totals against goals.
8. [x] Drift tables: `lib/diary/infrastructure/diary_entries_table.dart` and `lib/settings/infrastructure/goals_cache_table.dart`. Add `lib/app/database.dart` (`AppDatabase`, v1). Run `make gen-dart` and commit the generated `*.drift.dart` files. Confirm the modular output exposes typed table classes usable on a `GeneratedDatabase`. If it does not, stop and ask the owner (do not switch to raw SQL silently).
9. [x] `lib/diary/infrastructure/drift_entry_repository.dart` (scoped by `userId`, upsert guarded by `user_id`, errors mapped to `SaveFailed`) and `lib/diary/infrastructure/dev_seed_products.dart`.
10. [x] `test/diary/infrastructure/drift_entry_repository_test.dart` on `AppDatabase(NativeDatabase.memory())`:
    - Save and read back all fields, including `null` serving and `source_ref`.
    - `watchDay` filters by date and hides soft-deleted rows.
    - User B's repository sees none of user A's rows.
    - Saving with an id owned by user A from user B's repository leaves A's row unchanged (BR-001).
    - The stream emits after a save.

    This is the first test to load SQLite in the `make test` image; see Risks.
11. [x] Auth: add `currentUserId` to `AuthGateway`, `SupabaseAuthGateway` and `FakeAuthGateway`.
12. [x] Settings: `lib/settings/application/goals_cache.dart`, `lib/settings/infrastructure/drift_goals_cache.dart` and `caching_goals_repository.dart`. Export them, with the table, from `lib/settings/settings.dart`.
13. [x] Tests:
    - `test/settings/infrastructure/caching_goals_repository_test.dart` with a `FakeGoalsCache` and `FakeGoalsRepository`: online found → cached and returned; offline with cache → `GoalsFound` (BR-014); offline without cache → `GoalsUnavailable`; missing → cache cleared; save OK → cache written; save offline → cache unchanged and `GoalsOffline`.
    - `test/settings/infrastructure/drift_goals_cache_test.dart` on an in-memory DB: read, write, upsert, clear, and per-user isolation.
14. [x] ARB: add the keys from the UI table to `lib/l10n/app_en.arb` and `app_pl.arb` (with `@` descriptions and placeholders), remove `diaryPlaceholder`, and run `make gen-dart`.
15. [x] Presentation: `lib/diary/presentation/diary_providers.dart` and `diary_format.dart` (rounding, number formatting, minus sign).
16. [x] Presentation: `lib/diary/presentation/diary_screen.dart`, `day_summary_card.dart` and `meal_card.dart` (board Dziennik: arrows, date picker, greeting, summary, four meal cards, empty state).
17. [x] Presentation: `lib/diary/presentation/meal_details_screen.dart` (board Szczegóły posiłku) and `add_entry_screen.dart` (board Dodaj wpis, M3 subset).
18. [x] Presentation: `lib/diary/presentation/entry_form_screen.dart` (board Ilość; create and edit; −/+ step; unit, meal and date; live preview; the Save rules; delete confirmation; save-failure SnackBar).
19. [x] Create `lib/diary/diary.dart` (the public exports).
20. [x] Wire `app/`: providers in `lib/app/providers.dart` (database, current user id, caching goals repository, entry repository, product source with `kDebugMode`, daily goals, clock, uuid). Add the `Routes` constants, update `lib/app/router.dart` with the Diary branch and its child routes, and delete `lib/app/diary_placeholder_screen.dart`.
21. [x] Widget tests:
    - `test/diary/presentation/diary_screen_test.dart`: the FR-003 numbers 500 and 1500; a negative remaining value shows a minus sign; an empty meal shows "No entries" and plus; the arrows change the day; 360 dp and text scale 2.0 cause no overflow; PL locale texts.
    - `test/diary/presentation/entry_form_screen_test.dart`: an invalid quantity shows the UF-003 error and Save is disabled; `150` g of a 200 kcal product previews 300 kcal; no serving chip without `servingSize`; −/+ steps; the delete confirmation Cancel keeps the entry and Delete removes it; save failure shows "Could not save entry.".
    - `test/diary/presentation/meal_details_screen_test.dart`: entries and their lines; "Add product" opens the add route.
22. [x] Update `test/app/app_test.dart`: `pumpApp` overrides the diary providers with fakes, and the test "lands on the Diary" asserts the Diary greeting instead of the placeholder text. Keep `test/app/route_guard_test.dart` green; add a case showing that `/diary/add` stays put for a signed-in user with goals.
23. [x] Docs:
    - PRD §20 D-75 and the UF-002 M3 note.
    - ARCHITECTURE AD12, Layout and the dependency-rules line.
    - CODE_QUALITY known debt and the single-sources row.
    - In this spec, mark the FR-003 and FR-004 criteria covered.

## Checkpoints (Todo List)
- [x] CP1 — Setup, kernel, domain: steps 1–5. `make lint` clean; `test/kernel/` and `test/diary/domain/` green. — lint and tests not run (not selected); code and tests written
- [x] CP2 — Use cases: steps 6–7. `test/diary/application/` green; `make lint` clean. — lint and tests not run (not selected); code and tests written
- [x] CP3 — Local storage: steps 8–13. `test/diary/infrastructure/`, `test/settings/infrastructure/` and the existing `test/settings/` and `test/auth/` green; `make lint` clean. — lint and tests not run (not selected); `make gen-dart` ran clean and confirmed typed modular tables; SQLite-in-Docker risk still open
- [x] CP4 — Screens and wiring: steps 14–22. `make test` green (including `test/app/`); `make lint` clean. — lint and tests not run (not selected); code and tests written
- [x] CP5 — Docs and final light verification: step 23. `make lint` clean, `make test` green, `git diff --stat apps/api` empty. — `git diff --stat apps/api` empty (checked); lint and tests not run (not selected)

### Risks & Mitigations
- **Risk:** SQLite does not load in the pinned Flutter Docker image (`NativeDatabase.memory()` in `make test`), or the `sqlite3` build hook needs network or a compiler.
  - Mitigation: step 10 is the first DB test, so a failure shows early (CP3). The hook's download goes into the mounted `.cache/pub` once.
  - Mitigation: if it still fails, record it in the log and ask the owner before choosing between installing `libsqlite3` in a small derived test image and adding `sqlite3` test-only setup. Do not drop the repository tests.
- **Risk:** Another user's data shows after sign-out and sign-in (BR-001).
  - Mitigation: the repository is constructed with the user id and has no unscoped query. `entryRepositoryProvider` is rebuilt when `currentUserIdProvider` changes.
  - Mitigation: the two-user repository and cache tests (steps 10 and 13). The upsert `where` guards against an id collision overwriting another user's row.
- **Risk:** The day is wrong near midnight or across a DST change (BR-004).
  - Mitigation: `LocalDate` uses only local fields and UTC arithmetic for `addDays`, and the date is stored as `yyyy-MM-dd` text, never as an instant. The tests use a fake clock at 23:59:59 and 00:00.
- **Risk:** Rounding makes the displayed totals differ from the sum of displayed entries, or float noise appears (REAL).
  - Mitigation: sum unrounded values and round once in `diary_format.dart`, with the quantity normalized to one decimal on parse. The FR-003 and FR-004 tests use the PRD numbers.
- **Risk:** The modular Drift generation, the generated-file formatting or the analyzer rules fight `make lint`.
  - Mitigation: the analyzer excludes `*.drift.dart`. If `dart format` rewrites generated output, add those paths to the format exclusions in the Makefile and log it. Step 8 stops and asks if typed modular tables are not usable.

## Test Strategy
- **Light: `make lint` and `make test`, run during implementation as the user selects.**
  - Unit tests (Flutter, no network, database or widgets): kernel `LocalDate` and `Uuid`; diary domain (BR-003 quantity, BR-004, BR-005, BR-006, BR-007, FR-003 totals); diary use cases with a fake `Clock`, `Uuid` and repository; `CachingGoalsRepository` with fakes.
  - Repository tests: `DriftEntryRepository` and `DriftGoalsCache` on an in-memory Drift database (isolation, soft delete, guarded upsert).
  - Widget tests: Diary, Meal details, entry form, and the app shell landing on the Diary.
  - Unit tests (Go): none change, but `make test` still runs them. Contract tests: unchanged and still green.
- **Heavy, run only by `lean-review` when selected:** device build, contract drift, NFR-002 manual timing. Integration tests belong to `lean-e2e` only.
- **For `/lean-e2e`:**
  - In airplane mode, add an entry from a seed product; the Diary totals update (BR-014, FR-004).
  - Edit an entry's quantity and meal; it moves and the totals change, and the name stays (BR-007).
  - Delete an entry with confirmation; after an app restart it is still gone.
  - A cold start offline with previously loaded goals opens the Diary (BR-014).
  - NFR-002: a local save completes in ≤ 300 ms.
- **Manual testing:**
  - Airplane mode cold start.
  - Sign out and sign in as another user on one phone: no foreign entries.
  - An entry added at 23:59 and the day after midnight.
  - Polish locale (plural "2 wpisy", "5 wpisów", decimal comma).
  - Dark theme, 200 % font at 360 dp, TalkBack or VoiceOver labels on the arrows, plus and −/+.

## Success Checklist
- [ ] All success criteria met (with evidence)
- [ ] Lint and unit tests clean (implementation)
- [ ] Heavy checks green when run (review): build, contract drift
- [ ] Code review approved
- [ ] Documentation updated (sections listed in "Fit with Project Docs")
- [ ] No regressions in Polish and English, light and dark, offline
- [ ] User action: review the proposed Polish texts marked "M3" in the UI table

## Timeline & Estimates
- Phase 1 (implementation): ~10 hours
- Phase 2 (testing): ~4 hours
- Phase 3 (review + polish): ~2 hours
- **Total**: ~16 hours (rough estimate, plus buffer)

## Open Questions
None. The remaining environment unknowns (SQLite in the Docker test image, the shape of the modular Drift output) are handled by stop-and-ask points in steps 8 and 10.

## Implementation Log
- Decision: Entry source in M3: dev seed products, debug-only (`kDebugMode`), removed in M4
- Decision: Goals offline: cached in Drift; edits stay online-only until M6
- Decision: Local scope: one database with `user_id`, filtered in one repository
- Decision: Drift tables: only what M3 uses (`diary_entries`, goals cache)
- Decision: Delete: soft delete through `deleted_at`
- Decision: Seed location: code behind `kDebugMode`
- Decision: Numbers: REAL (double)
- Decision: Queries: typed Drift queries
- Decision: Opening the DB: `drift_flutter` (owner-approved, not in PRD §18)
- Decision: Delete UI: confirmation dialog
- Decision: Meal layout: DESIGN cards plus a Meal details screen
- Decision: Quantity form: −/+ step 10 g/ml, 1 serving; no quick-amount chips; Diary has arrows and a date picker, no 5-day strip
- Decision: workspace: worktree
- Decision: checks: none
- Step 1 — started
- Step 1 — done — files: apps/mobile/pubspec.yaml, apps/mobile/pubspec.lock, apps/mobile/build.yaml, apps/mobile/analysis_options.yaml, Makefile — drift 2.31.0, drift_dev 2.31.0, drift_flutter 0.2.8; make gen-dart ran (no existing generated file changed; pub cache seeded from main checkout)
- Step 2 — started
- Step 2 — done — files: apps/mobile/lib/kernel/clock.dart, uuid.dart, local_date.dart, limits/limits.dart — Clock, Uuid, LocalDate (+ parseIso returns null for invalid, toDateTime for pickers), quantity limits
- Step 3 — started
- Step 3 — done — files: apps/mobile/test/kernel/local_date_test.dart, uuid_test.dart — BR-004 midnight, addDays month/year/leap/DST, ISO round trip, uuid v4 format (not run: no checks selected)
- Step 4 — started
- Step 4 — done — files: apps/mobile/lib/diary/domain/{meal,units,product_snapshot,quantity,nutrition,diary_entry,day_totals}.dart — as in Key Changes; units.dart and product_snapshot.dart import each other (Dart allows it; unitsFor stays in units.dart as planned); DiaryEntry has a private ctor, only create/revise/delete build one
- Step 5 — started
- Step 5 — done — files: apps/mobile/test/diary/domain/{quantity,nutrition,diary_entry,day_totals}_test.dart, apps/mobile/test/support/diary_samples.dart — shared sample snapshots/entry helper added for the diary tests (not run: no checks selected)
- Step 6 — started
- Step 6 — done — files: apps/mobile/lib/diary/application/{entry_repository,product_source,daily_goals,add_entry,edit_entry,delete_entry,watch_day}.dart — edit/delete results are named EditQuantityRejected, EditUnitRejected, EditEntryNotFound, EditNotSaved, DeleteEntryNotFound, DeleteNotSaved so the sealed families do not clash in one public file
- Step 7 — started
- Step 7 — done — files: apps/mobile/test/support/fakes.dart, apps/mobile/test/diary/application/{add_entry,edit_entry,delete_entry,watch_day}_test.dart — FakeEntryRepository/FakeClock/FakeUuid/FakeProductSource (not run: no checks selected)
- Step 8 — started
- Step 8 — done — files: apps/mobile/lib/diary/infrastructure/diary_entries_table.dart(+.drift.dart), lib/settings/infrastructure/goals_cache_table.dart(+.drift.dart), lib/app/database.dart(+.drift.dart), lib/diary/diary.dart (started with the table export so app/ imports only the public file; step 19 completes it), lib/settings/settings.dart (table export) — modular output confirmed: typed $DiaryEntriesTable/$CachedGoalsTable(db) usable on a GeneratedDatabase; generated files are untracked, the user commits them; generated *.drift.dart sit in dart-format paths (lib/app, lib/diary, lib/settings), not checked here
- Step 9 — started
- Step 9 — done — files: apps/mobile/lib/diary/infrastructure/drift_entry_repository.dart, dev_seed_products.dart — save catches `on Exception` (drift reaches here as wrapped/remote exception; `sqlite3` is not a direct dependency so SqliteException is not imported); damaged rows (bad enum/date/unit) are skipped at read
- Step 10 — started
- Step 10 — done — files: apps/mobile/test/diary/infrastructure/drift_entry_repository_test.dart — plan cases plus ordering, replace-on-same-id, damaged-row skip, closed-db SaveFailed; NOT RUN: SQLite loading in the Flutter Docker image is still unverified (plan Risks) — check with `make test-dart` in review
- Step 11 — started
- Step 11 — done — files: apps/mobile/lib/auth/application/auth_gateway.dart, lib/auth/infrastructure/supabase_auth_gateway.dart, test/support/fakes.dart — currentUserId on the port, Supabase `_auth.currentUser?.id`, FakeAuthGateway settable (default 'user-1')
- Step 12 — started
- Step 12 — done — files: apps/mobile/lib/settings/application/goals_cache.dart, infrastructure/drift_goals_cache.dart, infrastructure/caching_goals_repository.dart, lib/settings/settings.dart — cache failures are swallowed in the decorator (best effort) so a good API answer never becomes an error
- Step 13 — started
- Step 13 — done — files: apps/mobile/test/settings/infrastructure/{caching_goals_repository,drift_goals_cache}_test.dart, test/support/fakes.dart — FakeGoalsCache added; FakeGoalsRepository gets a settable saveResult (not run: no checks selected)
- Step 14 — started
- Step 14 — done — files: apps/mobile/lib/l10n/app_en.arb, app_pl.arb (+ regenerated app_localizations*.dart) — all table keys plus one extra, `a11yNegative` ("minus", the spoken form of the minus sign, needed by the Semantics value in diary_format); PL file keeps its existing style (no @ metadata); `diaryPlaceholder` removed, so diary_placeholder_screen.dart does not compile until step 20 deletes it
- Step 15 — started
- Step 15 — done — files: apps/mobile/lib/diary/presentation/diary_providers.dart, diary_format.dart — plus `watchDayProvider`; `entryProvider` is `FutureProvider.autoDispose.family` so a reopened edit form never shows a stale entry; DESIGN.html boards are not text-searchable (bundled), so layouts follow the plan text and `ui/` tokens
- Step 16 — started
- Step 16 — done — files: apps/mobile/lib/diary/presentation/diary_screen.dart, day_summary_card.dart, meal_card.dart, screen_header.dart — screens take navigation callbacks (onOpenMeal, onAddEntry) so the module never imports the router; shared back-arrow header added as screen_header.dart
- Step 17 — started
- Step 17 — done — files: apps/mobile/lib/diary/presentation/meal_details_screen.dart, add_entry_screen.dart — callbacks onAddProduct/onOpenEntry/onPickProduct; AddEntryScreen's date is carried in the route and handed on to the form
- Step 18 — started
- Step 18 — done — files: apps/mobile/lib/diary/presentation/entry_form_screen.dart — create starts at 100 in the product's first unit (assumption: plan gives no default); a successful save or delete pops (Navigator.pop); edit loads the entry through entryProvider
- Step 19 — started
- Step 19 — done — files: apps/mobile/lib/diary/diary.dart — also exports Meal, EntryRepository and the providers (app/ parses the meal route value and overrides the ports)
- Step 20 — started
- Step 20 — done — files: apps/mobile/lib/app/providers.dart, router.dart, route_guard.dart, lib/diary/diary.dart (exports DiaryEntry too), deleted lib/app/diary_placeholder_screen.dart (git rm, staged) — a private `_SignedOutEntries` repository stands in while no user is signed in (empty, refuses saves) so a screen on its way out never touches a user scope; `NoProducts` lives in providers.dart; routes: meal/:meal?date, add?meal&date, add/quantity?meal&date (+extra snapshot), entry/:id
- Step 21 — started
- Step 21 — done — files: apps/mobile/test/diary/presentation/{diary_screen,entry_form_screen,meal_details_screen}_test.dart, test/support/diary_harness.dart — harness pushes each screen over a base page so pop works (not run: no checks selected)
- Step 22 — started
- Step 22 — done — files: apps/mobile/test/app/app_test.dart, test/app/route_guard_test.dart — pumpApp overrides the diary providers; Diary landing asserts 'Hi!' and four empty meals; guard cases for /diary/meal, /add, /add/quantity, /entry (not run: no checks selected)
- Step 23 — started
- Step 23 — done — files: docs/PRD.md (UF-002 M3 note, D-75), docs/ARCHITECTURE.md (AD12, Layout, dependency rule), docs/CODE_QUALITY.md (known debt, single-sources row), this spec (FR-003/FR-004 marked covered)
- Handoff — mode: worktree — branch: feature/04-diary-entries — base: 220188c — checks: none — changed: Makefile, apps/mobile/analysis_options.yaml, apps/mobile/lib/app/diary_placeholder_screen.dart, apps/mobile/lib/app/providers.dart, apps/mobile/lib/app/route_guard.dart, apps/mobile/lib/app/router.dart, apps/mobile/lib/auth/application/auth_gateway.dart, apps/mobile/lib/auth/infrastructure/supabase_auth_gateway.dart, apps/mobile/lib/kernel/limits/limits.dart, apps/mobile/lib/l10n/app_en.arb, apps/mobile/lib/l10n/app_localizations.dart, apps/mobile/lib/l10n/app_localizations_en.dart, apps/mobile/lib/l10n/app_localizations_pl.dart, apps/mobile/lib/l10n/app_pl.arb, apps/mobile/lib/settings/settings.dart, apps/mobile/pubspec.lock, apps/mobile/pubspec.yaml, apps/mobile/test/app/app_test.dart, apps/mobile/test/app/route_guard_test.dart, apps/mobile/test/support/fakes.dart, docs/ARCHITECTURE.md, docs/CODE_QUALITY.md, docs/PRD.md, apps/mobile/build.yaml, apps/mobile/lib/app/database.dart, apps/mobile/lib/app/database.drift.dart, apps/mobile/lib/diary/application/add_entry.dart, apps/mobile/lib/diary/application/daily_goals.dart, apps/mobile/lib/diary/application/delete_entry.dart, apps/mobile/lib/diary/application/edit_entry.dart, apps/mobile/lib/diary/application/entry_repository.dart, apps/mobile/lib/diary/application/product_source.dart, apps/mobile/lib/diary/application/watch_day.dart, apps/mobile/lib/diary/diary.dart, apps/mobile/lib/diary/domain/day_totals.dart, apps/mobile/lib/diary/domain/diary_entry.dart, apps/mobile/lib/diary/domain/meal.dart, apps/mobile/lib/diary/domain/nutrition.dart, apps/mobile/lib/diary/domain/product_snapshot.dart, apps/mobile/lib/diary/domain/quantity.dart, apps/mobile/lib/diary/domain/units.dart, apps/mobile/lib/diary/infrastructure/dev_seed_products.dart, apps/mobile/lib/diary/infrastructure/diary_entries_table.dart, apps/mobile/lib/diary/infrastructure/diary_entries_table.drift.dart, apps/mobile/lib/diary/infrastructure/drift_entry_repository.dart, apps/mobile/lib/diary/presentation/add_entry_screen.dart, apps/mobile/lib/diary/presentation/day_summary_card.dart, apps/mobile/lib/diary/presentation/diary_format.dart, apps/mobile/lib/diary/presentation/diary_providers.dart, apps/mobile/lib/diary/presentation/diary_screen.dart, apps/mobile/lib/diary/presentation/entry_form_screen.dart, apps/mobile/lib/diary/presentation/meal_card.dart, apps/mobile/lib/diary/presentation/meal_details_screen.dart, apps/mobile/lib/diary/presentation/screen_header.dart, apps/mobile/lib/kernel/clock.dart, apps/mobile/lib/kernel/local_date.dart, apps/mobile/lib/kernel/uuid.dart, apps/mobile/lib/settings/application/goals_cache.dart, apps/mobile/lib/settings/infrastructure/caching_goals_repository.dart, apps/mobile/lib/settings/infrastructure/drift_goals_cache.dart, apps/mobile/lib/settings/infrastructure/goals_cache_table.dart, apps/mobile/lib/settings/infrastructure/goals_cache_table.drift.dart, apps/mobile/test/diary/application/add_entry_test.dart, apps/mobile/test/diary/application/delete_entry_test.dart, apps/mobile/test/diary/application/edit_entry_test.dart, apps/mobile/test/diary/application/watch_day_test.dart, apps/mobile/test/diary/domain/day_totals_test.dart, apps/mobile/test/diary/domain/diary_entry_test.dart, apps/mobile/test/diary/domain/nutrition_test.dart, apps/mobile/test/diary/domain/quantity_test.dart, apps/mobile/test/diary/infrastructure/drift_entry_repository_test.dart, apps/mobile/test/diary/presentation/diary_screen_test.dart, apps/mobile/test/diary/presentation/entry_form_screen_test.dart, apps/mobile/test/diary/presentation/meal_details_screen_test.dart, apps/mobile/test/kernel/local_date_test.dart, apps/mobile/test/kernel/uuid_test.dart, apps/mobile/test/settings/infrastructure/caching_goals_repository_test.dart, apps/mobile/test/settings/infrastructure/drift_goals_cache_test.dart, apps/mobile/test/support/diary_harness.dart, apps/mobile/test/support/diary_samples.dart — preexisting: none — checkpoints: 5/5
