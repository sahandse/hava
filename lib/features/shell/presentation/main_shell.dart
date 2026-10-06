import 'package:flutter/material.dart';
import 'package:hava/features/location/presentation/city_search_screen.dart';
import 'package:hava/features/radar/presentation/radar_screen.dart';
import 'package:hava/features/settings/presentation/settings_screen.dart';
import 'package:hava/features/weather/presentation/weather_home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _pages = [
    WeatherHomeScreen(),
    CitySearchScreen(),
    RadarScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.cloud_outlined),
                selectedIcon: Icon(Icons.cloud_rounded),
                label: 'هوا',
              ),
              NavigationDestination(
                icon: Icon(Icons.location_city_outlined),
                selectedIcon: Icon(Icons.location_city_rounded),
                label: 'شهرها',
              ),
              NavigationDestination(
                icon: Icon(Icons.radar_outlined),
                selectedIcon: Icon(Icons.radar_rounded),
                label: 'نقشه',
              ),
              NavigationDestination(
                icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune_rounded),
                label: 'تنظیمات',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
