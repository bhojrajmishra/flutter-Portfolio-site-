class SiteSettings {
  final String weatherCity;
  final double weatherLat;
  final double weatherLon;

  const SiteSettings({
    required this.weatherCity,
    required this.weatherLat,
    required this.weatherLon,
  });

  factory SiteSettings.fromJson(Map<String, dynamic> json) => SiteSettings(
        weatherCity: json['weatherCity'] as String? ?? 'Dharan',
        weatherLat: (json['weatherLat'] as num?)?.toDouble() ?? 26.8121,
        weatherLon: (json['weatherLon'] as num?)?.toDouble() ?? 87.283902,
      );

  Map<String, dynamic> toJson() => {
        'weatherCity': weatherCity,
        'weatherLat': weatherLat,
        'weatherLon': weatherLon,
      };
}
