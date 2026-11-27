import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/app_buttons.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import 'auth_controller.dart';

/// Shown after sign-up while the email is not confirmed (PRD UF-001 step 2a, FR-001 criterion 1).
class CheckEmailScreen extends ConsumerWidget {
  const CheckEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final busy = ref.watch(authControllerProvider).busy;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.checkEmailTitle,
                      textAlign: TextAlign.center,
                      style: nunito(28, AppWeights.bold, color: palette.ink),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.checkEmailBody,
                    textAlign: TextAlign.center,
                    style: nunito(16, AppWeights.regular, color: palette.muted),
                  ),
                  const SizedBox(height: 24),
                  SecondaryButton(
                    label: l10n.backToSignIn,
                    onPressed: busy
                        ? null
                        : () => ref
                              .read(authControllerProvider.notifier)
                              .signOut(),
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
