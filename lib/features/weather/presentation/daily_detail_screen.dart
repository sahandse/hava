import 'package:flutter/material.dart';
import 'package:hava/core/date/persian_date.dart';
import 'package:hava/core/format/persian_digits.dart';
import 'package:hava/core/widgets/soft_reveal.dart';
import 'package:hava/features/weather/domain/weather_models.dart';
import 'package:hava/features/weather/presentation/widgets/temperature_trend_card.dart';
import 'package:hava/features/weather/presentation/widgets/weather_palette.dart';
import 'package:hava/features/weather/presentation/widgets/weather_scene.dart';

class DailyDetailScreen extends StatelessWidget {
  const DailyDetailScreen({
    required this.day,
    required this.hours,
    super.key,
  });

  final DailyWeather day;
  final List<HourlyWeather> hours;

  @override
  Widget build(BuildContext context) {
    final dayHours = hours.where((hour) {
      return hour.time.year == day.date.year &&
          hour.time.month == day.date.month &&
          hour.time.day == day.date.day;
    }).toList();

    final palette = WeatherPalette.resolve(
      weatherCode: day.weatherCode,
      now: DateTime(day.date.year, day.date.month, day.date.day, 12),
      sunrise: day.sunrise,
      sunset: day.sunset,
      brightness: Theme.of(context).brightness,
    );

    return Scaffold(
      appBar: AppBar(title: Text(persianDateLabel(day.date))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SoftReveal(
            child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: palette.colors,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: WeatherScene(
                    weatherCode: day.weatherCode,
                    isNight: palette.isNight,
                    accent: palette.accent,
                  ),
                ),
                Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 34),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${toPersianDigits(day.maxTemperature.round())}° / '
                          '${toPersianDigits(day.minTemperature.round())}°',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'احتمال بارش ${toPersianDigits(day.precipitationProbability)}٪',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ],
            ),
          ),
          ),
          const SizedBox(height: 12),
          SoftReveal(child: TemperatureTrendCard(hours: dayHours)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _Tile(
                icon: Icons.water_drop_outlined,
                title: 'بارش',
                value: '${toPersianDigits(day.precipitationSum)} mm',
              ),
              _Tile(
                icon: Icons.air_rounded,
                title: 'بیشترین باد',
                value: '${toPersianDigits(day.maxWindSpeed.round())} km/h',
              ),
              _Tile(
                icon: Icons.wb_sunny_outlined,
                title: 'بیشترین UV',
                value: toPersianDigits(day.uvIndexMax.toStringAsFixed(1)),
              ),
              _Tile(
                icon: Icons.light_mode_outlined,
                title: 'روشنایی روز',
                value: _duration(day.daylightDuration),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.wb_twilight_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'طلوع ${_time(day.sunrise)}  •  غروب ${_time(day.sunset)}',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (dayHours.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'ساعت‌به‌ساعت',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ...dayHours.map(
              (hour) => ListTile(
                leading: Text(_time(hour.time)),
                title: Text(
                  '${toPersianDigits(hour.temperature.round())}°',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  'بارش ${toPersianDigits(hour.precipitationProbability)}٪'
                  ' • باد ${toPersianDigits(hour.windSpeed.round())} km/h'
                  ' • UV ${toPersianDigits(hour.uvIndex.toStringAsFixed(1))}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _duration(double seconds) {
    final hours = seconds / 3600;
    return '${toPersianDigits(hours.toStringAsFixed(1))} ساعت';
  }

  String _time(DateTime time) =>
      '${toPersianDigits(time.hour.toString().padLeft(2, '0'))}:'
      '${toPersianDigits(time.minute.toString().padLeft(2, '0'))}';
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: .55),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20),
              const Spacer(),
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        ),
      );
}
