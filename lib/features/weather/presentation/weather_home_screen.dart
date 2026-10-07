import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hava/core/date/persian_date.dart';
import 'package:hava/core/format/persian_digits.dart';
import 'package:hava/core/widgets/soft_reveal.dart';
import 'package:hava/features/air_quality/application/air_quality_controller.dart';
import 'package:hava/features/air_quality/presentation/air_quality_detail_screen.dart';
import 'package:hava/features/location/application/city_controller.dart';
import 'package:hava/features/weather/application/weather_controller.dart';
import 'package:hava/features/weather/presentation/daily_detail_screen.dart';
import 'package:hava/features/weather/presentation/widgets/temperature_trend_card.dart';
import 'package:hava/features/weather/presentation/widgets/weather_palette.dart';
import 'package:hava/features/weather/presentation/widgets/weather_scene.dart';

class WeatherHomeScreen extends ConsumerWidget {
  const WeatherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider);
    final aqi = ref.watch(airQualityProvider);
    final city = ref.watch(selectedCityProvider);

    return Scaffold(
      body: SafeArea(
        child: weather.when(
          loading: () => const _LoadingState(),
          error: (error, _) => _ErrorState(
            message: error.toString().replaceFirst('Bad state: ', ''),
            onRetry: () => ref.invalidate(weatherProvider),
          ),
          data: (data) {
            final current = data.current;
            final today = data.daily.first;
            final weeklyMin = data.daily
                .map((day) => day.minTemperature)
                .reduce((a, b) => a < b ? a : b);
            final weeklyMax = data.daily
                .map((day) => day.maxTemperature)
                .reduce((a, b) => a > b ? a : b);
            final palette = WeatherPalette.resolve(
              weatherCode: current.weatherCode,
              now: current.updatedAt,
              sunrise: today.sunrise,
              sunset: today.sunset,
              brightness: Theme.of(context).brightness,
            );
            final heroColors = palette.colors;
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(weatherProvider);
                ref.invalidate(airQualityProvider);
                await ref.read(weatherProvider.future);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              city?.name ?? 'موقعیت فعلی',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              persianDateLabel(DateTime.now()),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'بروزرسانی',
                        onPressed: () => ref.invalidate(weatherProvider),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: heroColors,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: heroColors.first.withValues(alpha: .22),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: WeatherScene(
                            weatherCode: current.weatherCode,
                            isNight: palette.isNight,
                            accent: palette.accent,
                          ),
                        ),
                        Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .18),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Icon(
                                _weatherIcon(current.weatherCode),
                                size: 40,
                                color: palette.foreground,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _weatherLabel(current.weatherCode),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: palette.foreground,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          toPersianDigits(current.temperature.round()) + '°',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -3,
                                color: palette.foreground,
                              ),
                        ),
                        Text(
                          'احساسی ' +
                              toPersianDigits(
                                current.apparentTemperature.round(),
                              ) +
                              '°',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),

                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _MetricChip(
                              icon: Icons.arrow_upward_rounded,
                              label: 'بیشینه',
                              value: toPersianDigits(today.maxTemperature.round()) + '°',
                            ),
                            const SizedBox(width: 8),
                            _MetricChip(
                              icon: Icons.arrow_downward_rounded,
                              label: 'کمینه',
                              value: toPersianDigits(today.minTemperature.round()) + '°',
                            ),
                          ],
                        ),

                      ],
                    ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SoftReveal(child: TemperatureTrendCard(hours: data.hourly)),
                  const SizedBox(height: 18),
                  aqi.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (value) => Card(
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.air_rounded),
                        title: Text('کیفیت هوا: ${value.label}'),
                        subtitle: Text('AQI ${toPersianDigits(value.usAqi)} • UV ${toPersianDigits(value.uvIndex.toStringAsFixed(1))}'),
                        trailing: const Icon(Icons.chevron_left_rounded),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => AirQualityDetailScreen(
                              airQuality: value,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(title: '۵ روز آینده'),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: data.daily.take(5).map((day) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => DailyDetailScreen(
                                  day: day,
                                  hours: data.hourly,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
                              ),
                              child: Row(
                              children: [
                                SizedBox(
                                  width: 105,
                                  child: Text(
                                    persianDateLabel(day.date).split('،').first,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Icon(_weatherIcon(day.weatherCode), size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  toPersianDigits(
                                        day.precipitationProbability,
                                      ) +
                                      '٪',
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _TemperatureRangeBar(
                                    min: day.minTemperature,
                                    max: day.maxTemperature,
                                    globalMin: weeklyMin,
                                    globalMax: weeklyMax,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${toPersianDigits(day.minTemperature.round())}°',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${toPersianDigits(day.maxTemperature.round())}°',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w900),
      );
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 7),
            Text('$label  $value'),
          ],
        ),
      );
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
          6,
          (index) => Container(
            height: index == 0 ? 280 : 110,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 72),
              const SizedBox(height: 16),
              const Text(
                'هوا فعلاً در دسترس نیست',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('دوباره تلاش کن'),
              ),
            ],
          ),
        ),
      );
}

String _weatherLabel(int code) {
  if (code == 0) return 'صاف';
  if (code <= 3) return 'نیمه‌ابری';
  if (code <= 48) return 'مه‌آلود';
  if (code <= 67) return 'بارانی';
  if (code <= 77) return 'برفی';
  if (code <= 82) return 'رگبار';
  if (code <= 86) return 'برف';
  return 'رعدوبرق';
}

IconData _weatherIcon(int code) {
  if (code == 0) return Icons.wb_sunny_rounded;
  if (code <= 3) return Icons.cloud_rounded;
  if (code <= 48) return Icons.foggy;
  if (code <= 67) return Icons.water_drop_rounded;
  if (code <= 77) return Icons.ac_unit_rounded;
  if (code <= 82) return Icons.grain_rounded;
  if (code <= 86) return Icons.ac_unit_rounded;
  return Icons.thunderstorm_rounded;
}



class _TemperatureRangeBar extends StatelessWidget {
  const _TemperatureRangeBar({
    required this.min,
    required this.max,
    required this.globalMin,
    required this.globalMax,
  });

  final double min;
  final double max;
  final double globalMin;
  final double globalMax;

  @override
  Widget build(BuildContext context) {
    final range = (globalMax - globalMin).abs() < .1
        ? 1.0
        : globalMax - globalMin;
    final start = ((min - globalMin) / range).clamp(0.0, 1.0);
    final end = ((max - globalMin) / range).clamp(0.0, 1.0);

    return SizedBox(
      height: 8,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final left = width * start;
          final barWidth = (width * (end - start)).clamp(8.0, width);
          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Positioned(
                left: left,
                width: barWidth,
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF55B8FF),
                        Color(0xFFFFC95A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
