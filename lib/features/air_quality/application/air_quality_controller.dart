import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hava/features/air_quality/data/air_quality_repository.dart';
import 'package:hava/features/air_quality/domain/air_quality.dart';
import 'package:hava/features/location/application/city_controller.dart';

final airQualityRepositoryProvider =
    Provider<AirQualityRepository>((ref) => AirQualityRepository());

final airQualityProvider = FutureProvider<AirQuality?>((ref) async {
  final city = ref.watch(selectedCityProvider);
  if (city == null) return null;
  return ref.read(airQualityRepositoryProvider).fetch(
        latitude: city.latitude,
        longitude: city.longitude,
      );
});
