import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../kernel/local_date.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import '../domain/meal.dart';
import '../domain/product_snapshot.dart';
import 'diary_format.dart';
import 'diary_providers.dart';
import 'screen_header.dart';

/// Pick the product to log into [meal] on [date] (UF-003). M3 lists whatever the [ProductSource]
/// gives; the search, favorites and recents tabs arrive in M4 and M5.
class AddEntryScreen extends ConsumerWidget {
  const AddEntryScreen({
    required this.meal,
    required this.date,
    required this.onPickProduct,
    super.key,
  });

  final Meal meal;
  final LocalDate date;
  final void Function(ProductSnapshot product) onPickProduct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final format = DiaryFormat(l10n);
    final products = ref.watch(productSourceProvider).products();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            ScreenHeader(title: l10n.addTo(format.mealName(meal))),
            const SizedBox(height: 12),
            if (products.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  l10n.noProducts,
                  style: nunito(15, AppWeights.regular, color: palette.muted),
                ),
              ),
            for (final product in products) ...[
              Material(
                color: palette.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  side: BorderSide(color: palette.line),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  onTap: () => onPickProduct(product),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppSpacing.buttonHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: nunito(
                              16,
                              AppWeights.bold,
                              color: palette.ink,
                            ),
                          ),
                          Text(
                            format.productInfo(product),
                            style: nunito(
                              13,
                              AppWeights.regular,
                              color: palette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
