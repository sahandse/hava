import 'package:hava/features/weather/domain/weather_models.dart';

String buildWeatherSummary({
  required CurrentWeather current,
  required DailyWeather today,
  required List<HourlyWeather> hourly,
}) {
  final nextHours = hourly.take(12).toList();
  final maxRain = nextHours.isEmpty
      ? 0
      : nextHours
          .map((hour) => hour.precipitationProbability)
          .reduce((a, b) => a > b ? a : b);

  final parts = <String>[];
  parts.add(_condition(current.weatherCode));

  if (today.maxTemperature - today.minTemperature >= 10) {
    parts.add('اختلاف دمای امروز محسوس است');
  } else if (current.temperature <= 10) {
    parts.add('هوای خنکی دارید');
  } else if (current.temperature >= 30) {
    parts.add('هوا گرم است');
  }

  if (maxRain >= 70) {
    final rainyHour = nextHours.firstWhere(
      (hour) => hour.precipitationProbability >= 70,
      orElse: () => nextHours.first,
    );
    parts.add('احتمال بارش از حوالی ساعت ${rainyHour.time.hour}');
  } else if (maxRain >= 40) {
    parts.add('احتمال بارش پراکنده وجود دارد');
  }

  if (today.maxWindSpeed >= 40) {
    parts.add('وزش باد قابل توجه است');
  }

  if (today.uvIndexMax >= 8) {
    parts.add('UV امروز بالاست');
  }

  return parts.join('؛ ');
}

String _condition(int code) {
  if (code == 0) return 'آسمان عمدتاً صاف است';
  if (code <= 3) return 'هوا نیمه‌ابری است';
  if (code <= 48) return 'مه یا کاهش دید دیده می‌شود';
  if (code <= 67) return 'شرایط بارانی است';
  if (code <= 77) return 'احتمال برف وجود دارد';
  if (code <= 82) return 'رگبار محتمل است';
  if (code <= 86) return 'بارش برف محتمل است';
  return 'احتمال رعدوبرق وجود دارد';
}
