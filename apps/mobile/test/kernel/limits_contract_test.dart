import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lean_tracker/kernel/limits/limits.dart';
import 'package:yaml/yaml.dart';

void main() {
  // AD6, BR-003: the Dart limits equal the Settings schema of the committed contract copy.
  final contract = loadYaml(File('openapi.yaml').readAsStringSync()) as YamlMap;
  final properties =
      ((contract['components'] as YamlMap)['schemas'] as YamlMap)['Settings']
          as YamlMap;
  final goals = properties['properties'] as YamlMap;

  void expectRange(String property, int min, int max) {
    final schema = goals[property] as YamlMap;
    expect(schema['minimum'], min, reason: '$property minimum');
    expect(schema['maximum'], max, reason: '$property maximum');
  }

  test('goal_kcal range equals Limits (BR-003)', () {
    expectRange('goal_kcal', Limits.goalKcalMin, Limits.goalKcalMax);
  });

  test('macro goal ranges equal Limits (BR-003)', () {
    for (final property in ['goal_protein_g', 'goal_fat_g', 'goal_carbs_g']) {
      expectRange(property, Limits.goalMacroMin, Limits.goalMacroMax);
    }
  });

  test('password minimum is 8 characters (FR-001)', () {
    expect(Limits.passwordMinLength, 8);
  });
}
