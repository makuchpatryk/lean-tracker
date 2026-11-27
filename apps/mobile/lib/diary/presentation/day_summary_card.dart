import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import '../application/watch_day.dart';
import 'diary_format.dart';

/// The day's totals: remaining kcal, consumed against the goal, and the three macros (FR-003).
class DaySummaryCard extends StatelessWidget {
  const DaySummaryCard({required this.day, super.key});

  final DiaryDay day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final format = DiaryFormat(l10n);
    final totals = day.totals;
    final goals = day.goals;

    Widget macro(String label, double value, int goal, Color tint, Color ink) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(AppRadii.input),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            '$label ${l10n.macroOfGoal(format.whole(value), format.goal(goal))}',
            style: nunito(13, AppWeights.bold, color: ink),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: palette.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label:
                  '${format.remainingSpoken(totals.remainingKcal)} ${l10n.diaryKcalLeft}',
              excludeSemantics: true,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 8,
                children: [
                  Text(
                    format.remaining(totals.remainingKcal),
                    style: nunito(40, AppWeights.extraBold, color: palette.ink),
                  ),
                  Text(
                    l10n.diaryKcalLeft,
                    style: nunito(15, AppWeights.semiBold, color: palette.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.diaryEaten} ${format.whole(totals.total.kcal)} ${l10n.diaryOfGoal(format.goal(goals.kcal))}',
              style: nunito(15, AppWeights.semiBold, color: palette.muted),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                macro(
                  l10n.macroProtein,
                  totals.total.protein,
                  goals.protein,
                  palette.proteinTint,
                  palette.protein,
                ),
                macro(
                  l10n.macroFat,
                  totals.total.fat,
                  goals.fat,
                  palette.fatTint,
                  palette.fat,
                ),
                macro(
                  l10n.macroCarbs,
                  totals.total.carbs,
                  goals.carbs,
                  palette.carbsTint,
                  palette.carbs,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
