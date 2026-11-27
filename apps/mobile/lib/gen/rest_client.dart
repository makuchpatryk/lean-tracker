// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'fallback/fallback_client.dart';
import 'settings/settings_client.dart';

/// Lean Tracker API `v0.2.0`
class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '0.2.0';

  FallbackClient? _fallback;
  SettingsClient? _settings;

  FallbackClient get fallback => _fallback ??= FallbackClient(_dio, baseUrl: _baseUrl);

  SettingsClient get settings => _settings ??= SettingsClient(_dio, baseUrl: _baseUrl);
}
