import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hava/core/format/persian_digits.dart';
import 'package:hava/core/services/alert_preferences.dart';
import 'package:hava/features/air_quality/data/air_quality_repository.dart';
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
      HomeWidget.saveWidgetData<String>(
        'max_temp',
        toPersianDigits(weather.daily.first.maxTemperature.round()) + '°',
      ),
      HomeWidget.saveWidgetData<String>(
        'min_temp',
        toPersianDigits(weather.daily.first.minTemperature.round()) + '°',
      ),
      HomeWidget.saveWidgetData<String>(
        'rain',
        toPersianDigits(weather.daily.first.precipitationProbability) + '٪',
      ),
    ]);

    for (final provider in [
      'com.sahand.hava.HavaWidgetProvider',
      'com.sahand.hava.HavaMediumWidgetProvider',
      'com.sahand.hava.HavaLargeWidgetProvider',
    ]) {
      await HomeWidget.updateWidget(qualifiedAndroidName: provider);
    }

    if (!(prefs.getBool('weather_alerts') ?? false)) return true;

    final config = await AlertPreferences.load();
    final upcoming = weather.hourly.take(6).toList();
    final messages = <String>[];

    final maxRain = upcoming.isEmpty
        ? 0
        : upcoming
            .map((hour) => hour.precipitationProbability)
            .reduce((a, b) => a > b ? a : b);
    if (config.rainEnabled && maxRain >= config.rainThreshold) {
      messages.add('احتمال بارش به $maxRain٪ رسیده');
    }

    final snow = upcoming.any(
      (hour) => hour.weatherCode >= 71 && hour.weatherCode <= 86,
    );
    if (config.snowEnabled && snow) {
      messages.add('احتمال بارش برف وجود دارد');
    }

    if (config.windEnabled &&
        weather.daily.first.maxWindSpeed >= config.windThreshold) {
      messages.add(
        'باد تا ${weather.daily.first.maxWindSpeed.round()} km/h می‌رسد',
      );
    }

    if (config.uvEnabled &&
        weather.daily.first.uvIndexMax >= config.uvThreshold) {
      messages.add(
        'شاخص UV تا ${weather.daily.first.uvIndexMax.toStringAsFixed(1)} می‌رسد',
      );
    }

    if (config.aqiEnabled) {
      try {
        final air = await AirQualityRepository().fetch(
          latitude: lat,
          longitude: lon,
        );
        if (air.usAqi >= config.aqiThreshold) {
          messages.add('AQI به ${air.usAqi} رسیده');
        }
      } catch (_) {
        // Weather alerts should still work if AQI is temporarily unavailable.
      }
    }

    if (messages.isNotEmpty) {
      await _notifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('app_icon'),
        ),
      );
      await _notifications.show(
        id: 1001,
        title: 'هشدار هوا برای $city',
        body: messages.join(' • '),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'weather_alerts',
            'هشدارهای هواشناسی',
            channelDescription: 'هشدار بارش، باد، UV و کیفیت هوا',
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
