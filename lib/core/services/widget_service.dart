import 'package:home_widget/home_widget.dart';
import 'package:hava/core/format/persian_digits.dart';
import 'package:hava/core/services/background_service.dart';
import 'package:hava/features/weather/domain/weather_models.dart';
import 'package:hava/features/weather/domain/weather_summary.dart';

class WidgetService {
  static Future<void> update({
    required String city,
    required WeatherBundle weather,
  }) async {
    final today = weather.daily.first;
    final summary = buildWeatherSummary(
      current: weather.current,
      today: today,
      hourly: weather.hourly,
    );

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
        toPersianDigits(today.maxTemperature.round()) + '°',
      ),
      HomeWidget.saveWidgetData<String>(
        'min_temp',
        toPersianDigits(today.minTemperature.round()) + '°',
      ),
      HomeWidget.saveWidgetData<String>(
        'rain',
        toPersianDigits(today.precipitationProbability) + '٪',
      ),
      HomeWidget.saveWidgetData<String>('summary', summary),
    ]);

    for (final provider in [
      'com.sahand.hava.HavaWidgetProvider',
      'com.sahand.hava.HavaMediumWidgetProvider',
      'com.sahand.hava.HavaLargeWidgetProvider',
    ]) {
      await HomeWidget.updateWidget(qualifiedAndroidName: provider);
    }
  }
}
