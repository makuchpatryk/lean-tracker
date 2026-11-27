import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/app_buttons.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import '../application/goals_repository.dart';
import 'goals_providers.dart';

/// Board "Ustawienia" for M2: Goals, Language and theme (info only) and Sign out (UF-006). Reminders
/// and Delete account arrive in M7.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({
    required this.onEditGoals,
    required this.onSignOut,
    super.key,
  });

  final VoidCallback onEditGoals;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final loaded = ref.watch(goalsProvider).value;
    final goals = loaded is GoalsFound ? loaded.goals : null;

    Widget section(String title, List<Widget> children) => Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: nunito(14, AppWeights.bold, color: palette.primary),
            ),
          ),
          const SizedBox(height: 4),
          ...children,
        ],
      ),
    );

    Widget row(String label, String value, {Widget? trailing}) =>
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: nunito(15, AppWeights.regular, color: palette.ink),
                ),
              ),
              Text(
                value,
                style: nunito(15, AppWeights.regular, color: palette.muted),
              ),
              trailing ?? const SizedBox(width: AppSpacing.touchTarget),
            ],
          ),
        );

    final energy = goals == null ? '' : '${goals.kcal} ${l10n.unitKcal}';
    final macros = goals == null
        ? ''
        : '${goals.protein} / ${goals.fat} / ${goals.carbs} ${l10n.unitGram}';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 20,
                    ),
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.settingsTitle,
                        style: nunito(
                          22,
                          AppWeights.semiBold,
                          color: palette.ink,
                        ),
                      ),
                    ),
                  ),
                  section(l10n.settingsGoals, [
                    row(
                      l10n.settingsEnergy,
                      energy,
                      trailing: IconButton(
                        tooltip: l10n.settingsEditGoals,
                        onPressed: onEditGoals,
                        icon: const Icon(Icons.edit_outlined),
                        color: palette.ink,
                        constraints: const BoxConstraints.tightFor(
                          width: AppSpacing.touchTarget,
                          height: AppSpacing.touchTarget,
                        ),
                      ),
                    ),
                    row(l10n.settingsMacros, macros),
                  ]),
                  const SizedBox(height: 12),
                  section(l10n.settingsLanguageTheme, [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        l10n.settingsFollowsSystem,
                        style: nunito(
                          14,
                          AppWeights.regular,
                          color: palette.muted,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  SecondaryButton(label: l10n.signOut, onPressed: onSignOut),
                  const SizedBox(height: AppSpacing.gap),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
