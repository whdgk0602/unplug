import 'dart:math';
import 'package:flutter/material.dart';

class IslandPainter extends CustomPainter {
  final int stage;
  final double animationValue;

  const IslandPainter({required this.stage, this.animationValue = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    _drawSky(canvas, size);
    _drawClouds(canvas, size, cx, cy);
    _drawOcean(canvas, size, cx, cy);

    if (stage == 0) {
      _drawEmptyWaves(canvas, size, cx, cy);
      return;
    }

    _drawIslandBase(canvas, size, cx, cy);

    if (stage >= 2) _drawGrass(canvas, size, cx, cy);
    if (stage >= 3) _drawPalmTree(canvas, size, cx - size.width * 0.08, cy - size.height * 0.22, 0.7);
    if (stage >= 4) {
      _drawRock(canvas, cx + size.width * 0.1, cy - size.height * 0.1, size.width * 0.04);
      _drawPalmTree(canvas, size, cx + size.width * 0.12, cy - size.height * 0.2, 0.6);
    }
    if (stage >= 5) {
      _drawHut(canvas, size, cx - size.width * 0.05, cy - size.height * 0.28);
      _drawBush(canvas, cx - size.width * 0.18, cy - size.height * 0.12, size.width * 0.05);
    }
    if (stage >= 6) {
      _drawPalmTree(canvas, size, cx + size.width * 0.22, cy - size.height * 0.18, 0.8);
      _drawDock(canvas, size, cx, cy);
    }
    if (stage >= 7) {
      _drawLighthouse(canvas, size, cx + size.width * 0.04, cy - size.height * 0.35);
    }
    if (stage >= 8) {
      _drawBush(canvas, cx + size.width * 0.18, cy - size.height * 0.1, size.width * 0.04);
      _drawBush(canvas, cx - size.width * 0.22, cy - size.height * 0.08, size.width * 0.06);
    }
    if (stage >= 9) {
      _drawPalmTree(canvas, size, cx - size.width * 0.25, cy - size.height * 0.22, 0.65);
      _drawRock(canvas, cx - size.width * 0.05, cy - size.height * 0.08, size.width * 0.03);
    }
    if (stage >= 10) {
      _drawRainbow(canvas, size, cx, cy);
    }

    _drawIslandEdge(canvas, size, cx, cy);
    _drawOceanSheen(canvas, size, cx, cy);
  }

  void _drawSky(Canvas canvas, Size size) {
    final paint = Paint();
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.center,
      colors: [Color(0xFFD4EEFF), Color(0xFFEFF8FF)],
    ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _drawClouds(Canvas canvas, Size size, double cx, double cy) {
    final paint = Paint()..color = Colors.white.withOpacity(0.85);

    // Left cloud
    _drawCloud(canvas, paint, cx * 0.2, cy * 0.3, size.width * 0.15);
    // Right cloud
    _drawCloud(canvas, paint, cx * 1.5, cy * 0.22, size.width * 0.12);
    if (stage >= 5) {
      _drawCloud(canvas, paint, cx * 0.6, cy * 0.15, size.width * 0.1);
    }
  }

  void _drawCloud(Canvas canvas, Paint paint, double x, double y, double r) {
    canvas.drawCircle(Offset(x, y), r * 0.6, paint);
    canvas.drawCircle(Offset(x + r * 0.5, y + r * 0.1), r * 0.45, paint);
    canvas.drawCircle(Offset(x - r * 0.45, y + r * 0.15), r * 0.4, paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y + r * 0.35), width: r * 2, height: r * 0.5), paint);
  }

  void _drawOcean(Canvas canvas, Size size, double cx, double cy) {
    final paint = Paint();
    final oceanTop = cy * 0.85;
    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [Color(0xFF5BB8F5), Color(0xFF1976D2)],
    ).createShader(Rect.fromLTWH(0, oceanTop, size.width, size.height - oceanTop));

