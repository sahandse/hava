import 'package:home_widget/home_widget.dart';
import 'package:hava/core/format/persian_digits.dart';
import 'package:hava/core/services/background_service.dart';
import 'package:hava/features/weather/domain/weather_models.dart';

class WidgetService {
  static Future<void> update({
    required String city,
    required WeatherBundle weather,
  }) async {
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
  }
}
