class AirQuality {
  const AirQuality({
    required this.usAqi,
    required this.pm25,
    required this.pm10,
    required this.nitrogenDioxide,
    required this.ozone,
    required this.uvIndex,
  });

  final int usAqi;
  final double pm25;
  final double pm10;
  final double nitrogenDioxide;
  final double ozone;
  final double uvIndex;

  String get label {
    if (usAqi <= 50) return 'پاک';
    if (usAqi <= 100) return 'قابل قبول';
    if (usAqi <= 150) return 'ناسالم برای گروه‌های حساس';
    if (usAqi <= 200) return 'ناسالم';
    if (usAqi <= 300) return 'بسیار ناسالم';
    return 'خطرناک';
  }
}
