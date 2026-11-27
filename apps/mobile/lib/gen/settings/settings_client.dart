// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/settings.dart';

part 'settings_client.g.dart';

@RestApi()
abstract class SettingsClient {
  factory SettingsClient(Dio dio, {String? baseUrl}) = _SettingsClient;

  @GET('/v1/settings')
  Future<Settings> getSettings();

  @PUT('/v1/settings')
  Future<Settings> putSettings({
    @Body() required Settings body,
  });
}
