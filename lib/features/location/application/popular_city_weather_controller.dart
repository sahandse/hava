import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hava/features/location/domain/city.dart';
import 'package:hava/features/weather/data/open_meteo_weather_repository.dart';
import 'package:hava/features/weather/domain/weather_models.dart';

final popularCityWeatherProvider =
    FutureProvider.family<WeatherBundle, City>((ref, city) {
  return OpenMeteoWeatherRepository().fetch(
    latitude: city.latitude,
    longitude: city.longitude,
  );
});
