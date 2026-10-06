import 'package:shared_preferences/shared_preferences.dart';

class AlertPreferences {
  const AlertPreferences({
    required this.rainEnabled,
    required this.snowEnabled,
    required this.windEnabled,
    required this.uvEnabled,
    required this.aqiEnabled,
    required this.rainThreshold,
    required this.windThreshold,
    required this.uvThreshold,
    required this.aqiThreshold,
  });

  final bool rainEnabled;
  final bool snowEnabled;
  final bool windEnabled;
  final bool uvEnabled;
  final bool aqiEnabled;
  final int rainThreshold;
  final double windThreshold;
  final double uvThreshold;
  final int aqiThreshold;

  static Future<AlertPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AlertPreferences(
      rainEnabled: prefs.getBool('alert_rain_enabled') ?? true,
      snowEnabled: prefs.getBool('alert_snow_enabled') ?? true,
      windEnabled: prefs.getBool('alert_wind_enabled') ?? true,
      uvEnabled: prefs.getBool('alert_uv_enabled') ?? true,
      aqiEnabled: prefs.getBool('alert_aqi_enabled') ?? true,
      rainThreshold: prefs.getInt('alert_rain_threshold') ?? 70,
      windThreshold: prefs.getDouble('alert_wind_threshold') ?? 40,
      uvThreshold: prefs.getDouble('alert_uv_threshold') ?? 8,
      aqiThreshold: prefs.getInt('alert_aqi_threshold') ?? 100,
    );
  }

  static Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  static Future<void> setDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }
}
