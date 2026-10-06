import 'package:flutter/material.dart';
import 'package:hava/core/format/persian_digits.dart';
import 'package:hava/features/air_quality/domain/air_quality.dart';

class AirQualityDetailScreen extends StatelessWidget {
  const AirQualityDetailScreen({
    required this.airQuality,
    super.key,
  });

  final AirQuality airQuality;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('کیفیت هوا')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  const Icon(Icons.air_rounded, size: 46),
                  const SizedBox(height: 12),
                  Text(
                    toPersianDigits(airQuality.usAqi),
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    airQuality.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Pollutant(
            title: 'PM2.5',
            value: airQuality.pm25,
            description: 'ذرات بسیار ریز معلق',
          ),
          _Pollutant(
            title: 'PM10',
            value: airQuality.pm10,
            description: 'ذرات معلق درشت‌تر',
          ),
          _Pollutant(
            title: 'NO₂',
            value: airQuality.nitrogenDioxide,
            description: 'دی‌اکسید نیتروژن',
          ),
          _Pollutant(
            title: 'O₃',
            value: airQuality.ozone,
            description: 'اوزون سطح زمین',
          ),
          _Pollutant(
            title: 'UV',
            value: airQuality.uvIndex,
            description: 'شاخص فرابنفش',
            unit: '',
          ),
        ],
      ),
    );
  }
}

class _Pollutant extends StatelessWidget {
  const _Pollutant({
    required this.title,
    required this.value,
    required this.description,
    this.unit = ' µg/m³',
  });

  final String title;
  final double value;
  final String description;
  final String unit;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: const Icon(Icons.blur_on_rounded),
          title: Text(title),
          subtitle: Text(description),
          trailing: Text(
            '${toPersianDigits(value.toStringAsFixed(1))}$unit',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      );
}
