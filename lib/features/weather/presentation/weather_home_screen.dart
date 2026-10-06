import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hava/core/date/persian_date.dart';
import 'package:hava/core/format/persian_digits.dart';
import 'package:hava/features/air_quality/application/air_quality_controller.dart';
import 'package:hava/features/air_quality/presentation/air_quality_detail_screen.dart';
import 'package:hava/features/location/application/city_controller.dart';
import 'package:hava/features/location/presentation/city_search_screen.dart';
import 'package:hava/features/weather/application/weather_controller.dart';
import 'package:hava/features/weather/domain/weather_summary.dart';
import 'package:hava/features/weather/domain/weather_models.dart';
import 'package:hava/features/weather/domain/moon_phase.dart';
import 'package:hava/features/weather/presentation/daily_detail_screen.dart';
import 'package:hava/features/weather/presentation/widgets/temperature_trend_card.dart';

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
            final nowVisibility = data.hourly.isNotEmpty
                ? data.hourly.first.visibility / 1000
                : 0.0;
            final today = data.daily.first;
            final summary = buildWeatherSummary(
              current: current,
              today: today,
              hourly: data.hourly,
            );
            final heroColors = _heroColors(
              context,
              current.weatherCode,
              current.updatedAt,
              today.sunrise,
              today.sunset,
            );
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
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const CitySearchScreen(),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 2,
                            ),
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
                                Text(
                                  persianDateLabel(DateTime.now()),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const CitySearchScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.location_on_outlined),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filledTonal(
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
                        Positioned(
                          left: -26,
                          top: -28,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: .12),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -40,
                          bottom: -46,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: .08),
                            ),
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
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _weatherLabel(current.weatherCode),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ],
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
                          'احساسی ' +
                              toPersianDigits(
                                current.apparentTemperature.round(),
                              ) +
                              '°',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          summary,
                          style: Theme.of(context).textTheme.bodyMedium,
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
                        const SizedBox(height: 22),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MetricChip(
                              icon: Icons.water_drop_outlined,
                              label: 'رطوبت',
                              value: toPersianDigits(current.humidity) + '٪',
                            ),
                            _MetricChip(
                              icon: Icons.air_rounded,
                              label: 'باد',
                              value: toPersianDigits(
                                    current.windSpeed.round(),
                                  ) +
                                  ' km/h',
                            ),
                            _MetricChip(
                              icon: Icons.grain_rounded,
                              label: 'بارش',
                              value: toPersianDigits(current.precipitation) +
                                  ' mm',
                            ),
                          ],
                        ),
                      ],
                    ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(title: 'پیش‌بینی ساعتی'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 126,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: data.hourly.length > 24 ? 24 : data.hourly.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final hour = data.hourly[index];
                        return Container(
                          width: 78,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: index == 0
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: .45),
                            ),
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
                  const SizedBox(height: 16),
                  TemperatureTrendCard(hours: data.hourly),
                  const SizedBox(height: 22),
                  _SectionTitle(title: 'وضعیت هوا'),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.7,
                    children: [
                      aqi.when(
                        loading: () => const _InfoCard(
                          icon: Icons.air_rounded,
                          title: 'کیفیت هوا',
                          value: '...',
                          subtitle: 'در حال دریافت',
                        ),
                        error: (_, __) => const _InfoCard(
                          icon: Icons.air_rounded,
                          title: 'کیفیت هوا',
                          value: '—',
                          subtitle: 'در دسترس نیست',
                        ),
                        data: (value) => _InfoCard(
                          icon: Icons.air_rounded,
                          title: 'کیفیت هوا',
                          value: toPersianDigits(value.usAqi),
                          subtitle: value.label,
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
                      aqi.when(
                        loading: () => const _InfoCard(
                          icon: Icons.wb_sunny_outlined,
                          title: 'UV',
                          value: '...',
                          subtitle: 'شاخص فرابنفش',
                        ),
                        error: (_, __) => const _InfoCard(
                          icon: Icons.wb_sunny_outlined,
                          title: 'UV',
                          value: '—',
                          subtitle: 'در دسترس نیست',
                        ),
                        data: (value) => _InfoCard(
                          icon: Icons.wb_sunny_outlined,
                          title: 'UV',
                          value: toPersianDigits(value.uvIndex.toStringAsFixed(1)),
                          subtitle: _uvLabel(value.uvIndex),
                        ),
                      ),
                      _InfoCard(
                        icon: Icons.speed_rounded,
                        title: 'فشار',
                        value: toPersianDigits(
                              current.surfacePressure.round(),
                            ) +
                            ' hPa',
                        subtitle: 'فشار سطح',
                      ),
                      _InfoCard(
                        icon: Icons.visibility_outlined,
                        title: 'دید',
                        value: toPersianDigits(
                              nowVisibility.toStringAsFixed(1),
                            ) +
                            ' km',
                        subtitle: 'دید افقی',
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(title: '۱۰ روز آینده'),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: data.daily.map((day) {
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
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SunMoonCard(day: data.daily.first),
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _metricAccent(title);
    return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  accent.withValues(alpha: .16),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 19),
                  const SizedBox(width: 6),
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        ),
        ),
      );
  }
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

String _time(DateTime time) =>
    toPersianDigits(time.hour.toString().padLeft(2, '0')) +
    ':' +
    toPersianDigits(time.minute.toString().padLeft(2, '0'));

String _uvLabel(double value) {
  if (value < 3) return 'کم';
  if (value < 6) return 'متوسط';
  if (value < 8) return 'زیاد';
  if (value < 11) return 'خیلی زیاد';
  return 'بسیار شدید';
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


List<Color> _heroColors(
  BuildContext context,
  int code,
  DateTime now,
  DateTime sunrise,
  DateTime sunset,
) {
  final scheme = Theme.of(context).colorScheme;
  final isNight = now.isBefore(sunrise) || now.isAfter(sunset);

  if (isNight) {
    return [
      scheme.surfaceContainerHighest,
      scheme.primaryContainer,
    ];
  }
  if (code >= 51 && code <= 99) {
    return [
      scheme.secondaryContainer,
      scheme.surfaceContainerHighest,
    ];
  }
  if (code >= 71 && code <= 86) {
    return [
      scheme.tertiaryContainer,
      scheme.surfaceContainerLow,
    ];
  }
  return [
    scheme.primaryContainer,
    scheme.secondaryContainer,
  ];
}


class _SunMoonCard extends StatelessWidget {
  const _SunMoonCard({required this.day});

  final DailyWeather day;

  @override
  Widget build(BuildContext context) {
    final moon = moonPhaseFor(day.date);
    final daylightHours = day.daylightDuration / 3600;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
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
            const Divider(height: 24),
            Row(
              children: [
                Text(moon.symbol, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${moon.name} • روشنایی روز '
                    '${toPersianDigits(daylightHours.toStringAsFixed(1))} ساعت',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


Color _metricAccent(String title) {
  switch (title) {
    case 'کیفیت هوا':
      return const Color(0xFF35C98B);
    case 'UV':
      return const Color(0xFFFFB547);
    case 'فشار':
      return const Color(0xFF8B7CFF);
    case 'دید':
      return const Color(0xFF55B8FF);
    default:
      return const Color(0xFF4B7BFF);
  }
}
