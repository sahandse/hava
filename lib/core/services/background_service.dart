import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hava/core/format/persian_digits.dart';
import 'package:hava/features/weather/data/open_meteo_weather_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const _taskName = 'hava.weather.refresh';
const _taskUniqueName = 'hava-periodic-weather-refresh';
final _notifications = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != _taskName) return true;
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('last_lat');
    final lon = prefs.getDouble('last_lon');
    if (lat == null || lon == null) return true;

    final weather = await OpenMeteoWeatherRepository().fetch(
      latitude: lat,
      longitude: lon,
    );
    final city = prefs.getString('last_city') ?? 'موقعیت فعلی';

    await Future.wait([
      HomeWidget.saveWidgetData<String>('city', city),
      HomeWidget.saveWidgetData<String>(
        'temperature',
        toPersianDigits(weather.current.temperature.round()) + '°',
      ),
      HomeWidget.saveWidgetData<String>(
        'condition',
        weatherLabel(weather.current.weatherCode),
      ),
    ]);
    await HomeWidget.updateWidget(
      qualifiedAndroidName: 'com.sahand.hava.HavaWidgetProvider',
    );

    final likelyRain = weather.hourly.take(4).any(
          (hour) => hour.precipitationProbability >= 70,
        );
    if (likelyRain && (prefs.getBool('weather_alerts') ?? false)) {
      await _notifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('app_icon'),
        ),
      );
      await _notifications.show(
        id: 1001,
        title: 'احتمال بارش',
        body: 'در چند ساعت آینده احتمال بارش بالاست.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'weather_alerts',
            'هشدارهای هواشناسی',
            channelDescription: 'هشدار بارش و تغییرات مهم هوا',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
    return true;
  });
}

class BackgroundService {
  static Future<void> initialize() =>
      Workmanager().initialize(backgroundCallbackDispatcher);

  static Future<void> enablePeriodicUpdates() =>
      Workmanager().registerPeriodicTask(
        _taskUniqueName,
        _taskName,
        frequency: const Duration(hours: 1),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );

  static Future<void> disablePeriodicUpdates() =>
      Workmanager().cancelByUniqueName(_taskUniqueName);
}

String weatherLabel(int code) {
  if (code == 0) return 'صاف';
  if (code <= 3) return 'نیمه‌ابری';
  if (code <= 48) return 'مه‌آلود';
  if (code <= 67) return 'بارانی';
  if (code <= 77) return 'برفی';
  if (code <= 82) return 'رگبار';
  if (code <= 86) return 'برف';
  return 'رعدوبرق';
}
