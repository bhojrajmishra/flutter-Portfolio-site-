import 'package:dio/dio.dart';

import '../models/weather.dart';

/// Fetches current weather from Open-Meteo (https://open-meteo.com) — a free
/// weather API that needs no API key — for a given lat/lon, and resolves a
/// human-readable city name for the same coordinates via BigDataCloud's free,
/// keyless reverse-geocoding endpoint. Uses a plain Dio instance (no base
/// URL/auth interceptors from the app's API client) since both talk to
/// third-party hosts, not our backend.
class WeatherRepository {
  final Dio _dio = Dio();

  Future<Weather> getCurrentWeather({required double lat, required double lon}) async {
    final results = await Future.wait([
      _dio.get('https://api.open-meteo.com/v1/forecast', queryParameters: {
        'latitude': lat,
        'longitude': lon,
        'current': 'temperature_2m,weather_code,is_day',
        'timezone': 'auto',
      }),
      _reverseGeocode(lat, lon),
    ]);
    final weatherRes = results[0] as Response;
    final cityName = results[1] as String;
    return Weather.fromOpenMeteoJson(weatherRes.data as Map<String, dynamic>, cityName: cityName);
  }

  Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final res = await _dio.get('https://api.bigdatacloud.net/data/reverse-geocode-client', queryParameters: {
        'latitude': lat,
        'longitude': lon,
        'localityLanguage': 'en',
      });
      final data = res.data as Map<String, dynamic>;
      final city = (data['city'] as String?)?.trim();
      final locality = (data['locality'] as String?)?.trim();
      final principalSubdivision = (data['principalSubdivision'] as String?)?.trim();
      return (city != null && city.isNotEmpty)
          ? city
          : (locality != null && locality.isNotEmpty)
              ? locality
              : (principalSubdivision ?? 'Your location');
    } catch (_) {
      return 'Your location';
    }
  }
}
