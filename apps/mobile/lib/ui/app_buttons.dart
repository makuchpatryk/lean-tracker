import 'package:flutter/material.dart';

import 'theme.dart';
import 'tokens.dart';

enum _Kind { primary, secondary, text }

/// Filled pill button of the DESIGN boards (primary color).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) =>
      _PillButton(kind: _Kind.primary, label: label, onPressed: onPressed);
}

/// Outlined pill button of the DESIGN boards (surface color, line border).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) =>
      _PillButton(kind: _Kind.secondary, label: label, onPressed: onPressed);
}

/// Borderless link-style button with a 48 dp touch target.
class LinkButton extends StatelessWidget {
  const LinkButton({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(AppSpacing.touchTarget, AppSpacing.touchTarget),
        foregroundColor: palette.primary,
      ),
      child: Text(label, style: nunito(14, AppWeights.semiBold)),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.kind,
    required this.label,
    required this.onPressed,
  });

  final _Kind kind;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final primary = kind == _Kind.primary;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.buttonHeight),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          backgroundColor: primary ? palette.primary : palette.surface,
          foregroundColor: primary ? palette.onPrimary : palette.ink,
          disabledBackgroundColor: palette.surfaceVariant,
          disabledForegroundColor: palette.muted,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
            side: primary ? BorderSide.none : BorderSide(color: palette.line),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: nunito(17, AppWeights.extraBold),
        ),
      ),
    );
  }
}
