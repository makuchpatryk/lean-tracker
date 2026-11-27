import 'package:dio/dio.dart';

import '../../gen/models/error_code.dart';

/// What a failed settings call means for the app. Chosen from the status and the `Error.code` of the
/// contract, never from message text (AD5).
enum GoalsFailure {
  /// 404 SETTINGS_NOT_FOUND: the user has no goals yet.
  missing,

  /// 400: the API refused the values.
  rejected,

  /// No connection, timeout, 401, 5xx or anything unexpected.
  unavailable,
}

GoalsFailure mapGoalsError(
  int? status,
  ErrorCode? code,
  DioExceptionType type,
) {
  if (status == 404 && code == ErrorCode.settingsNotFound) {
    return GoalsFailure.missing;
  }
  if (status == 400) return GoalsFailure.rejected;
  return GoalsFailure.unavailable;
}
