import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hava/core/services/widget_service.dart';
import 'package:hava/features/location/application/city_controller.dart';
import 'package:hava/features/weather/data/open_meteo_weather_repository.dart';
import 'package:hava/features/weather/domain/weather_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

final weatherRepositoryProvider = Provider<OpenMeteoWeatherRepository>(
  (ref) => OpenMeteoWeatherRepository(),
);

final weatherProvider = FutureProvider<WeatherBundle>((ref) async {
  final city = ref.watch(selectedCityProvider);

  if (city != null) {
    final weather = await ref.read(weatherRepositoryProvider).fetch(
          latitude: city.latitude,
          longitude: city.longitude,
        );
    await _remember(city.name, weather);
    return weather;
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw StateError('دسترسی موقعیت مکانی فعال نیست.');
  }

  if (!await Geolocator.isLocationServiceEnabled()) {
    throw StateError('موقعیت مکانی دستگاه خاموش است.');
  }

  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,
    ),
  );

  final weather = await ref.read(weatherRepositoryProvider).fetch(
        latitude: position.latitude,
        longitude: position.longitude,
      );
  await _remember('موقعیت فعلی', weather);
  return weather;
});

Future<void> _remember(String cityName, WeatherBundle weather) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('last_lat', weather.latitude);
  await prefs.setDouble('last_lon', weather.longitude);
  await prefs.setString('last_city', cityName);
  await WidgetService.update(city: cityName, weather: weather);
}
