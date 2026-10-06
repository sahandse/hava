import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hava/features/air_quality/data/air_quality_repository.dart';
import 'package:hava/features/air_quality/domain/air_quality.dart';
import 'package:hava/features/weather/application/weather_controller.dart';

final airQualityRepositoryProvider =
    Provider<AirQualityRepository>((ref) => AirQualityRepository());

final airQualityProvider = FutureProvider<AirQuality>((ref) async {
  final weather = await ref.watch(weatherProvider.future);
  return ref.read(airQualityRepositoryProvider).fetch(
        latitude: weather.latitude,
        longitude: weather.longitude,
      );
});
