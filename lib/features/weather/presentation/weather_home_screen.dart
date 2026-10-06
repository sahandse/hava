import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hava/core/format/persian_digits.dart';
import 'package:hava/features/weather/application/weather_controller.dart';

class WeatherHomeScreen extends ConsumerWidget {
  const WeatherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider);

    return Scaffold(
      body: SafeArea(
        child: weather.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            message: error.toString().replaceFirst('Bad state: ', ''),
            onRetry: () => ref.invalidate(weatherProvider),
          ),
          data: (data) {
            final current = data.current;
            return RefreshIndicator(
              onRefresh: () => ref.refresh(weatherProvider.future),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'هوا',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => ref.invalidate(weatherProvider),
                        tooltip: 'بروزرسانی',
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Theme.of(context).colorScheme.primaryContainer,
                          Theme.of(context).colorScheme.secondaryContainer,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _weatherIcon(current.weatherCode),
                          size: 58,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          toPersianDigits(current.temperature.round()) + '°',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -3,
                              ),
                        ),
                        Text(
                          'دمای احساسی ' +
                              toPersianDigits(current.apparentTemperature.round()) +
                              '°',
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _Metric(
                                icon: Icons.water_drop_outlined,
                                label: 'رطوبت',
                                value: toPersianDigits(current.humidity) + '٪',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Metric(
                                icon: Icons.air_rounded,
                                label: 'باد',
                                value: toPersianDigits(current.windSpeed.round()) +
                                    ' km/h',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'پیش‌بینی ساعتی',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 124,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: data.hourly.length > 24 ? 24 : data.hourly.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final hour = data.hourly[index];
                        return Container(
                          width: 82,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLow,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                toPersianDigits(
                                      hour.time.hour.toString().padLeft(2, '0'),
                                    ) +
                                    ':۰۰',
                              ),
                              Icon(_weatherIcon(hour.weatherCode)),
                              Text(
                                toPersianDigits(hour.temperature.round()) + '°',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                toPersianDigits(
                                      hour.precipitationProbability,
                                    ) +
                                    '٪',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '۱۰ روز آینده',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: data.daily.map((day) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 82,
                                  child: Text(
                                    _weekday(day.date.weekday),
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
                                const Spacer(),
                                Text(
                                  toPersianDigits(
                                        day.minTemperature.round(),
                                      ) +
                                      '°',
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  toPersianDigits(
                                        day.maxTemperature.round(),
                                      ) +
                                      '°',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
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

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 72),
            const SizedBox(height: 18),
            Text(
              'هوا فعلاً در دسترس نیست',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
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

String _weekday(int weekday) {
  const days = [
    'دوشنبه',
    'سه‌شنبه',
    'چهارشنبه',
    'پنجشنبه',
    'جمعه',
    'شنبه',
    'یکشنبه',
  ];
  return days[weekday - 1];
}
