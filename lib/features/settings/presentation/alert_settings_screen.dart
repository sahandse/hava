import 'package:flutter/material.dart';
import 'package:hava/core/services/alert_preferences.dart';

class AlertSettingsScreen extends StatefulWidget {
  const AlertSettingsScreen({super.key});

  @override
  State<AlertSettingsScreen> createState() => _AlertSettingsScreenState();
}

class _AlertSettingsScreenState extends State<AlertSettingsScreen> {
  bool _loading = true;
  bool rain = true;
  bool snow = true;
  bool wind = true;
  bool uv = true;
  bool aqi = true;
  double rainThreshold = 70;
  double windThreshold = 40;
  double uvThreshold = 8;
  double aqiThreshold = 100;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await AlertPreferences.load();
    if (!mounted) return;
    setState(() {
      rain = config.rainEnabled;
      snow = config.snowEnabled;
      wind = config.windEnabled;
      uv = config.uvEnabled;
      aqi = config.aqiEnabled;
      rainThreshold = config.rainThreshold.toDouble();
      windThreshold = config.windThreshold;
      uvThreshold = config.uvThreshold;
      aqiThreshold = config.aqiThreshold.toDouble();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیم هشدارها')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Switch(
                  icon: Icons.water_drop_outlined,
                  title: 'بارش',
                  value: rain,
                  onChanged: (value) {
                    setState(() => rain = value);
                    AlertPreferences.setBool('alert_rain_enabled', value);
                  },
                ),
                _Threshold(
                  label: 'آستانه احتمال بارش',
                  value: rainThreshold,
                  min: 30,
                  max: 100,
                  divisions: 14,
                  suffix: '٪',
                  onChanged: rain
                      ? (value) {
                          setState(() => rainThreshold = value);
                          AlertPreferences.setInt(
                            'alert_rain_threshold',
                            value.round(),
                          );
                        }
                      : null,
                ),
                const Divider(),
                _Switch(
                  icon: Icons.ac_unit_rounded,
                  title: 'برف',
                  value: snow,
                  onChanged: (value) {
                    setState(() => snow = value);
                    AlertPreferences.setBool('alert_snow_enabled', value);
                  },
                ),
                const Divider(),
                _Switch(
                  icon: Icons.air_rounded,
                  title: 'باد شدید',
                  value: wind,
                  onChanged: (value) {
                    setState(() => wind = value);
                    AlertPreferences.setBool('alert_wind_enabled', value);
                  },
                ),
                _Threshold(
                  label: 'آستانه سرعت باد',
                  value: windThreshold,
                  min: 20,
                  max: 100,
                  divisions: 16,
                  suffix: ' km/h',
                  onChanged: wind
                      ? (value) {
                          setState(() => windThreshold = value);
                          AlertPreferences.setDouble(
                            'alert_wind_threshold',
                            value,
                          );
                        }
                      : null,
                ),
                const Divider(),
                _Switch(
                  icon: Icons.wb_sunny_outlined,
                  title: 'UV بالا',
                  value: uv,
                  onChanged: (value) {
                    setState(() => uv = value);
                    AlertPreferences.setBool('alert_uv_enabled', value);
                  },
                ),
                _Threshold(
                  label: 'آستانه UV',
                  value: uvThreshold,
                  min: 3,
                  max: 12,
                  divisions: 9,
                  suffix: '',
                  onChanged: uv
                      ? (value) {
                          setState(() => uvThreshold = value);
                          AlertPreferences.setDouble(
                            'alert_uv_threshold',
                            value,
                          );
                        }
                      : null,
                ),
                const Divider(),
                _Switch(
                  icon: Icons.masks_outlined,
                  title: 'کیفیت هوای نامناسب',
                  value: aqi,
                  onChanged: (value) {
                    setState(() => aqi = value);
                    AlertPreferences.setBool('alert_aqi_enabled', value);
                  },
                ),
                _Threshold(
                  label: 'آستانه AQI',
                  value: aqiThreshold,
                  min: 50,
                  max: 250,
                  divisions: 20,
                  suffix: '',
                  onChanged: aqi
                      ? (value) {
                          setState(() => aqiThreshold = value);
                          AlertPreferences.setInt(
                            'alert_aqi_threshold',
                            value.round(),
                          );
                        }
                      : null,
                ),
              ],
            ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
        secondary: Icon(icon),
        title: Text(title),
        value: value,
        onChanged: onChanged,
      );
}

class _Threshold extends StatelessWidget {
  const _Threshold({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.suffix,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String suffix;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('$label: ${value.round()}$suffix'),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      );
}
