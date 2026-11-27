/// Public entry of the settings module: the daily goals (FR-002). `app/` reaches the module only
/// through this file (ARCHITECTURE: module boundaries).
library;

export 'application/goals_cache.dart';
export 'application/goals_repository.dart';
export 'application/load_goals.dart';
export 'application/save_goals.dart';
export 'domain/goals.dart';
export 'infrastructure/api_goals_repository.dart';
export 'infrastructure/caching_goals_repository.dart';
export 'infrastructure/drift_goals_cache.dart';
export 'infrastructure/goals_cache_table.dart';
export 'presentation/goals_providers.dart';
export 'presentation/edit_goals_screen.dart';
export 'presentation/goals_screen.dart';
export 'presentation/settings_screen.dart';
