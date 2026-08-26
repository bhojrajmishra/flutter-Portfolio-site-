import 'package:flutter/material.dart';

class Weather {
  final double temperatureC;
  final int weatherCode;
  final bool isDay;

  const Weather({
    required this.temperatureC,
    required this.weatherCode,
    required this.isDay,
  });

  factory Weather.fromOpenMeteoJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    return Weather(
      temperatureC: (current['temperature_2m'] as num).toDouble(),
      weatherCode: current['weather_code'] as int,
      isDay: (current['is_day'] as num) == 1,
    );
  }

  /// Human label + icon for [weatherCode], per the WMO code table Open-Meteo
  /// uses. Falls back to a generic cloud icon for any code not covered.
  String get label => _describe(weatherCode).$1;

  IconData get icon {
    final base = _describe(weatherCode).$2;
    // Swap the clear/partly-cloudy day icon for a moon at night.
    if (!isDay && weatherCode <= 1) return Icons.nightlight_round;
    return base;
  }

  static (String, IconData) _describe(int code) {
    if (code == 0) return ('Clear', Icons.wb_sunny_rounded);
    if (code <= 2) return ('Partly Cloudy', Icons.wb_cloudy_rounded);
    if (code == 3) return ('Overcast', Icons.cloud_rounded);
    if (code == 45 || code == 48) return ('Fog', Icons.foggy);
    if (code >= 51 && code <= 57) return ('Drizzle', Icons.grain_rounded);
    if (code >= 61 && code <= 67) return ('Rain', Icons.water_drop_rounded);
    if (code >= 71 && code <= 77) return ('Snow', Icons.ac_unit_rounded);
    if (code >= 80 && code <= 82) return ('Rain Showers', Icons.beach_access_rounded);
    if (code == 85 || code == 86) return ('Snow Showers', Icons.ac_unit_rounded);
    if (code >= 95) return ('Thunderstorm', Icons.thunderstorm_rounded);
    return ('Cloudy', Icons.cloud_rounded);
  }
}
