import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hava/core/widgets/soft_reveal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hava/features/location/application/city_controller.dart';
import 'package:hava/features/location/application/popular_city_weather_controller.dart';
import 'package:hava/core/format/persian_digits.dart';
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
    HapticFeedback.selectionClick();
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
            const SizedBox(height: 12),
            SizedBox(
              height: 164,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: popularCities.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final city = popularCities[index];
                  final weather = ref.watch(popularCityWeatherProvider(city));
                  final saved = favorites.any(
                    (item) =>
                        item.latitude == city.latitude &&
                        item.longitude == city.longitude,
                  );

                  return SoftReveal(
                    child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => _select(city),
                    child: Container(
                      width: 150,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            Theme.of(context).colorScheme.primaryContainer,
                            Theme.of(context).colorScheme.tertiaryContainer,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  city.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  saved
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 19,
                                ),
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  ref
                                      .read(favoriteCitiesProvider.notifier)
                                      .toggle(city);
                                },
                              ),
                            ],
                          ),
                          const Spacer(),
                          weather.when(
                            loading: () => const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            error: (_, __) => const Text('—'),
                            data: (data) => Text(
                              '${toPersianDigits(data.current.temperature.round())}°',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            city.admin1 ?? city.country,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    ),
                  );
                },
              ),
            ),
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
