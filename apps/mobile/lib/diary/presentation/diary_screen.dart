import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../kernel/local_date.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import '../domain/meal.dart';
import '../domain/nutrition.dart';
import 'day_summary_card.dart';
import 'diary_providers.dart';
import 'meal_card.dart';

/// The Diary: the selected day with its totals and four meal cards (UF-002, FR-003). `app/` supplies
/// the navigation, so the module never imports the router.
class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({
    required this.onOpenMeal,
    required this.onAddEntry,
    super.key,
  });

  /// Opens the details of a meal on a date.
  final void Function(Meal meal, LocalDate date) onOpenMeal;

  /// Opens Add entry for a meal on a date.
  final void Function(Meal meal, LocalDate date) onAddEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final date = ref.watch(selectedDateProvider);
    final selected = ref.read(selectedDateProvider.notifier);
    final day = ref.watch(dayProvider(date));

    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date.toDateTime(),
        // Any past or future day may be logged (PRD D-16).
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) selected.set(LocalDate.of(picked));
    }

    final dateText = toBeginningOfSentenceCase(
      DateFormat.MMMMEEEEd(l10n.localeName).format(date.toDateTime()),
      l10n.localeName,
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            Text(
              l10n.diaryGreeting,
              style: nunito(15, AppWeights.semiBold, color: palette.muted),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: selected.previous,
                  tooltip: l10n.a11yPreviousDay,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      dateText,
                      textAlign: TextAlign.center,
                      style: nunito(
                        20,
                        AppWeights.extraBold,
                        color: palette.ink,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: pickDate,
                  tooltip: l10n.a11yPickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                ),
                IconButton(
                  onPressed: selected.next,
                  tooltip: l10n.a11yNextDay,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...day.when(
              loading: () => const [
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (_, _) => [
                Text(
                  l10n.errorUnknown,
                  style: nunito(15, AppWeights.regular, color: palette.error),
                ),
              ],
              data: (data) => [
                DaySummaryCard(day: data),
                for (final meal in Meal.values) ...[
                  const SizedBox(height: 12),
                  MealCard(
                    meal: meal,
                    entries: data.entriesByMeal[meal] ?? const [],
                    total: data.totals.perMeal[meal] ?? Nutrition.zero,
                    onOpen: () => onOpenMeal(meal, date),
                    onAdd: () => onAddEntry(meal, date),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
