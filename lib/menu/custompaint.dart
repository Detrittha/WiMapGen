import 'package:flutter/material.dart';

class CirclePainter extends CustomPainter {
  final Color color;
  final Size screenSize;

  CirclePainter(this.color, this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    double sizeCircle = screenSize.width * 0.15;
    Paint paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withOpacity(0.0)],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: sizeCircle,
        ),
      );

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      sizeCircle,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
 