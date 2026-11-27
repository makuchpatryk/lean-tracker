import 'package:flutter/material.dart';

import '../../ui/theme.dart';
import '../../ui/tokens.dart';

/// Back arrow and a title, the top of the Diary's inner screens.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        // Pops the route: the screens are pushed above the Diary (go_router child routes).
        BackButton(color: palette.ink),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: nunito(22, AppWeights.semiBold, color: palette.ink),
            ),
          ),
        ),
      ],
    );
  }
}
