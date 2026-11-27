import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/app_buttons.dart';
import '../../ui/app_text_field.dart';
import '../../ui/mascot.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import '../application/auth_gateway.dart';
import '../domain/auth_failure.dart';
import 'auth_controller.dart';
import 'auth_failure_text.dart';

/// Board "Logowanie": sign in, sign up, forgot password and social sign-in (UF-001).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({required this.onForgotPassword, super.key});

  final VoidCallback onForgotPassword;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final state = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    final failure = state.failure;
    final failureText = failure == null ? null : authFailureText(l10n, failure);
    final emailError =
        failure is InvalidEmail || failure is EmailAlreadyRegistered
        ? failureText
        : null;
    final passwordError = failure is PasswordTooShort ? failureText : null;
    final generalError = emailError == null && passwordError == null
        ? failureText
        : null;
    final idle = !state.busy;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.gap,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Mascot(size: 120, semanticLabel: l10n.mascotLabel),
                  ),
                  Text(
                    l10n.appTitle,
                    textAlign: TextAlign.center,
                    style: nunito(
                      34,
                      AppWeights.extraBold,
                      color: palette.primary,
                    ),
                  ),
                  Text(
                    l10n.loginTagline,
                    textAlign: TextAlign.center,
                    style: nunito(16, AppWeights.regular, color: palette.muted),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: l10n.emailLabel,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    errorText: emailError,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: l10n.passwordLabel,
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    errorText: passwordError,
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: LinkButton(
                      label: l10n.forgotPasswordLink,
                      onPressed: idle ? widget.onForgotPassword : null,
                    ),
                  ),
                  if (generalError != null)
                    Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          generalError,
                          textAlign: TextAlign.center,
                          style: nunito(
                            14,
                            AppWeights.regular,
                            color: palette.error,
                          ),
                        ),
                      ),
                    ),
                  PrimaryButton(
                    label: l10n.signInButton,
                    onPressed: idle
                        ? () => controller.signIn(_email.text, _password.text)
                        : null,
                  ),
                  const SizedBox(height: 14),
                  SecondaryButton(
                    label: l10n.signUpButton,
                    onPressed: idle
                        ? () => controller.signUp(_email.text, _password.text)
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.orDivider,
                    textAlign: TextAlign.center,
                    style: nunito(13, AppWeights.regular, color: palette.muted),
                  ),
                  const SizedBox(height: 14),
                  SecondaryButton(
                    label: l10n.continueWithGoogle,
                    onPressed: idle
                        ? () => controller.signInWith(SocialProvider.google)
                        : null,
                  ),
                  const SizedBox(height: 14),
                  SecondaryButton(
                    label: l10n.continueWithApple,
                    onPressed: idle
                        ? () => controller.signInWith(SocialProvider.apple)
                        : null,
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
