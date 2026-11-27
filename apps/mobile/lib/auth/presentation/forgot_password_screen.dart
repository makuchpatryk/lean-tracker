import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/app_buttons.dart';
import '../../ui/app_text_field.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import '../domain/auth_failure.dart';
import 'auth_controller.dart';
import 'auth_failure_text.dart';

/// Asks for the email and sends the reset link (FR-001, PRD D-72).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final state = ref.watch(authControllerProvider);
    final failure = state.failure;
    final failureText = failure == null ? null : authFailureText(l10n, failure);
    final emailError = failure is InvalidEmail ? failureText : null;
    final generalError = emailError == null ? failureText : null;

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
                      l10n.resetTitle,
                      style: nunito(28, AppWeights.bold, color: palette.ink),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.resetBody,
                    style: nunito(15, AppWeights.regular, color: palette.muted),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: l10n.emailLabel,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.done,
                    errorText: emailError,
                  ),
                  const SizedBox(height: 16),
                  if (generalError != null)
                    Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          generalError,
                          style: nunito(
                            14,
                            AppWeights.regular,
                            color: palette.error,
                          ),
                        ),
                      ),
                    ),
                  if (state.done)
                    Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          l10n.resetSent,
                          style: nunito(
                            14,
                            AppWeights.regular,
                            color: palette.ink,
                          ),
                        ),
                      ),
                    ),
                  PrimaryButton(
                    label: l10n.resetSend,
                    onPressed: state.busy
                        ? null
                        : () => ref
                              .read(authControllerProvider.notifier)
                              .requestPasswordReset(_email.text),
                  ),
                  const SizedBox(height: 14),
                  SecondaryButton(
                    label: l10n.backToSignIn,
                    onPressed: widget.onBack,
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
