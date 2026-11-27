/// Public entry of the diary module: entries, the day view and the quantity form (FR-003, FR-004).
/// `app/` reaches the module only through this file (ARCHITECTURE: module boundaries).
library;

export 'application/daily_goals.dart';
export 'application/entry_repository.dart';
export 'application/product_source.dart';
export 'domain/diary_entry.dart';
export 'domain/meal.dart';
export 'domain/product_snapshot.dart';
export 'infrastructure/dev_seed_products.dart';
export 'infrastructure/diary_entries_table.dart';
export 'infrastructure/drift_entry_repository.dart';
export 'presentation/add_entry_screen.dart';
export 'presentation/diary_providers.dart';
export 'presentation/diary_screen.dart';
export 'presentation/entry_form_screen.dart';
export 'presentation/meal_details_screen.dart';
