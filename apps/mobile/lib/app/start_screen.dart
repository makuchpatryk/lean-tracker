import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../settings/settings.dart';
import '../ui/app_buttons.dart';
import '../ui/theme.dart';
import '../ui/tokens.dart';
import 'providers.dart';
import 'route_guard.dart';

/// Holding screen while the session is restored and the goals load. A failed load shows the error and
/// a retry; the route guard leaves this screen as soon as the status is known.
class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final failed = ref.watch(goalsStatusProvider) == GoalsStatus.unavailable;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: failed
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          l10n.errorNoConnection,
                          textAlign: TextAlign.center,
                          style: nunito(
                            16,
                            AppWeights.regular,
                            color: palette.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.gap),
                      PrimaryButton(
                        label: l10n.retry,
                        onPressed: () =>
                            ref.read(goalsProvider.notifier).retry(),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
