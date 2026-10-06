class CurrentWeather {
  const CurrentWeather({
    required this.temperature,
    required this.apparentTemperature,
    required this.weatherCode,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.precipitation,
    required this.surfacePressure,
    required this.updatedAt,
  });

  final double temperature;
  final double apparentTemperature;
  final int weatherCode;
  final int humidity;
  final double windSpeed;
  final int windDirection;
  final double precipitation;
  final double surfacePressure;
  final DateTime updatedAt;
}

class HourlyWeather {
  const HourlyWeather({
    required this.time,
    required this.temperature,
    required this.precipitationProbability,
    required this.weatherCode,
    required this.visibility,
    required this.windSpeed,
    required this.uvIndex,
  });

  final DateTime time;
  final double temperature;
  final int precipitationProbability;
  final int weatherCode;
  final double visibility;
  final double windSpeed;
  final double uvIndex;
}

class DailyWeather {
  const DailyWeather({
    required this.date,
    required this.maxTemperature,
    required this.minTemperature,
    required this.precipitationProbability,
    required this.weatherCode,
    required this.sunrise,
    required this.sunset,
    required this.precipitationSum,
    required this.maxWindSpeed,
    required this.uvIndexMax,
    required this.daylightDuration,
  });

  final DateTime date;
  final double maxTemperature;
  final double minTemperature;
  final int precipitationProbability;
  final int weatherCode;
  final DateTime sunrise;
  final DateTime sunset;
  final double precipitationSum;
  final double maxWindSpeed;
  final double uvIndexMax;
  final double daylightDuration;
}

class WeatherBundle {
  const WeatherBundle({
    required this.current,
    required this.hourly,
    required this.daily,
    required this.timezone,
    required this.latitude,
    required this.longitude,
  });

  final CurrentWeather current;
  final List<HourlyWeather> hourly;
  final List<DailyWeather> daily;
  final String timezone;
  final double latitude;
  final double longitude;
}
