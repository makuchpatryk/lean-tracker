import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../kernel/local_date.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/app_buttons.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import '../domain/meal.dart';
import '../domain/nutrition.dart';
import 'diary_format.dart';
import 'diary_providers.dart';
import 'screen_header.dart';

/// The entries of one meal on one day, with the meal's kcal (UF-002). Tapping an entry opens the edit
/// form; "Add product" opens Add entry.
class MealDetailsScreen extends ConsumerWidget {
  const MealDetailsScreen({
    required this.meal,
    required this.date,
    required this.onAddProduct,
    required this.onOpenEntry,
    super.key,
  });

  final Meal meal;
  final LocalDate date;
  final VoidCallback onAddProduct;
  final void Function(String entryId) onOpenEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final format = DiaryFormat(l10n);
    final day = ref.watch(dayProvider(date));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            ScreenHeader(title: format.mealName(meal)),
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
              data: (data) {
                final entries = data.entriesByMeal[meal] ?? const [];
                final total = data.totals.perMeal[meal] ?? Nutrition.zero;
                return [
                  Semantics(
                    container: true,
                    label: '${format.whole(total.kcal)} ${l10n.mealKcalLabel}',
                    excludeSemantics: true,
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 8,
                      children: [
                        Text(
                          format.whole(total.kcal),
                          style: nunito(
                            40,
                            AppWeights.extraBold,
                            color: palette.ink,
                          ),
                        ),
                        Text(
                          l10n.mealKcalLabel,
                          style: nunito(
                            15,
                            AppWeights.semiBold,
                            color: palette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        l10n.noEntries,
                        style: nunito(
                          15,
                          AppWeights.regular,
                          color: palette.muted,
                        ),
                      ),
                    ),
                  for (final entry in entries) ...[
                    _EntryTile(
                      name: entry.snapshot.name,
                      line: format.entryLine(entry),
                      kcal: format.kcal(entry.nutrition.kcal),
                      onTap: () => onOpenEntry(entry.id),
                    ),
                    const SizedBox(height: 8),
                  ],
                ];
              },
            ),
            const SizedBox(height: 8),
            PrimaryButton(label: l10n.addProduct, onPressed: onAddProduct),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.name,
    required this.line,
    required this.kcal,
    required this.onTap,
  });

  final String name;
  final String line;
  final String kcal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(color: palette.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.buttonHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: nunito(16, AppWeights.bold, color: palette.ink),
                      ),
                      Text(
                        line,
                        style: nunito(
                          13,
                          AppWeights.regular,
                          color: palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  kcal,
                  style: nunito(15, AppWeights.extraBold, color: palette.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
