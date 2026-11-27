// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Settings _$SettingsFromJson(Map<String, dynamic> json) => Settings(
  goalKcal: (json['goal_kcal'] as num).toInt(),
  goalProteinG: (json['goal_protein_g'] as num).toInt(),
  goalFatG: (json['goal_fat_g'] as num).toInt(),
  goalCarbsG: (json['goal_carbs_g'] as num).toInt(),
);

Map<String, dynamic> _$SettingsToJson(Settings instance) => <String, dynamic>{
  'goal_kcal': instance.goalKcal,
  'goal_protein_g': instance.goalProteinG,
  'goal_fat_g': instance.goalFatG,
  'goal_carbs_g': instance.goalCarbsG,
};
