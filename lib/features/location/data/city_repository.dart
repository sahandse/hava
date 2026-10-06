import 'package:dio/dio.dart';
import 'package:hava/features/location/domain/city.dart';

class CityRepository {
  CityRepository([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(baseUrl: 'https://geocoding-api.open-meteo.com/v1'));

  final Dio _dio;

  Future<List<City>> search(String query) async {
    final normalized = query.trim();
    if (normalized.length < 2) return const [];

    final response = await _dio.get<Map<String, dynamic>>(
      '/search',
      queryParameters: {
        'name': normalized,
        'count': 20,
        'language': 'fa',
        'format': 'json',
      },
    );

    final results = response.data?['results'] as List<dynamic>? ?? const [];
    return results
        .map((item) => City.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
