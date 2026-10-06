import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hava/features/weather/domain/weather_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OpenMeteoWeatherRepository {
  OpenMeteoWeatherRepository([Dio? dio])
      : _dio = dio ?? Dio(BaseOptions(baseUrl: 'https://api.open-meteo.com/v1'));

  final Dio _dio;

  Future<WeatherBundle> fetch({
    required double latitude,
    required double longitude,
  }) async {
    final cacheKey = _cacheKey(latitude, longitude);

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/forecast',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'timezone': 'auto',
          'forecast_days': 10,
          'current': [
            'temperature_2m',
            'apparent_temperature',
            'relative_humidity_2m',
            'weather_code',
            'wind_speed_10m',
            'wind_direction_10m',
            'precipitation',
            'surface_pressure',
          ].join(','),
          'hourly': [
            'temperature_2m',
            'precipitation_probability',
            'weather_code',
            'visibility',
          ].join(','),
          'daily': [
            'weather_code',
            'temperature_2m_max',
            'temperature_2m_min',
            'precipitation_probability_max',
            'sunrise',
            'sunset',
          ].join(','),
        },
      );

      final data = response.data;
      if (data == null) {
        throw StateError('پاسخ هواشناسی خالی است.');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, jsonEncode(data));
      await prefs.setString(
        '${cacheKey}_saved_at',
        DateTime.now().toIso8601String(),
      );

      return _parse(data);
    } on DioException {
      final cached = await _readCache(cacheKey);
      if (cached != null) return _parse(cached);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _readCache(String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(cacheKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      await prefs.remove(cacheKey);
      await prefs.remove('${cacheKey}_saved_at');
      return null;
    }
  }

  String _cacheKey(double latitude, double longitude) {
    final lat = latitude.toStringAsFixed(3);
    final lon = longitude.toStringAsFixed(3);
    return 'weather_cache_${lat}_$lon';
  }

  WeatherBundle _parse(Map<String, dynamic> data) {
    final current = data['current'] as Map<String, dynamic>;
    final hourly = data['hourly'] as Map<String, dynamic>;
    final daily = data['daily'] as Map<String, dynamic>;

    return WeatherBundle(
      timezone: data['timezone'] as String? ?? 'auto',
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      current: CurrentWeather(
        temperature: (current['temperature_2m'] as num).toDouble(),
        apparentTemperature: (current['apparent_temperature'] as num).toDouble(),
        weatherCode: (current['weather_code'] as num).toInt(),
        humidity: (current['relative_humidity_2m'] as num).toInt(),
        windSpeed: (current['wind_speed_10m'] as num).toDouble(),
        windDirection: (current['wind_direction_10m'] as num).toInt(),
        precipitation: (current['precipitation'] as num).toDouble(),
        surfacePressure: (current['surface_pressure'] as num).toDouble(),
        updatedAt: DateTime.parse(current['time'] as String),
      ),
      hourly: _parseHourly(hourly),
      daily: _parseDaily(daily),
    );
  }

  List<HourlyWeather> _parseHourly(Map<String, dynamic> json) {
    final times = (json['time'] as List).cast<String>();
    final temperatures = (json['temperature_2m'] as List).cast<num>();
    final rain = (json['precipitation_probability'] as List).cast<num>();
    final codes = (json['weather_code'] as List).cast<num>();
    final visibility = (json['visibility'] as List).cast<num>();

    return List.generate(times.length, (index) {
      return HourlyWeather(
        time: DateTime.parse(times[index]),
        temperature: temperatures[index].toDouble(),
        precipitationProbability: rain[index].toInt(),
        weatherCode: codes[index].toInt(),
        visibility: visibility[index].toDouble(),
      );
    });
  }

  List<DailyWeather> _parseDaily(Map<String, dynamic> json) {
    final times = (json['time'] as List).cast<String>();
    final max = (json['temperature_2m_max'] as List).cast<num>();
    final min = (json['temperature_2m_min'] as List).cast<num>();
    final rain = (json['precipitation_probability_max'] as List).cast<num>();
    final codes = (json['weather_code'] as List).cast<num>();
    final sunrise = (json['sunrise'] as List).cast<String>();
    final sunset = (json['sunset'] as List).cast<String>();

    return List.generate(times.length, (index) {
      return DailyWeather(
        date: DateTime.parse(times[index]),
        maxTemperature: max[index].toDouble(),
        minTemperature: min[index].toDouble(),
        precipitationProbability: rain[index].toInt(),
        weatherCode: codes[index].toInt(),
        sunrise: DateTime.parse(sunrise[index]),
        sunset: DateTime.parse(sunset[index]),
      );
    });
  }
}
