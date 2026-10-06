import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hava/features/location/data/city_repository.dart';
import 'package:hava/features/location/domain/city.dart';
import 'package:shared_preferences/shared_preferences.dart';

final cityRepositoryProvider = Provider<CityRepository>((ref) => CityRepository());

final favoriteCitiesProvider =
    AsyncNotifierProvider<FavoriteCitiesController, List<City>>(
  FavoriteCitiesController.new,
);

class FavoriteCitiesController extends AsyncNotifier<List<City>> {
  static const _key = 'favorite_cities';

  @override
  Future<List<City>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key)?.map(City.decode).toList() ?? const [];
  }

  Future<void> toggle(City city) async {
    final current = [...(state.value ?? const <City>[])];
    final index = current.indexWhere(
      (item) =>
          item.latitude == city.latitude && item.longitude == city.longitude,
    );

    if (index >= 0) {
      current.removeAt(index);
    } else {
      current.add(city);
    }

    state = AsyncData(current);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      current.map((item) => item.encode()).toList(),
    );
  }
}

final selectedCityProvider =
    NotifierProvider<SelectedCityController, City?>(
  SelectedCityController.new,
);

class SelectedCityController extends Notifier<City?> {
  static const selectedCityKey = 'selected_city';

  @override
  City? build() => null;

  Future<void> select(City? city) async {
    state = city;
    final prefs = await SharedPreferences.getInstance();
    if (city == null) {
      await prefs.remove(selectedCityKey);
    } else {
      await prefs.setString(selectedCityKey, city.encode());
      await prefs.setBool(CurrentLocationController.currentLocationKey, false);
    }
  }

  void restore(City city) {
    state = city;
  }
}

final currentLocationProvider =
    NotifierProvider<CurrentLocationController, bool>(
  CurrentLocationController.new,
);

class CurrentLocationController extends Notifier<bool> {
  static const currentLocationKey = 'current_location_selected';

  @override
  bool build() => false;

  Future<void> enable() async {
    state = true;
    await ref.read(selectedCityProvider.notifier).select(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(currentLocationKey, true);
    await prefs.remove(SelectedCityController.selectedCityKey);
  }

  Future<void> disable() async {
    state = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(currentLocationKey, false);
  }

  void restore(bool value) {
    state = value;
  }
}
