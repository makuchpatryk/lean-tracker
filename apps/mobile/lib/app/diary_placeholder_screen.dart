import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../ui/theme.dart';
import '../ui/tokens.dart';

/// Temporary Diary route; the real Diary replaces it in M3.
class DiaryPlaceholderScreen extends StatelessWidget {
  const DiaryPlaceholderScreen({super.key});

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
              Semantics(
                header: true,
                child: Text(
                  l10n.navDiary,
                  style: nunito(22, AppWeights.semiBold, color: palette.ink),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.diaryPlaceholder,
                style: nunito(15, AppWeights.regular, color: palette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
