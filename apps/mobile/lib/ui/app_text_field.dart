import 'package:flutter/material.dart';

import 'theme.dart';
import 'tokens.dart';

/// Text field of the DESIGN boards: a label above, a rounded box, an optional unit and an error line.
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    required this.controller,
    this.errorText,
    this.suffix,
    this.keyboardType,
    this.obscureText = false,
    this.autofillHints,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? errorText;

  /// Unit shown inside the box, such as "kcal".
  final String? suffix;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: nunito(13, AppWeights.regular, color: palette.muted),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.fieldHeight),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(AppRadii.input),
            border: Border.all(color: hasError ? palette.error : palette.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  label: label,
                  child: TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    obscureText: obscureText,
                    autofillHints: autofillHints,
                    textInputAction: textInputAction,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    style: nunito(17, AppWeights.regular, color: palette.ink),
                    cursorColor: palette.primary,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 8),
                ExcludeSemantics(
                  child: Text(
                    suffix!,
                    style: nunito(14, AppWeights.regular, color: palette.muted),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorText!,
              style: nunito(13, AppWeights.regular, color: palette.error),
            ),
          ),
      ],
    );
  }
}
