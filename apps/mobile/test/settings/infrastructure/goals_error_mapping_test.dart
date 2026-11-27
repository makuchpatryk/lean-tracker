import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/gen/models/error_code.dart';
import 'package:lean_tracker/settings/infrastructure/goals_error_mapping.dart';

void main() {
  test('404 SETTINGS_NOT_FOUND means the user has no goals (BP-006)', () {
    expect(
      mapGoalsError(
        404,
        ErrorCode.settingsNotFound,
        DioExceptionType.badResponse,
      ),
      GoalsFailure.missing,
    );
  });

  test('404 without the SETTINGS_NOT_FOUND code is not "missing"', () {
    expect(
      mapGoalsError(404, null, DioExceptionType.badResponse),
      GoalsFailure.unavailable,
    );
  });

  test('400 means the API rejected the goals', () {
    expect(
      mapGoalsError(
        400,
        ErrorCode.validationError,
        DioExceptionType.badResponse,
      ),
      GoalsFailure.rejected,
    );
  });

  test('connection errors and timeouts are unavailable', () {
    for (final type in [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      expect(mapGoalsError(null, null, type), GoalsFailure.unavailable);
    }
  });

  test('500 and 401 are unavailable', () {
    expect(
      mapGoalsError(500, ErrorCode.internalError, DioExceptionType.badResponse),
      GoalsFailure.unavailable,
    );
    expect(
      mapGoalsError(401, ErrorCode.unauthorized, DioExceptionType.badResponse),
      GoalsFailure.unavailable,
    );
  });
}
