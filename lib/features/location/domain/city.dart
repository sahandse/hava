import 'dart:convert';

class City {
  const City({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.admin1,
  });

  final String name;
  final String country;
  final String? admin1;
  final double latitude;
  final double longitude;

  String get subtitle => [
        if (admin1 != null && admin1!.isNotEmpty) admin1!,
        country,
      ].join('، ');

  Map<String, dynamic> toJson() => {
        'name': name,
        'country': country,
        'admin1': admin1,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory City.fromJson(Map<String, dynamic> json) => City(
        name: json['name'] as String,
        country: json['country'] as String? ?? '',
        admin1: json['admin1'] as String?,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  String encode() => jsonEncode(toJson());

  factory City.decode(String value) =>
      City.fromJson(jsonDecode(value) as Map<String, dynamic>);
}

const popularCities = <City>[
  City(
    name: 'تهران',
    country: 'ایران',
    admin1: 'تهران',
    latitude: 35.6892,
    longitude: 51.3890,
  ),
  City(
    name: 'مشهد',
    country: 'ایران',
    admin1: 'خراسان رضوی',
    latitude: 36.2605,
    longitude: 59.6168,
  ),
  City(
    name: 'اصفهان',
    country: 'ایران',
    admin1: 'اصفهان',
    latitude: 32.6546,
    longitude: 51.6680,
  ),
  City(
    name: 'شیراز',
    country: 'ایران',
    admin1: 'فارس',
    latitude: 29.5918,
    longitude: 52.5837,
  ),
  City(
    name: 'تبریز',
    country: 'ایران',
    admin1: 'آذربایجان شرقی',
    latitude: 38.0800,
    longitude: 46.2919,
  ),
  City(
    name: 'رشت',
    country: 'ایران',
    admin1: 'گیلان',
    latitude: 37.2808,
    longitude: 49.5832,
  ),
];
