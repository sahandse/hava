import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hava/features/location/application/city_controller.dart';
import 'package:hava/features/location/domain/city.dart';

class CitySearchScreen extends ConsumerStatefulWidget {
  const CitySearchScreen({super.key});

  @override
  ConsumerState<CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends ConsumerState<CitySearchScreen> {
  final _controller = TextEditingController();
  Future<List<City>>? _search;

  void _run(String value) {
    setState(() {
      _search = value.trim().isEmpty
          ? null
          : ref.read(cityRepositoryProvider).search(value);
    });
  }

  void _select(City city) {
    ref.read(selectedCityProvider.notifier).select(city);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoriteCitiesProvider).value ?? const <City>[];

    return Scaffold(
      appBar: AppBar(title: const Text('شهرها')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            onChanged: _run,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'جستجوی شهر...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          if (favorites.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'شهرهای موردعلاقه',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ...favorites.map(
              (city) => ListTile(
                leading: const Icon(Icons.location_city_rounded),
                title: Text(city.name),
                subtitle: Text(city.subtitle),
                trailing: const Icon(Icons.star_rounded),
                onTap: () => _select(city),
                onLongPress: () =>
                    ref.read(favoriteCitiesProvider.notifier).toggle(city),
              ),
            ),
          ],
          if (_search == null) ...[
            const SizedBox(height: 24),
            const Text(
              'شهرهای محبوب',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ...popularCities.map((city) {
              final saved = favorites.any(
                (item) =>
                    item.latitude == city.latitude &&
                    item.longitude == city.longitude,
              );
              return ListTile(
                leading: const Icon(Icons.explore_outlined),
                title: Text(city.name),
                subtitle: Text(city.subtitle),
                trailing: IconButton(
                  icon: Icon(
                    saved ? Icons.star_rounded : Icons.star_border_rounded,
                  ),
                  onPressed: () =>
                      ref.read(favoriteCitiesProvider.notifier).toggle(city),
                ),
                onTap: () => _select(city),
              );
            }),
          ],
          const SizedBox(height: 16),
          if (_search != null)
            FutureBuilder<List<City>>(
              future: _search,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final items = snapshot.data ?? const <City>[];
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('شهری پیدا نشد')),
                  );
                }

                return Column(
                  children: items.map((city) {
                    final saved = favorites.any(
                      (item) =>
                          item.latitude == city.latitude &&
                          item.longitude == city.longitude,
                    );

                    return ListTile(
                      leading: const Icon(Icons.place_outlined),
                      title: Text(city.name),
                      subtitle: Text(city.subtitle),
                      trailing: IconButton(
                        icon: Icon(
                          saved ? Icons.star_rounded : Icons.star_border_rounded,
                        ),
                        onPressed: () => ref
                            .read(favoriteCitiesProvider.notifier)
                            .toggle(city),
                      ),
                      onTap: () => _select(city),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}
