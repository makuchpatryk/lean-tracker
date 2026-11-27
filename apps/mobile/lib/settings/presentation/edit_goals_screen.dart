import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import '../application/goals_repository.dart';
import 'goals_form.dart';
import 'goals_providers.dart';

/// Board "Cele": edits the saved goals from Settings (FR-002).
class EditGoalsScreen extends ConsumerWidget {
  const EditGoalsScreen({required this.onDone, super.key});

  /// Called after the goals were stored: the router goes back to Settings.
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final loaded = ref.watch(goalsProvider).value;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: palette.background,
        scrolledUnderElevation: 0,
        title: Semantics(
          header: true,
          child: Text(
            l10n.settingsGoals,
            style: nunito(22, AppWeights.semiBold, color: palette.ink),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: GoalsForm(
                submitLabel: l10n.goalsSave,
                initial: loaded is GoalsFound ? loaded.goals : null,
                onSave: ref.read(goalsProvider.notifier).save,
                onSaved: onDone,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
