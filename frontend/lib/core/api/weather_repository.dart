import 'package:dio/dio.dart';

import '../models/weather.dart';

/// Fetches current weather from Open-Meteo (https://open-meteo.com) — a free
/// weather API that needs no API key. Uses a plain Dio instance (no base
/// URL/auth interceptors from the app's API client) since this talks to a
/// third-party host, not our backend.
class WeatherRepository {
  final Dio _dio = Dio();

  Future<Weather> getCurrentWeather({required double lat, required double lon}) async {
    final res = await _dio.get('https://api.open-meteo.com/v1/forecast', queryParameters: {
      'latitude': lat,
      'longitude': lon,
      'current': 'temperature_2m,weather_code,is_day',
      'timezone': 'auto',
    });
    return Weather.fromOpenMeteoJson(res.data as Map<String, dynamic>);
  }
}
