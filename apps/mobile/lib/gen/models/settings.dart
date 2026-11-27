// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'settings.g.dart';

@JsonSerializable()
class Settings {
  const Settings({
    required this.goalKcal,
    required this.goalProteinG,
    required this.goalFatG,
    required this.goalCarbsG,
  });
  
  factory Settings.fromJson(Map<String, Object?> json) => _$SettingsFromJson(json);
  
  @JsonKey(name: 'goal_kcal')
  final int goalKcal;
  @JsonKey(name: 'goal_protein_g')
  final int goalProteinG;
  @JsonKey(name: 'goal_fat_g')
  final int goalFatG;
  @JsonKey(name: 'goal_carbs_g')
  final int goalCarbsG;

  Map<String, Object?> toJson() => _$SettingsToJson(this);
}
