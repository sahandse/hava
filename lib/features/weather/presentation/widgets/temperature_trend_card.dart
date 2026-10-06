import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hava/core/format/persian_digits.dart';
import 'package:hava/features/weather/domain/weather_models.dart';

class TemperatureTrendCard extends StatelessWidget {
  const TemperatureTrendCard({
    required this.hours,
    super.key,
  });

  final List<HourlyWeather> hours;

  @override
  Widget build(BuildContext context) {
    final values = hours.take(24).toList();
    if (values.length < 2) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'روند ۲۴ ساعت',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const Spacer(),
                const Icon(Icons.show_chart_rounded, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              width: double.infinity,
              child: CustomPaint(
                painter: _TrendPainter(
                  hours: values,
                  lineColor: Theme.of(context).colorScheme.primary,
                  rainColor: Theme.of(context).colorScheme.secondary,
                  gridColor: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: .45),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _LegendDot(
                  icon: Icons.thermostat_rounded,
                  label: 'دما',
                  value:
                      '${toPersianDigits(values.first.temperature.round())}° → '
                      '${toPersianDigits(values.last.temperature.round())}°',
                ),
                const Spacer(),
                _LegendDot(
                  icon: Icons.water_drop_outlined,
                  label: 'بیشترین بارش',
                  value:
                      '${toPersianDigits(values.map((e) => e.precipitationProbability).reduce(math.max))}٪',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17),
        const SizedBox(width: 5),
        Text(
          '$label  $value',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.hours,
    required this.lineColor,
    required this.rainColor,
    required this.gridColor,
  });

  final List<HourlyWeather> hours;
  final Color lineColor;
  final Color rainColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final temps = hours.map((e) => e.temperature).toList();
    final minTemp = temps.reduce(math.min);
    final maxTemp = temps.reduce(math.max);
    final range = math.max(1.0, maxTemp - minTemp);
    final dx = size.width / (hours.length - 1);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final rainPaint = Paint()
      ..color = rainColor.withValues(alpha: .18)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < hours.length; i++) {
      final probability = hours[i].precipitationProbability / 100;
      final height = probability * size.height * .55;
      final barWidth = math.max(2.0, dx * .45);
      final x = i * dx - barWidth / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x.clamp(0, size.width - barWidth),
            size.height - height,
            barWidth,
            height,
          ),
          const Radius.circular(3),
        ),
        rainPaint,
      );
    }

    final path = Path();
    for (var i = 0; i < hours.length; i++) {
      final normalized = (hours[i].temperature - minTemp) / range;
      final y = size.height - 18 - normalized * (size.height - 36);
      final point = Offset(i * dx, y);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.hours != hours ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.rainColor != rainColor;
}
