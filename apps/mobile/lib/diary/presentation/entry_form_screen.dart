import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../kernel/local_date.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/app_buttons.dart';
import '../../ui/app_text_field.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import '../application/add_entry.dart';
import '../application/delete_entry.dart';
import '../application/edit_entry.dart';
import '../domain/meal.dart';
import '../domain/nutrition.dart';
import '../domain/product_snapshot.dart';
import '../domain/quantity.dart';
import '../domain/units.dart';
import 'diary_format.dart';
import 'diary_providers.dart';
import 'meal_card.dart';
import 'screen_header.dart';

/// The quantity form (UF-003 step 3): quantity, unit, meal and date with a live preview. One screen
/// for a new entry ([EntryFormScreen.create]) and for changing or deleting one ([EntryFormScreen.edit]).
/// A successful save or delete pops back.
class EntryFormScreen extends ConsumerWidget {
  const EntryFormScreen.create({
    required ProductSnapshot this.snapshot,
    required Meal this.meal,
    required LocalDate this.date,
    super.key,
  }) : entryId = null;

  const EntryFormScreen.edit({required String this.entryId, super.key})
    : snapshot = null,
      meal = null,
      date = null;

  final String? entryId;
  final ProductSnapshot? snapshot;
  final Meal? meal;
  final LocalDate? date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = entryId;
    if (id == null) {
      final product = snapshot;
      final initialMeal = meal;
      final initialDate = date;
      if (product == null || initialMeal == null || initialDate == null) {
        return const _FormMessage(unknown: true);
      }
      return _EntryForm(
        snapshot: product,
        meal: initialMeal,
        date: initialDate,
        unit: unitsFor(product).first,
        quantityText: '100',
      );
    }

    final format = DiaryFormat(AppLocalizations.of(context));
    return ref
        .watch(entryProvider(id))
        .when(
          loading: () => const _FormMessage(),
          error: (_, _) => const _FormMessage(unknown: true),
          data: (entry) => entry == null
              ? const _FormMessage(unknown: true)
              : _EntryForm(
                  entryId: entry.id,
                  snapshot: entry.snapshot,
                  meal: entry.meal,
                  date: entry.entryDate,
                  unit: entry.unit,
                  quantityText: format.fieldText(entry.quantity),
                ),
        );
  }
}

/// A form with nothing to edit: still loading, or the entry is gone.
class _FormMessage extends StatelessWidget {
  const _FormMessage({this.unknown = false});

