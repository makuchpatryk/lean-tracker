import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/mascot.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import 'goals_form.dart';
import 'goals_providers.dart';

/// Board "Cele (pierwsze uruchomienie)": the goals gate before the Diary (UF-001, BP-006). Saving
/// makes the route guard open the Diary.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.goalsTitle,
                      style: nunito(28, AppWeights.bold, color: palette.ink),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.goalsSubtitle,
                    style: nunito(15, AppWeights.regular, color: palette.muted),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Mascot(
                        size: 64,
                        semanticLabel: l10n.mascotLabel,
                        leftEyeOpen: true,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Text(
                            l10n.goalsMascot,
                            style: nunito(
                              14,
                              AppWeights.regular,
                              color: palette.ink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.screenPadding),
                  GoalsForm(
                    submitLabel: l10n.goalsSaveAndContinue,
                    onSave: ref.read(goalsProvider.notifier).save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
