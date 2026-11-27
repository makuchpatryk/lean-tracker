import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import '../domain/diary_entry.dart';
import '../domain/meal.dart';
import '../domain/nutrition.dart';
import 'diary_format.dart';

/// The accent of a meal from the design tokens.
Color mealColor(AppPalette palette, Meal meal) => switch (meal) {
  Meal.breakfast => palette.meal1,
  Meal.lunch => palette.meal2,
  Meal.dinner => palette.meal3,
  Meal.snack => palette.meal4,
};

/// One meal of the day: its name, kcal and entry count, the entry names, and a plus button (UF-002).
/// Tapping the card opens the meal's details.
class MealCard extends StatelessWidget {
  const MealCard({
    required this.meal,
    required this.entries,
    required this.total,
    required this.onOpen,
    required this.onAdd,
    super.key,
  });

  final Meal meal;
  final List<DiaryEntry> entries;
  final Nutrition total;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final format = DiaryFormat(l10n);
    final name = format.mealName(meal);
    final summary = entries.isEmpty
        ? l10n.noEntries
        : format.mealSummary(total, entries.length);

    return Material(
      color: mealColor(palette, meal),
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: onOpen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.buttonHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: nunito(17, AppWeights.extraBold, color: palette.ink),
                      ),
                      Text(
                        summary,
                        style: nunito(14, AppWeights.semiBold, color: palette.ink),
                      ),
                      if (entries.isNotEmpty)
                        Text(
                          entries.map((e) => e.snapshot.name).join(', '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: nunito(13, AppWeights.regular, color: palette.muted),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onAdd,
                  tooltip: l10n.a11yAddToMeal(name),
                  constraints: const BoxConstraints(
                    minWidth: AppSpacing.touchTarget,
                    minHeight: AppSpacing.touchTarget,
                  ),
                  icon: Icon(Icons.add_circle, color: palette.primary, size: 32),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
