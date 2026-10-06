class MoonPhaseInfo {
  const MoonPhaseInfo({
    required this.fraction,
    required this.name,
    required this.symbol,
  });

  final double fraction;
  final String name;
  final String symbol;
}

MoonPhaseInfo moonPhaseFor(DateTime date) {
  final utc = DateTime.utc(date.year, date.month, date.day);
  final days = utc.difference(DateTime.utc(2000, 1, 6, 18, 14)).inMinutes /
      (24 * 60);
  const synodicMonth = 29.53058867;
  var phase = (days / synodicMonth) % 1;
  if (phase < 0) phase += 1;

  if (phase < 0.03 || phase >= 0.97) {
    return MoonPhaseInfo(fraction: phase, name: 'ماه نو', symbol: '🌑');
  }
  if (phase < 0.22) {
    return MoonPhaseInfo(fraction: phase, name: 'هلال افزایشی', symbol: '🌒');
  }
  if (phase < 0.28) {
    return MoonPhaseInfo(fraction: phase, name: 'تربیع اول', symbol: '🌓');
  }
  if (phase < 0.47) {
    return MoonPhaseInfo(fraction: phase, name: 'کوژ افزایشی', symbol: '🌔');
  }
  if (phase < 0.53) {
    return MoonPhaseInfo(fraction: phase, name: 'ماه کامل', symbol: '🌕');
  }
  if (phase < 0.72) {
    return MoonPhaseInfo(fraction: phase, name: 'کوژ کاهشی', symbol: '🌖');
  }
  if (phase < 0.78) {
    return MoonPhaseInfo(fraction: phase, name: 'تربیع آخر', symbol: '🌗');
  }
  return MoonPhaseInfo(fraction: phase, name: 'هلال کاهشی', symbol: '🌘');
}
