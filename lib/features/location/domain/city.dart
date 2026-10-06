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