  final bool unknown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(title: l10n.quantityTitle),
              const SizedBox(height: 16),
              if (unknown)
                Text(
                  l10n.errorUnknown,
                  style: nunito(15, AppWeights.regular, color: palette.error),
                )
              else
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryForm extends ConsumerStatefulWidget {
  const _EntryForm({
    required this.snapshot,
    required this.meal,
    required this.date,
    required this.unit,
    required this.quantityText,
    this.entryId,
  });

  /// Null for a new entry.
  final String? entryId;
  final ProductSnapshot snapshot;
  final Meal meal;
  final LocalDate date;
  final EntryUnit unit;
  final String quantityText;

  @override
  ConsumerState<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends ConsumerState<_EntryForm> {
  late final TextEditingController _quantity = TextEditingController(
    text: widget.quantityText,
  );
  late EntryUnit _unit = widget.unit;
  late Meal _meal = widget.meal;
  late LocalDate _date = widget.date;
  bool _busy = false;

  bool get _editing => widget.entryId != null;

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  double? get _validQuantity => switch (parseQuantity(_quantity.text)) {
    ValidQuantity(:final value) => value,
    InvalidQuantity() => null,
  };

  void _step(int direction) {
    final next = stepQuantity(_validQuantity ?? 0, _unit, direction);
    final format = DiaryFormat(AppLocalizations.of(context));
    setState(() => _quantity.text = format.fieldText(next));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.toDateTime(),
      // Any past or future day may be logged (PRD D-16).
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _date = LocalDate.of(picked));
  }

  Future<void> _save() async {
    final id = widget.entryId;
    setState(() => _busy = true);
    final saved = id == null
        ? switch (await ref.read(addEntryProvider)(
            snapshot: widget.snapshot,
            quantityText: _quantity.text,
            unit: _unit,
            meal: _meal,
            date: _date,
          )) {
            EntryAdded() => true,
            QuantityRejected() || UnitRejected() || EntryNotSaved() => false,
          }
        : switch (await ref.read(editEntryProvider)(
            id: id,
            quantityText: _quantity.text,
            unit: _unit,
            meal: _meal,
            date: _date,
          )) {
            EntryEdited() => true,
            EditQuantityRejected() ||
            EditUnitRejected() ||
            EditEntryNotFound() ||
            EditNotSaved() => false,
          };
    _finish(saved);
  }

  Future<void> _delete() async {
    final id = widget.entryId;
    if (id == null) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteEntryQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final deleted = switch (await ref.read(deleteEntryProvider)(id)) {
      EntryDeleted() => true,
      DeleteEntryNotFound() || DeleteNotSaved() => false,
    };
    _finish(deleted);
  }

  /// Pops after a success; a failure keeps the form and says so (UF-002).
  void _finish(bool success) {
    if (!mounted) return;
    setState(() => _busy = false);
    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).errorEntryNotSaved),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final format = DiaryFormat(l10n);
    final snapshot = widget.snapshot;
    final quantity = _validQuantity;
    final nutrition = quantity == null
        ? Nutrition.zero
        : entryNutrition(snapshot, quantity, _unit);
    final dateText = DateFormat.yMMMMd(
      l10n.localeName,
    ).format(_date.toDateTime());

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            ScreenHeader(title: l10n.quantityTitle),
            const SizedBox(height: 12),
            Text(
              snapshot.name,
              style: nunito(20, AppWeights.extraBold, color: palette.ink),
            ),
            Text(
              format.productInfo(snapshot),
              style: nunito(14, AppWeights.regular, color: palette.muted),
            ),
            const SizedBox(height: 16),
            _PreviewCard(nutrition: nutrition, format: format),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _step(-1),
                  tooltip: l10n.a11yDecrease,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Expanded(
                  child: AppTextField(
                    label: l10n.quantityLabel,
                    controller: _quantity,
                    // The serving chip already names the unit; its long text would not fit beside the − and + buttons.
                    suffix: _unit == EntryUnit.serving
                        ? null
                        : format.unit(_unit, snapshot),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    errorText: quantity == null
                        ? l10n.errorQuantityRange
                        : null,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                IconButton(
                  onPressed: () => _step(1),
                  tooltip: l10n.a11yIncrease,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final unit in unitsFor(snapshot))
                  ChoiceChip(
                    label: Text(format.unit(unit, snapshot)),
                    selected: _unit == unit,
                    onSelected: (_) => setState(() => _unit = unit),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.mealLabel,
              style: nunito(13, AppWeights.regular, color: palette.muted),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final meal in Meal.values)
                  ChoiceChip(
                    label: Text(format.mealName(meal)),
                    selected: _meal == meal,
                    selectedColor: mealColor(palette, meal),
                    onSelected: (_) => setState(() => _meal = meal),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.dateLabel,
              style: nunito(13, AppWeights.regular, color: palette.muted),
            ),
            const SizedBox(height: 4),
            SecondaryButton(label: dateText, onPressed: _pickDate),
            const SizedBox(height: 24),
            PrimaryButton(
              label: l10n.save,
              onPressed: quantity == null || _busy ? null : _save,
            ),
            if (_editing) ...[
              const SizedBox(height: 12),
              SecondaryButton(
                label: l10n.deleteEntry,
                onPressed: _busy ? null : _delete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Live preview of the entry: kcal and the three macros, one decimal (DESIGN "6,2 g").
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.nutrition, required this.format});

  final Nutrition nutrition;
  final DiaryFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = format.l10n;
    final palette = context.palette;

    Widget macro(String label, double grams, Color tint, Color ink) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(AppRadii.input),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            '$label ${format.oneDecimal(grams)} ${l10n.unitGram}',
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              format.kcal(nutrition.kcal),
              style: nunito(32, AppWeights.extraBold, color: palette.ink),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                macro(
                  l10n.macroProtein,
                  nutrition.protein,
                  palette.proteinTint,
                  palette.protein,
                ),
                macro(
                  l10n.macroFat,
                  nutrition.fat,
                  palette.fatTint,
                  palette.fat,
                ),
                macro(
                  l10n.macroCarbs,
                  nutrition.carbs,
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
