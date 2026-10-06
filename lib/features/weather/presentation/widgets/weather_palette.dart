import 'package:flutter/material.dart';

class WeatherPalette {
  const WeatherPalette({
    required this.colors,
    required this.foreground,
    required this.accent,
    required this.isNight,
  });

  final List<Color> colors;
  final Color foreground;
  final Color accent;
  final bool isNight;

  static WeatherPalette resolve({
    required int weatherCode,
    required DateTime now,
    required DateTime sunrise,
    required DateTime sunset,
    required Brightness brightness,
  }) {
    final night = now.isBefore(sunrise) || now.isAfter(sunset);
    final dark = brightness == Brightness.dark;

    if (night) {
      return WeatherPalette(
        colors: dark
            ? const [Color(0xFF071225), Color(0xFF182A52), Color(0xFF3A2C73)]
            : const [Color(0xFF15284B), Color(0xFF314A83), Color(0xFF66549D)],
        foreground: Colors.white,
        accent: const Color(0xFFB8C8FF),
        isNight: true,
      );
    }

    if (weatherCode >= 95) {
      return WeatherPalette(
        colors: dark
            ? const [Color(0xFF171728), Color(0xFF332B4E), Color(0xFF55447A)]
            : const [Color(0xFF4C4E70), Color(0xFF716F9B), Color(0xFFA28DC4)],
        foreground: Colors.white,
        accent: const Color(0xFFFFD65A),
        isNight: false,
      );
    }

    if (weatherCode >= 71 && weatherCode <= 86) {
      return WeatherPalette(
        colors: dark
            ? const [Color(0xFF163044), Color(0xFF28516A), Color(0xFF4E7890)]
            : const [Color(0xFF8ED0ED), Color(0xFFB9E4F4), Color(0xFFEAF8FF)],
        foreground: dark ? Colors.white : const Color(0xFF183343),
        accent: const Color(0xFFD7F5FF),
        isNight: false,
      );
    }

    if (weatherCode >= 51 && weatherCode <= 82) {
      return WeatherPalette(
        colors: dark
            ? const [Color(0xFF10283C), Color(0xFF244E69), Color(0xFF3C7186)]
            : const [Color(0xFF3E7FA3), Color(0xFF68A8C4), Color(0xFFA9D5DF)],
        foreground: Colors.white,
        accent: const Color(0xFF7FDBFF),
        isNight: false,
      );
    }

    if (weatherCode >= 45 && weatherCode <= 48) {
      return WeatherPalette(
        colors: dark
            ? const [Color(0xFF29323D), Color(0xFF485563), Color(0xFF6B7784)]
            : const [Color(0xFF9AA8B4), Color(0xFFBDC7CE), Color(0xFFE1E7EA)],
        foreground: dark ? Colors.white : const Color(0xFF26333C),
        accent: const Color(0xFFD8E2E8),
        isNight: false,
      );
    }

    if (weatherCode >= 1 && weatherCode <= 3) {
      return WeatherPalette(
        colors: dark
            ? const [Color(0xFF17375A), Color(0xFF315E82), Color(0xFF6886A2)]
            : const [Color(0xFF60A5FA), Color(0xFF8FC8F8), Color(0xFFC8E7FF)],
        foreground: Colors.white,
        accent: const Color(0xFFF5FBFF),
        isNight: false,
      );
    }

    return WeatherPalette(
      colors: dark
          ? const [Color(0xFF123663), Color(0xFF1F6EA9), Color(0xFF2DA7D7)]
          : const [Color(0xFF42A5F5), Color(0xFF63C4F4), Color(0xFFFFD36E)],
      foreground: Colors.white,
      accent: const Color(0xFFFFE58A),
      isNight: false,
    );
  }
}
