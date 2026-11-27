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

/// Opened from the reset link: stores the new password (FR-001, PRD D-72). On success the auth
/// status becomes signedIn and the route guard leaves this screen.
class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final state = ref.watch(authControllerProvider);
    final failure = state.failure;
    final failureText = failure == null ? null : authFailureText(l10n, failure);
    final passwordError = failure is PasswordTooShort ? failureText : null;
    final generalError = passwordError == null ? failureText : null;

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
                      l10n.newPasswordTitle,
                      style: nunito(28, AppWeights.bold, color: palette.ink),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: l10n.passwordLabel,
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.done,
                    errorText: passwordError,
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
                  PrimaryButton(
                    label: l10n.newPasswordSave,
                    onPressed: state.busy
                        ? null
                        : () => ref
                              .read(authControllerProvider.notifier)
                              .setNewPassword(_password.text),
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
