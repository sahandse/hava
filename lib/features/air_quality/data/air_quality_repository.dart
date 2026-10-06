import 'package:dio/dio.dart';
import 'package:hava/features/air_quality/domain/air_quality.dart';

class AirQualityRepository {
  AirQualityRepository([Dio? dio])
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://air-quality-api.open-meteo.com/v1',
              ),
            );

  final Dio _dio;

  Future<AirQuality> fetch({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/air-quality',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'current': 'us_aqi,pm2_5,pm10,uv_index',
        'timezone': 'auto',
      },
    );

    final current =
        response.data?['current'] as Map<String, dynamic>? ?? const {};
    return AirQuality(
      usAqi: (current['us_aqi'] as num?)?.toInt() ?? 0,
      pm25: (current['pm2_5'] as num?)?.toDouble() ?? 0,
      pm10: (current['pm10'] as num?)?.toDouble() ?? 0,
      uvIndex: (current['uv_index'] as num?)?.toDouble() ?? 0,
    );
  }
}
