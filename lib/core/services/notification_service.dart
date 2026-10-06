import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hava/core/services/background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('app_icon'),
      ),
    );
  }

  static Future<bool> setWeatherAlerts(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    if (enabled) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission() ?? true;
      if (!granted) return false;
      await prefs.setBool('weather_alerts', true);
      await BackgroundService.enablePeriodicUpdates();
      return true;
    }
    await prefs.setBool('weather_alerts', false);
    await BackgroundService.disablePeriodicUpdates();
    return true;
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('weather_alerts') ?? false;
  }
}
