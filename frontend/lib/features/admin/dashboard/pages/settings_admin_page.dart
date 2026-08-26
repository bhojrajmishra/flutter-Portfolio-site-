import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/data_providers.dart';
import '../../../../core/api/portfolio_repository.dart';
import '../../../../core/models/site_settings.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../widgets/admin_helpers.dart';
import '../../widgets/admin_page.dart';

class SettingsAdminPage extends ConsumerStatefulWidget {
  const SettingsAdminPage({super.key});

  @override
  ConsumerState<SettingsAdminPage> createState() => _SettingsAdminPageState();
}

class _SettingsAdminPageState extends ConsumerState<SettingsAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  bool _saving = false;
  bool _loadedOnce = false;

  void _populate(SiteSettings settings) {
    if (_loadedOnce) return;
    _loadedOnce = true;
    _cityController.text = settings.weatherCity;
    _latController.text = settings.weatherLat.toString();
    _lonController.text = settings.weatherLon.toString();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(portfolioRepositoryProvider).updateSettings(SiteSettings(
            weatherCity: _cityController.text.trim(),
            weatherLat: double.parse(_latController.text.trim()),
            weatherLon: double.parse(_lonController.text.trim()),
          ));
      ref.invalidate(settingsProvider);
      ref.invalidate(weatherProvider);
      if (mounted) showSnack(context, 'Settings saved.');
    } catch (e) {
      if (mounted) showSnack(context, 'Save failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return AdminPage(
      title: 'Settings',
      subtitle: 'Location used for the live weather widget on the desktop home page.',
      child: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Text('Failed to load: $e'),
        data: (settings) {
          _populate(settings);
          return GlassCard(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City (display label)'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            decoration: const InputDecoration(labelText: 'Latitude'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            validator: (v) {
                              final n = double.tryParse(v?.trim() ?? '');
                              if (n == null || n < -90 || n > 90) return 'Invalid latitude';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lonController,
                            decoration: const InputDecoration(labelText: 'Longitude'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            validator: (v) {
                              final n = double.tryParse(v?.trim() ?? '');
                              if (n == null || n < -180 || n > 180) return 'Invalid longitude';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tip: search "<your city> latitude longitude" to find these.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
