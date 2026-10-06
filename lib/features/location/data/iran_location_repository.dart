import 'dart:convert';

import 'package:flutter/services.dart';

class IranProvince {
  const IranProvince({
    required this.id,
    required this.name,
    required this.counties,
  });

  final int id;
  final String name;
  final List<IranCounty> counties;

  factory IranProvince.fromJson(Map<String, dynamic> json) => IranProvince(
        id: json['id'] as int,
        name: json['name'] as String,
        counties: (json['counties'] as List<dynamic>)
            .map((item) => IranCounty.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class IranCounty {
  const IranCounty({
    required this.id,
    required this.name,
    required this.cities,
  });

  final int id;
  final String name;
  final List<IranCity> cities;

  factory IranCounty.fromJson(Map<String, dynamic> json) => IranCounty(
        id: json['id'] as int,
        name: json['name'] as String,
        cities: (json['cities'] as List<dynamic>)
            .map((item) => IranCity.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class IranCity {
  const IranCity({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory IranCity.fromJson(Map<String, dynamic> json) => IranCity(
        id: json['id'] as int,
        name: json['name'] as String,
      );
}

class IranLocationRepository {
  Future<List<IranProvince>> load() async {
    final raw = await rootBundle.loadString('assets/data/iran_locations.json');
    final root = jsonDecode(raw) as Map<String, dynamic>;
    return (root['provinces'] as List<dynamic>)
        .map((item) => IranProvince.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
