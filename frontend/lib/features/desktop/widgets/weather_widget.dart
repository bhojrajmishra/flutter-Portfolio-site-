import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/theme/app_theme.dart';

/// Floating "widget" card showing real live weather for the admin-configured
/// city. Decorative/non-critical — failures show a small unobtrusive message
/// rather than an error state.
class WeatherWidget extends ConsumerWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final weatherAsync = ref.watch(weatherProvider);

    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xCC12151F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: weatherAsync.when(
        loading: () => const SizedBox(
          height: 90,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (e, st) => const SizedBox(
          height: 90,
          child: Center(
            child: Text('Weather unavailable', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
        ),
        data: (weather) {
          final city = settingsAsync.value?.weatherCity ?? '';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(city,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${weather.temperatureC.round()}°',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w300, height: 1)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(weather.icon, size: 16, color: AppColors.accentEnd),
                  const SizedBox(width: 6),
                  Text(weather.label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
