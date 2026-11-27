// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Error _$ErrorFromJson(Map<String, dynamic> json) => Error(
  code: ErrorCode.fromJson(json['code'] as String),
  message: json['message'] as String,
);

Map<String, dynamic> _$ErrorToJson(Error instance) => <String, dynamic>{
  'code': _$ErrorCodeEnumMap[instance.code]!,
  'message': instance.message,
};

const _$ErrorCodeEnumMap = {
  ErrorCode.unauthorized: 'UNAUTHORIZED',
  ErrorCode.validationError: 'VALIDATION_ERROR',
  ErrorCode.settingsNotFound: 'SETTINGS_NOT_FOUND',
  ErrorCode.internalError: 'INTERNAL_ERROR',
  ErrorCode.$unknown: r'$unknown',
};
