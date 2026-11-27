import 'package:flutter/material.dart';

/// Borówka, the app mascot, drawn from the plain shapes of the DESIGN.html boards (viewBox 0 0 120 124).
/// The illustration has its own fixed colors: they do not follow the light or dark theme.
class Mascot extends StatelessWidget {
  const Mascot({
    required this.size,
    required this.semanticLabel,
    this.leftEyeOpen = false,
    super.key,
  });

  final double size;

  /// Localized name read by screen readers.
  final String semanticLabel;

  /// The onboarding board shows the left eye as a dot; the login board shows it closed.
  final bool leftEyeOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: CustomPaint(
          size: Size.square(size),
          painter: _MascotPainter(leftEyeOpen: leftEyeOpen),
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  const _MascotPainter({required this.leftEyeOpen});

  final bool leftEyeOpen;

  static const _white = Color(0xFFFFFFFF);
  static const _outline = Color(0xFF48324F);
  static const _body = Color(0xFF8F77A8);
  static const _face = Color(0xFF2E1E33);
  static const _cheek = Color(0xFFE6A5A0);
  static const _artWidth = 120.0;
  static const _artHeight = 124.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _artWidth < size.height / _artHeight
        ? size.width / _artWidth
        : size.height / _artHeight;
    canvas
      ..translate(
        (size.width - _artWidth * scale) / 2,
        (size.height - _artHeight * scale) / 2,
      )
      ..scale(scale);

    final limbs = Path()
      ..moveTo(18, 66)
      ..lineTo(3, 49)
      ..moveTo(102, 66)
      ..lineTo(117, 75)
      ..moveTo(43, 98)
      ..relativeLineTo(0, 17)
      ..moveTo(77, 98)
      ..relativeLineTo(0, 17);

    Paint stroke(Color color, double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width
      ..color = color;
    Paint fill(Color color) => Paint()..color = color;

    canvas
      ..drawPath(limbs, stroke(_white, 15))
      ..drawCircle(const Offset(60, 60), 50, fill(_white))
      ..drawPath(limbs, stroke(_outline, 6))
      ..drawCircle(const Offset(60, 60), 43, fill(_body))
      ..drawCircle(const Offset(60, 60), 43, stroke(_outline, 4));

    final crown = Path()
      ..moveTo(45, 21)
      ..relativeLineTo(3, -12)
      ..relativeLineTo(12, 8)
      ..relativeLineTo(12, -8)
      ..relativeLineTo(3, 12)
      ..relativeLineTo(-15, 6)
      ..close();
    canvas.drawPath(crown, fill(_outline));

    if (leftEyeOpen) {
      canvas.drawCircle(const Offset(45, 56), 5, fill(_face));
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(38, 58)
          ..relativeQuadraticBezierTo(7, -9, 14, 0),
        stroke(_face, 4),
      );
    }
    canvas
      ..drawPath(
        Path()
          ..moveTo(68, 56)
          ..relativeQuadraticBezierTo(7, -8, 14, 0),
        stroke(_face, 4),
      )
      ..drawOval(
        Rect.fromCenter(center: const Offset(32, 72), width: 12, height: 8),
        fill(_cheek),
      )
      ..drawOval(
        Rect.fromCenter(center: const Offset(88, 72), width: 12, height: 8),
        fill(_cheek),
      )
      ..drawPath(
        Path()
          ..moveTo(45, 71)
          ..relativeQuadraticBezierTo(15, 22, 30, 0)
          ..close(),
        fill(_face),
      );
  }

  @override
  bool shouldRepaint(_MascotPainter oldDelegate) =>
      oldDelegate.leftEyeOpen != leftEyeOpen;
}
