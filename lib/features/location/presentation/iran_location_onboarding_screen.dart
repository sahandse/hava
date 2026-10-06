import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hava/features/location/application/city_controller.dart';
import 'package:hava/features/location/data/city_repository.dart';
import 'package:hava/features/location/data/iran_location_repository.dart';

class IranLocationOnboardingScreen extends ConsumerStatefulWidget {
  const IranLocationOnboardingScreen({
    required this.onSelectionCompleted,
    super.key,
  });

  final VoidCallback onSelectionCompleted;

  @override
  ConsumerState<IranLocationOnboardingScreen> createState() =>
      _IranLocationOnboardingScreenState();
}

class _IranLocationOnboardingScreenState
    extends ConsumerState<IranLocationOnboardingScreen> {
  final _repository = IranLocationRepository();
  final _searchController = TextEditingController();

  List<IranProvince>? _provinces;
  IranProvince? _province;
  IranCounty? _county;
  String _query = '';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository.load().then((value) {
      if (!mounted) return;
      value.sort((a, b) => a.name.compareTo(b.name));
      setState(() => _provinces = value);
    }).catchError((Object error) {
      if (!mounted) return;
      setState(() => _error = 'داده شهرها بارگذاری نشد.');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectCity(IranCity city) async {
    final province = _province;
    if (province == null || _saving) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final resolved = await ref.read(cityRepositoryProvider).resolveIranLocation(
            name: city.name,
            provinceName: province.name,
          );
      await ref.read(currentLocationProvider.notifier).disable();
      await ref.read(selectedCityProvider.notifier).select(resolved);
      if (!mounted) return;
      widget.onSelectionCompleted();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'اتصال اینترنت یا مختصات شهر را بررسی کن و دوباره بزن.';
      });
    }
  }

  void _selectProvince(IranProvince province) {
    HapticFeedback.selectionClick();
    setState(() {
      _province = province;
      _county = null;
      _query = '';
      _searchController.clear();
      _error = null;
    });
  }

  void _backToProvinces() {
    setState(() {
      _province = null;
      _county = null;
      _query = '';
      _searchController.clear();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provinces = _provinces;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              provinceName: _province?.name,
              onBack: _province == null ? null : _backToProvinces,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(.08, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _province == null
                    ? _ProvinceStep(
                        key: const ValueKey('provinces'),
                        provinces: provinces,
                        error: _error,
                        onSelect: _selectProvince,
                      )
                    : _CityStep(
                        key: ValueKey('cities-${_province!.id}'),
                        province: _province!,
                        selectedCounty: _county,
                        query: _query,
                        searchController: _searchController,
                        saving: _saving,
                        error: _error,
                        onCountyChanged: (county) {
                          HapticFeedback.selectionClick();
                          setState(() => _county = county);
                        },
                        onQueryChanged: (value) =>
                            setState(() => _query = value.trim()),
                        onSelectCity: _selectCity,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.provinceName,
    required this.onBack,
  });

  final String? provinceName;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Column(
        children: [
          Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: .88, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) => Transform.scale(
                    scale: value,
                    child: child,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/branding/hava_logo.png',
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'هوا',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text('آب‌وهوای شهر خودت'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (onBack != null) const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('🇮🇷', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                const Text(
                  'ایران',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                if (provinceName != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.chevron_left_rounded, size: 18),
                  ),
                  Expanded(
                    child: Text(
                      provinceName!,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ] else
                  const Spacer(),
                const Icon(Icons.check_circle_rounded, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProvinceStep extends StatelessWidget {
  const _ProvinceStep({
    required this.provinces,
    required this.error,
    required this.onSelect,
    super.key,
  });

  final List<IranProvince>? provinces;
  final String? error;
  final ValueChanged<IranProvince> onSelect;

  @override
  Widget build(BuildContext context) {
    if (provinces == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
      children: [
        Text(
          'استانت را انتخاب کن',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 5),
        Text(
          '۳۱ استان ایران داخل برنامه ذخیره شده و این مرحله بدون اینترنت کار می‌کند.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provinces!.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.15,
          ),
          itemBuilder: (context, index) {
            final province = provinces![index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: .92, end: 1),
              duration: Duration(milliseconds: 220 + (index % 8) * 35),
              curve: Curves.easeOutBack,
              builder: (context, value, child) => Transform.scale(
                scale: value,
                child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
              ),
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => onSelect(province),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        province.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CityStep extends StatelessWidget {
  const _CityStep({
    required this.province,
    required this.selectedCounty,
    required this.query,
    required this.searchController,
    required this.saving,
    required this.error,
    required this.onCountyChanged,
    required this.onQueryChanged,
    required this.onSelectCity,
    super.key,
  });

  final IranProvince province;
  final IranCounty? selectedCounty;
  final String query;
  final TextEditingController searchController;
  final bool saving;
  final String? error;
  final ValueChanged<IranCounty?> onCountyChanged;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<IranCity> onSelectCity;

  @override
  Widget build(BuildContext context) {
    final normalized = query
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll('‌', ' ')
        .trim();

    final counties = selectedCounty == null
        ? province.counties
        : <IranCounty>[selectedCounty!];

    final rows = <({IranCounty county, IranCity city})>[];
    for (final county in counties) {
      for (final city in county.cities) {
        final cityName = city.name.replaceAll('ي', 'ی').replaceAll('ك', 'ک');
        final countyName =
            county.name.replaceAll('ي', 'ی').replaceAll('ك', 'ک');
        if (normalized.isEmpty ||
            cityName.contains(normalized) ||
            countyName.contains(normalized)) {
          rows.add((county: county, city: city));
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        Text(
          'شهر یا شهرستان',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 5),
        Text('استان ${province.name} • ابتدا شهرستان را فیلتر کن یا مستقیم شهر را جستجو کن.'),
        const SizedBox(height: 16),
        TextField(
          controller: searchController,
          onChanged: onQueryChanged,
          decoration: const InputDecoration(
            hintText: 'جستجوی شهر یا شهرستان...',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ChoiceChip(
                label: const Text('همه'),
                selected: selectedCounty == null,
                onSelected: (_) => onCountyChanged(null),
              ),
              const SizedBox(width: 7),
              ...province.counties.map(
                (county) => Padding(
                  padding: const EdgeInsets.only(left: 7),
                  child: ChoiceChip(
                    label: Text(county.name),
                    selected: selectedCounty?.id == county.id,
                    onSelected: (_) => onCountyChanged(county),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        if (saving)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('موردی پیدا نشد')),
          )
        else
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  leading: const CircleAvatar(
                    child: Icon(Icons.location_city_rounded),
                  ),
                  title: Text(
                    row.city.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('شهرستان ${row.county.name}'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => onSelectCity(row.city),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
