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

    final maxRain = values
        .map((e) => e.precipitationProbability)
        .reduce(math.max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '۲۴ ساعت آینده',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const Spacer(),
                Icon(
                  Icons.auto_graph_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final hour = values[index];
                  final selected = index == 0;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 62,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          index == 0
                              ? 'اکنون'
                              : '${toPersianDigits(hour.time.hour.toString().padLeft(2, '0'))}:۰۰',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          '${toPersianDigits(hour.temperature.round())}°',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.water_drop_outlined, size: 11),
                            const SizedBox(width: 2),
                            Text(
                              '${toPersianDigits(hour.precipitationProbability)}٪',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 128,
              width: double.infinity,
              child: CustomPaint(
                painter: _TrendPainter(
                  hours: values,
                  lineColor: Theme.of(context).colorScheme.primary,
                  rainColor: const Color(0xFF47B8FF),
                  gridColor: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: .32),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _CompactLegend(
                  icon: Icons.thermostat_rounded,
                  text:
                      '${toPersianDigits(values.first.temperature.round())}° → '
                      '${toPersianDigits(values.last.temperature.round())}°',
                ),
                const Spacer(),
                _CompactLegend(
                  icon: Icons.water_drop_outlined,
                  text: 'تا ${toPersianDigits(maxRain)}٪ بارش',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactLegend extends StatelessWidget {
  const _CompactLegend({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15),
            const SizedBox(width: 4),
            Text(text, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      );
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
      ..color = rainColor.withValues(alpha: .16)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < hours.length; i++) {
      final probability = hours[i].precipitationProbability / 100;
      final height = probability * size.height * .5;
      final barWidth = math.max(2.0, dx * .5);
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
      final y = size.height - 16 - normalized * (size.height - 32);
      final point = Offset(i * dx, y);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    final glow = Paint()
      ..color = lineColor.withValues(alpha: .2)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, glow);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
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
