import 'package:flutter/material.dart';
import '../theme/nyx_theme.dart';

class NyxLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;

  const NyxLogo({super.key, this.size = 40, this.showWordmark = false});

  @override
  Widget build(BuildContext context) {
    final logo = CustomPaint(
      size: Size(size, size),
      painter: _NyxLogoPainter(),
    );
    if (!showWordmark) return logo;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      logo,
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('NYX AUDIO',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: size * 0.35,
              fontWeight: FontWeight.w700,
              color: NyxColors.primaryText,
              letterSpacing: size * 0.025,
            )),
        Text('MUSIC · UNFETTERED',
            style: TextStyle(
              fontSize: size * 0.18,
              color: NyxColors.textGhost,
              letterSpacing: size * 0.04,
            )),
      ]),
    ]);
  }
}

class _NyxLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rect = Rect.fromLTWH(0, 0, s, s);
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.24));

    // Background
    canvas.drawRRect(rr, Paint()..color = const Color(0xFF08070F));
    canvas.clipRRect(rr);

    // Left ear
    final leftEar = Path()
      ..moveTo(s * 0.22, s * 0.50)
      ..lineTo(s * 0.12, s * 0.07)
      ..lineTo(s * 0.43, s * 0.36)
      ..close();
    canvas.drawPath(leftEar, Paint()..color = const Color(0xFF1E1248));

    // Right ear
    final rightEar = Path()
      ..moveTo(s * 0.78, s * 0.50)
      ..lineTo(s * 0.88, s * 0.07)
      ..lineTo(s * 0.57, s * 0.36)
      ..close();
    canvas.drawPath(rightEar, Paint()..color = const Color(0xFF1E1248));

    // Face circle
    canvas.drawCircle(
      Offset(s * 0.50, s * 0.60),
      s * 0.32,
      Paint()..color = const Color(0xFF1E1248),
    );

    // Left ear inner
    final leftInner = Path()
      ..moveTo(s * 0.26, s * 0.46)
      ..lineTo(s * 0.18, s * 0.13)
      ..lineTo(s * 0.40, s * 0.37)
      ..close();
    canvas.drawPath(leftInner, Paint()..color = const Color(0xFF120C30));

    // Right ear inner
    final rightInner = Path()
      ..moveTo(s * 0.74, s * 0.46)
      ..lineTo(s * 0.82, s * 0.13)
      ..lineTo(s * 0.60, s * 0.37)
      ..close();
    canvas.drawPath(rightInner, Paint()..color = const Color(0xFF120C30));

    // Eyes - outer glow
    final eyePaint = Paint()..color = const Color(0xFF7C3AED);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(s * 0.38, s * 0.58), width: s * 0.15, height: s * 0.065),
        eyePaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(s * 0.62, s * 0.58), width: s * 0.15, height: s * 0.065),
        eyePaint);

    // Eyes - inner bright
    final eyeInner = Paint()..color = const Color(0xFFA78BFA);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(s * 0.38, s * 0.58), width: s * 0.07, height: s * 0.05),
        eyeInner);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(s * 0.62, s * 0.58), width: s * 0.07, height: s * 0.05),
        eyeInner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
