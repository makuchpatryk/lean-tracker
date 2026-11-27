import 'package:dio/dio.dart';

import '../../gen/models/error.dart' as api;
import '../../gen/models/error_code.dart';
import '../../gen/models/settings.dart';
import '../../gen/settings/settings_client.dart';
import '../application/goals_repository.dart';
import '../domain/goals.dart';
import 'goals_error_mapping.dart';

/// [GoalsRepository] over the generated `GET/PUT /v1/settings` client. Request and response bodies
/// are never logged (CODE_QUALITY: security and privacy).
class ApiGoalsRepository implements GoalsRepository {
  const ApiGoalsRepository(this._client);

  final SettingsClient _client;

  @override
  Future<GoalsLoad> load() async {
    try {
      return GoalsFound(_toGoals(await _client.getSettings()));
    } on DioException catch (e) {
      return switch (_failure(e)) {
        GoalsFailure.missing => const GoalsMissing(),
        GoalsFailure.rejected ||
        GoalsFailure.unavailable => const GoalsUnavailable(),
      };
    }
  }

  @override
  Future<GoalsSave> save(Goals goals) async {
    try {
      final stored = await _client.putSettings(body: _toSettings(goals));
      return GoalsSaved(_toGoals(stored));
    } on DioException catch (e) {
      return switch (_failure(e)) {
        GoalsFailure.rejected => const GoalsRejected(),
        GoalsFailure.missing ||
        GoalsFailure.unavailable => const GoalsOffline(),
      };
    }
  }

  GoalsFailure _failure(DioException e) {
    final response = e.response;
    return mapGoalsError(
      response?.statusCode,
      _errorCode(response?.data),
      e.type,
    );
  }

  /// Reads `code` from the contract's `Error` body; anything else is no code.
  static ErrorCode? _errorCode(Object? body) {
    if (body is! Map<String, Object?>) return null;
    try {
      return api.Error.fromJson(body).code;
    } on Object {
      return null;
    }
  }

  static Goals _toGoals(Settings s) => Goals(
    kcal: s.goalKcal,
    protein: s.goalProteinG,
    fat: s.goalFatG,
    carbs: s.goalCarbsG,
  );

  static Settings _toSettings(Goals g) => Settings(
    goalKcal: g.kcal,
    goalProteinG: g.protein,
    goalFatG: g.fat,
    goalCarbsG: g.carbs,
  );
}
