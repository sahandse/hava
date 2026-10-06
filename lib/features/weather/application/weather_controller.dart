import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hava/features/weather/data/open_meteo_weather_repository.dart';
import 'package:hava/features/weather/domain/weather_models.dart';

final weatherRepositoryProvider = Provider<OpenMeteoWeatherRepository>(
  (ref) => OpenMeteoWeatherRepository(),
);

final weatherProvider = FutureProvider<WeatherBundle>((ref) async {
  var permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw StateError('دسترسی موقعیت مکانی فعال نیست.');
  }

  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw StateError('موقعیت مکانی دستگاه خاموش است.');
  }

  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,
    ),
  );

  return ref.read(weatherRepositoryProvider).fetch(
        latitude: position.latitude,
        longitude: position.longitude,
      );
});
