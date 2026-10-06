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

  Future<City> resolveIranLocation({
    required String name,
    required String provinceName,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/search',
      queryParameters: {
        'name': name,
        'count': 50,
        'language': 'fa',
        'format': 'json',
        'countryCode': 'IR',
      },
    );

    final results = response.data?['results'] as List<dynamic>? ?? const [];
    if (results.isEmpty) {
      throw StateError('مختصات این شهر پیدا نشد. دوباره تلاش کن.');
    }

    Map<String, dynamic>? best;
    for (final item in results) {
      final map = item as Map<String, dynamic>;
      final countryCode = (map['country_code'] as String?)?.toUpperCase();
      final admin1 = (map['admin1'] as String?) ?? '';
      if (countryCode == 'IR' && _normalize(admin1) == _normalize(provinceName)) {
        best = map;
        break;
      }
    }

    best ??= results
        .cast<Map<String, dynamic>>()
        .where((item) => (item['country_code'] as String?)?.toUpperCase() == 'IR')
        .cast<Map<String, dynamic>?>()
        .firstWhere((_) => true, orElse: () => null);

    best ??= results.first as Map<String, dynamic>;
    return City.fromJson(best);
  }

  String _normalize(String value) => value
      .replaceAll('ي', 'ی')
      .replaceAll('ك', 'ک')
      .replaceAll('‌', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
