import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/app_buttons.dart';
import '../../ui/app_text_field.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import '../application/goals_repository.dart';
import '../domain/goals.dart';

/// The four goal fields and the Save button, used by onboarding and by editing (UF-001 step 3,
/// FR-002). Save is enabled only when all four values are valid; a field shows its range error as
/// soon as it holds an invalid value.
class GoalsForm extends StatefulWidget {
  const GoalsForm({
    required this.submitLabel,
    required this.onSave,
    this.initial,
    this.onSaved,
    super.key,
  });

  final String submitLabel;
  final Goals? initial;

  /// Sends the raw field values (the use case validates again and stores them).
  final Future<GoalsSave> Function(Map<GoalField, String> raw) onSave;

  /// Called after the goals were stored. Onboarding leaves it null: the route guard opens the Diary.
  final VoidCallback? onSaved;

  @override
  State<GoalsForm> createState() => _GoalsFormState();
}

class _GoalsFormState extends State<GoalsForm> {
  late final Map<GoalField, TextEditingController> _controllers = {
    for (final field in GoalField.values)
      field: TextEditingController(text: _initialText(field)),
  };
  bool _busy = false;
  GoalsSave? _failure;

  String _initialText(GoalField field) {
    final goals = widget.initial;
    if (goals == null) return '';
    return switch (field) {
      GoalField.kcal => '${goals.kcal}',
      GoalField.protein => '${goals.protein}',
      GoalField.fat => '${goals.fat}',
      GoalField.carbs => '${goals.carbs}',
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<GoalField, String> get _raw => {
    for (final entry in _controllers.entries) entry.key: entry.value.text,
  };

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _failure = null;
    });
    final result = await widget.onSave(_raw);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failure = result is GoalsSaved ? null : result;
    });
    if (result is GoalsSaved) widget.onSaved?.call();
  }

  String? _errorText(AppLocalizations l10n, GoalField field, GoalsInput input) {
    if (input is! InvalidGoals) return null;
    return switch (input.errors[field]) {
      GoalError.outOfRange || GoalError.notInteger =>
        field == GoalField.kcal ? l10n.errorKcalRange : l10n.errorMacroRange,
      // An empty field disables Save but is not scolded before the user has typed.
      GoalError.missing || null => null,
    };
  }

  String? _failureText(AppLocalizations l10n) => switch (_failure) {
    GoalsOffline() => l10n.errorNoConnection,
    GoalsRejected() || GoalsInvalid() => l10n.errorUnknown,
    GoalsSaved() || null => null,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final input = validateGoals(_raw);
    final failureText = _failureText(l10n);

    Widget field(GoalField f, String label, String unit) => AppTextField(
      label: label,
      // Present for every field: the map is built from GoalField.values.
      controller: _controllers[f]!,
      suffix: unit,
      keyboardType: TextInputType.number,
      textInputAction: f == GoalField.carbs
          ? TextInputAction.done
          : TextInputAction.next,
      errorText: _errorText(l10n, f, input),
      onChanged: (_) => setState(() => _failure = null),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field(GoalField.kcal, l10n.goalKcalLabel, l10n.unitKcal),
        const SizedBox(height: AppSpacing.gap),
        field(GoalField.protein, l10n.goalProteinLabel, l10n.unitGram),
        const SizedBox(height: AppSpacing.gap),
        field(GoalField.fat, l10n.goalFatLabel, l10n.unitGram),
        const SizedBox(height: AppSpacing.gap),
        field(GoalField.carbs, l10n.goalCarbsLabel, l10n.unitGram),
        const SizedBox(height: AppSpacing.gap),
        if (failureText != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                failureText,
                textAlign: TextAlign.center,
                style: nunito(14, AppWeights.regular, color: palette.error),
              ),
            ),
          ),
        PrimaryButton(
          label: widget.submitLabel,
          onPressed: input is ValidGoals && !_busy ? _save : null,
        ),
      ],
    );
  }
}
