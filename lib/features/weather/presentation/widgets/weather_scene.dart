import 'dart:math' as math;

import 'package:flutter/material.dart';

class WeatherScene extends StatefulWidget {
  const WeatherScene({
    required this.weatherCode,
    required this.isNight,
    required this.accent,
    super.key,
  });

  final int weatherCode;
  final bool isNight;
  final Color accent;

  @override
  State<WeatherScene> createState() => _WeatherSceneState();
}

class _WeatherSceneState extends State<WeatherScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _WeatherScenePainter(
            progress: _controller.value,
            code: widget.weatherCode,
            night: widget.isNight,
            accent: widget.accent,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _WeatherScenePainter extends CustomPainter {
  const _WeatherScenePainter({
    required this.progress,
    required this.code,
    required this.night,
    required this.accent,
  });

  final double progress;
  final int code;
  final bool night;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    _paintOrb(canvas, size);
    _paintClouds(canvas, size);

    if (code >= 51 && code <= 82) {
      _paintRain(canvas, size);
    }
    if (code >= 71 && code <= 86) {
      _paintSnow(canvas, size);
    }
    if (night) {
      _paintStars(canvas, size);
    }
  }

  void _paintOrb(Canvas canvas, Size size) {
    final center = Offset(size.width * .2, size.height * .18);
    final pulse = 1 + math.sin(progress * math.pi * 2) * .035;
    final radius = 34 * pulse;

    final glow = Paint()
      ..color = accent.withValues(alpha: .18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(center, radius * 1.8, glow);

    final core = Paint()..color = accent.withValues(alpha: night ? .75 : .9);
    canvas.drawCircle(center, radius, core);
  }

  void _paintClouds(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .12);
    final drift = (progress * 42) % (size.width + 120);

    for (var i = 0; i < 3; i++) {
      final x = size.width - drift + (i * 145) - 60;
      final y = size.height * (.18 + i * .16);
      final cloud = Path()
        ..addOval(Rect.fromCircle(center: Offset(x, y), radius: 23))
        ..addOval(Rect.fromCircle(center: Offset(x + 27, y + 3), radius: 18))
        ..addOval(Rect.fromCircle(center: Offset(x - 25, y + 6), radius: 15))
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 42, y + 7, 86, 24),
            const Radius.circular(14),
          ),
        );
      canvas.drawPath(cloud, paint);
    }
  }

  void _paintRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBDEBFF).withValues(alpha: .28)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 22; i++) {
      final x = ((i * 47.0) + progress * 90) % size.width;
      final y = ((i * 31.0) + progress * size.height * 1.7) % size.height;
      canvas.drawLine(Offset(x, y), Offset(x - 5, y + 12), paint);
    }
  }

  void _paintSnow(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .42);

    for (var i = 0; i < 18; i++) {
      final x = ((i * 53.0) + math.sin(progress * 6 + i) * 12) % size.width;
      final y = ((i * 37.0) + progress * size.height) % size.height;
      canvas.drawCircle(Offset(x, y), 1.5 + (i % 3) * .6, paint);
    }
  }

  void _paintStars(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .45);
    for (var i = 0; i < 20; i++) {
      final x = (i * 61.0) % size.width;
      final y = 12 + (i * 29.0) % (size.height * .55);
      final twinkle = .6 + math.sin(progress * 8 + i) * .35;
      canvas.drawCircle(Offset(x, y), math.max(.5, twinkle), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherScenePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.code != code ||
        oldDelegate.night != night ||
        oldDelegate.accent != accent;
  }
}
