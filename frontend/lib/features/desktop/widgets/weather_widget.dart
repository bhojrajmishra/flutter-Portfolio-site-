import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loading_indicator.dart';

/// Floating "widget" card showing real live weather for the visitor's own
/// location (browser geolocation, not an admin-configured city).
/// Decorative/non-critical — a denied permission or lookup failure shows a
/// small unobtrusive message with a retry, rather than an error state.
class WeatherWidget extends ConsumerWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          child: Center(child: AppLoadingIndicator(size: 22, showLabel: false)),
        ),
        error: (e, st) {
          return SizedBox(
            height: 90,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_off_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(height: 6),
                  const Text(
                    'Enable location for local weather',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => ref.invalidate(weatherProvider),
                    child: const Text('Retry', style: TextStyle(color: AppColors.accentEnd, fontSize: 11)),
                  ),
                ],
              ),
            ),
          );
        },
        data: (weather) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(weather.cityName,
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