    final path = Path()
      ..moveTo(0, oceanTop)
      ..quadraticBezierTo(cx * 0.5, oceanTop - 10, cx, oceanTop)
      ..quadraticBezierTo(cx * 1.5, oceanTop + 10, size.width, oceanTop)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawOceanSheen(Canvas canvas, Size size, double cx, double cy) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final y = cy * 0.9;
    canvas.drawLine(Offset(cx * 0.4, y), Offset(cx * 0.8, y), paint);
    canvas.drawLine(Offset(cx * 1.2, y + 8), Offset(cx * 1.6, y + 8), paint);
  }

  void _drawEmptyWaves(Canvas canvas, Size size, double cx, double cy) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final y = cy * 0.88;
    for (int i = 0; i < 3; i++) {
      final path = Path()
        ..moveTo(cx * 0.3 + i * 20, y + i * 15)
        ..cubicTo(
          cx * 0.6 + i * 20, y - 8 + i * 15,
          cx * 0.9 + i * 20, y + 8 + i * 15,
          cx * 1.3 + i * 20, y + i * 15,
        );
      canvas.drawPath(path, paint);
    }
  }

  void _drawIslandBase(Canvas canvas, Size size, double cx, double cy) {
    final islandCy = cy * 0.88;
    final rX = size.width * 0.38;
    final rY = size.height * 0.1;

    // Shadow
    final shadowPaint = Paint()..color = const Color(0x33000000);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, islandCy + rY * 0.5), width: rX * 1.8, height: rY * 0.6),
      shadowPaint,
    );

    // Cliff face (3D side)
    final cliffPaint = Paint()..color = const Color(0xFFD4A574);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, islandCy + rY * 0.3), width: rX * 2, height: rY * 1.2),
      cliffPaint,
    );

    // Top surface (sand)
    final sandPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.5),
        colors: const [Color(0xFFFFF0C8), Color(0xFFF5DEB3)],
      ).createShader(Rect.fromCenter(center: Offset(cx, islandCy - rY), width: rX * 2, height: rY * 2));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, islandCy - rY * 0.1), width: rX * 2, height: rY * 1.5),
      sandPaint,
    );
  }

  void _drawIslandEdge(Canvas canvas, Size size, double cx, double cy) {
    final islandCy = cy * 0.88;
    final rX = size.width * 0.38;
    final rY = size.height * 0.1;
    final paint = Paint()
      ..color = const Color(0xFFDEB887).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, islandCy - rY * 0.1), width: rX * 2, height: rY * 1.5),
      paint,
    );
  }

  void _drawGrass(Canvas canvas, Size size, double cx, double cy) {
    final islandCy = cy * 0.88;
    final rX = size.width * 0.32;
    final rY = size.height * 0.12;

    final grassPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.6),
        colors: const [Color(0xFFA8E063), Color(0xFF56AB2F)],
      ).createShader(Rect.fromCenter(center: Offset(cx, islandCy - rY * 1.2), width: rX * 2, height: rY * 2));

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, islandCy - rY * 1.1), width: rX * 2, height: rY * 1.3),
      grassPaint,
    );
  }

  void _drawPalmTree(Canvas canvas, Size size, double x, double y, double scale) {
    final trunkPaint = Paint()
      ..color = const Color(0xFF8B6914)
      ..strokeWidth = size.width * 0.025 * scale
      ..strokeCap = StrokeCap.round;

    // Trunk (slightly curved)
    final trunkHeight = size.height * 0.18 * scale;
    final path = Path()
      ..moveTo(x, y + trunkHeight)
      ..quadraticBezierTo(x + trunkHeight * 0.1, y + trunkHeight * 0.5, x, y);
    canvas.drawPath(path, trunkPaint..style = PaintingStyle.stroke);

    // Leaves
    final leafPaint = Paint()..style = PaintingStyle.fill;
    final leafColors = [const Color(0xFF2D6A27), const Color(0xFF3D8B37), const Color(0xFF4CAF50)];
    final angles = [-pi / 4, -pi / 8, 0, pi / 8, pi / 4, -pi / 3, pi / 3];
    final leafLength = size.width * 0.12 * scale;

    for (int i = 0; i < angles.length; i++) {
      leafPaint.color = leafColors[i % leafColors.length];
      final angle = angles[i] - pi / 2;
      final ex = x + cos(angle) * leafLength;
      final ey = y + sin(angle) * leafLength;
      final leafPath = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(
          x + cos(angle + pi / 12) * leafLength * 0.5,
          y + sin(angle + pi / 12) * leafLength * 0.5,
          ex,
          ey,
        );
      canvas.drawPath(leafPath, Paint()
        ..color = leafColors[i % leafColors.length]
        ..strokeWidth = size.width * 0.025 * scale
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke);  // ignore: avoid_dynamic_calls
    }

    // Coconuts
    if (scale > 0.65) {
      final coconutPaint = Paint()..color = const Color(0xFF8B4513);
      canvas.drawCircle(Offset(x - 4, y + 5), 4 * scale, coconutPaint);
      canvas.drawCircle(Offset(x + 3, y + 6), 3.5 * scale, coconutPaint);
    }
  }

  void _drawRock(Canvas canvas, double x, double y, double r) {
    final rockPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.5),
        colors: const [Color(0xFFBDBDBD), Color(0xFF757575)],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: r));
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: r * 2.2, height: r * 1.5), rockPaint);
  }

  void _drawBush(Canvas canvas, double x, double y, double r) {
    final paint = Paint()..color = const Color(0xFF388E3C);
    canvas.drawCircle(Offset(x, y), r, paint);
    paint.color = const Color(0xFF4CAF50);
    canvas.drawCircle(Offset(x - r * 0.4, y - r * 0.2), r * 0.7, paint);
    canvas.drawCircle(Offset(x + r * 0.4, y - r * 0.2), r * 0.7, paint);
    paint.color = const Color(0xFF66BB6A);
    canvas.drawCircle(Offset(x, y - r * 0.4), r * 0.6, paint);
  }

  void _drawHut(Canvas canvas, Size size, double x, double y) {
    final wallPaint = Paint()..color = const Color(0xFFFFF8DC);
    final roofPaint = Paint()..color = const Color(0xFFCD853F);
    final doorPaint = Paint()..color = const Color(0xFF8B4513);

    final w = size.width * 0.1;
    final h = size.height * 0.08;

    // Wall
    canvas.drawRect(Rect.fromLTWH(x - w / 2, y, w, h), wallPaint);
    // Door
    canvas.drawRect(Rect.fromLTWH(x - w * 0.15, y + h * 0.5, w * 0.3, h * 0.5), doorPaint);
    // Roof (triangle)
    final roofPath = Path()
      ..moveTo(x - w * 0.6, y)
      ..lineTo(x, y - h * 0.6)
      ..lineTo(x + w * 0.6, y)
      ..close();
    canvas.drawPath(roofPath, roofPaint);
    // Roof highlight
    roofPaint.color = const Color(0xFFD2691E);
    roofPaint.style = PaintingStyle.stroke;
    roofPaint.strokeWidth = 1;
    canvas.drawPath(roofPath, roofPaint);
  }

  void _drawDock(Canvas canvas, Size size, double cx, double cy) {
    final dockPaint = Paint()
      ..color = const Color(0xFF8B6914)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final waterY = cy * 0.92;
    canvas.drawLine(Offset(cx + size.width * 0.25, cy * 0.85), Offset(cx + size.width * 0.38, waterY), dockPaint);
    dockPaint.strokeWidth = 2.5;
    canvas.drawLine(Offset(cx + size.width * 0.27, cy * 0.87), Offset(cx + size.width * 0.4, waterY), dockPaint);
    // Planks
    dockPaint.strokeWidth = 1.5;
    for (int i = 0; i < 3; i++) {
      final t = 0.3 + i * 0.25;
      final y1 = cy * 0.85 + (waterY - cy * 0.85) * t;
      final x1 = cx + size.width * (0.25 + 0.13 * t);
      canvas.drawLine(Offset(x1 - 5, y1), Offset(x1 + 3, y1 + 2), dockPaint);
    }
  }

  void _drawLighthouse(Canvas canvas, Size size, double x, double y) {
    final bodyPaint = Paint()..color = const Color(0xFFF5F5F5);
    final stripePaint = Paint()..color = const Color(0xFFE53935);
    final lightPaint = Paint()..color = const Color(0xFFFFEB3B);
    final roofPaint = Paint()..color = const Color(0xFF546E7A);

    final w = size.width * 0.045;
    final h = size.height * 0.14;

    // Body
    canvas.drawRect(Rect.fromLTWH(x - w / 2, y, w, h), bodyPaint);
    // Stripes
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(Rect.fromLTWH(x - w / 2, y + h * (0.2 + i * 0.25), w, h * 0.1), stripePaint);
    }
    // Light room
    canvas.drawRect(Rect.fromLTWH(x - w * 0.7, y - h * 0.12, w * 1.4, h * 0.12), Paint()..color = const Color(0xFF546E7A));
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y - h * 0.06), width: w * 1.2, height: h * 0.1), lightPaint);
    // Roof
    final roofPath = Path()
      ..moveTo(x - w * 0.8, y - h * 0.12)
      ..lineTo(x, y - h * 0.26)
      ..lineTo(x + w * 0.8, y - h * 0.12)
      ..close();
    canvas.drawPath(roofPath, roofPaint);
    // Light beam
    final beamPaint = Paint()..color = const Color(0x33FFD700);
    final beamPath = Path()
      ..moveTo(x, y - h * 0.06)
      ..lineTo(x - w * 3, y - h * 0.5)
      ..lineTo(x + w * 3, y - h * 0.5)
      ..close();
    canvas.drawPath(beamPath, beamPaint);
  }

  void _drawRainbow(Canvas canvas, Size size, double cx, double cy) {
    final colors = [
      const Color(0x66E91E63),
      const Color(0x66FF5722),
      const Color(0x66FFC107),
      const Color(0x664CAF50),
      const Color(0x662196F3),
      const Color(0x669C27B0),
    ];
    for (int i = 0; i < colors.length; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke;
      final r = size.width * (0.3 + i * 0.04);
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, cy * 0.7), width: r * 2, height: r),
        pi,
        pi,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(IslandPainter oldDelegate) {
    return oldDelegate.stage != stage || oldDelegate.animationValue != animationValue;
  }
}
