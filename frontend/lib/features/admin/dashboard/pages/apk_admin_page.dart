import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/data_providers.dart';
import '../../../../core/api/portfolio_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../widgets/admin_helpers.dart';
import '../../widgets/admin_page.dart';
import '../../widgets/file_pick_helpers.dart';

class ApkAdminPage extends ConsumerStatefulWidget {
  const ApkAdminPage({super.key});

  @override
  ConsumerState<ApkAdminPage> createState() => _ApkAdminPageState();
}

class _ApkAdminPageState extends ConsumerState<ApkAdminPage> {
  final _versionController = TextEditingController();
  bool _uploading = false;

  @override
  void dispose() {
    _versionController.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    final picked = await pickFileBytes(type: FileType.custom, allowedExtensions: const ['apk']);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      await ref.read(portfolioRepositoryProvider).uploadApk(
            picked.bytes,
            picked.name,
            versionLabel: _versionController.text.trim(),
          );
      ref.invalidate(apkProvider);
      _versionController.clear();
      if (mounted) showSnack(context, 'App uploaded.');
    } catch (e) {
      if (mounted) showSnack(context, 'Upload failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final apkAsync = ref.watch(apkProvider);

    return AdminPage(
      title: 'Android App (APK)',
      subtitle: 'The .apk visitors download from the "Download App" icon on the desktop.',
      child: GlassCard(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              apkAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Failed to load: $e'),
                data: (apk) => apk == null
                    ? const Text('No app uploaded yet.', style: TextStyle(color: AppColors.textSecondary))
                    : Row(
                        children: [
                          const Icon(Icons.android, color: Color(0xFF3DDC84)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(apk.filename, style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (apk.versionLabel != null && apk.versionLabel!.isNotEmpty)
                                  Text('Version ${apk.versionLabel}',
                                      style: const TextStyle(color: AppColors.accentEnd, fontSize: 12)),
                                Text(
                                  'Uploaded ${DateFormat('yyyy-MM-dd HH:mm').format(apk.uploadedAt)}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Open',
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () => launchUrl(Uri.parse(apk.url), webOnlyWindowName: '_blank'),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _versionController,
                decoration: const InputDecoration(labelText: 'Version label (optional, e.g. "1.2.0")'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Keep the APK modest in size — this hosting plan has a small total disk quota.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _uploading ? null : _upload,
                icon: _uploading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload_file_outlined),
                label: Text(_uploading ? 'Uploading...' : 'Upload New APK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
