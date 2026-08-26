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

class ResumeAdminPage extends ConsumerStatefulWidget {
  const ResumeAdminPage({super.key});

  @override
  ConsumerState<ResumeAdminPage> createState() => _ResumeAdminPageState();
}

class _ResumeAdminPageState extends ConsumerState<ResumeAdminPage> {
  bool _uploading = false;

  Future<void> _upload() async {
    final picked = await pickFileBytes(type: FileType.custom, allowedExtensions: const ['pdf']);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      await ref.read(portfolioRepositoryProvider).uploadResume(picked.bytes, picked.name);
      ref.invalidate(resumeProvider);
      if (mounted) showSnack(context, 'Resume uploaded.');
    } catch (e) {
      if (mounted) showSnack(context, 'Upload failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resumeAsync = ref.watch(resumeProvider);

    return AdminPage(
      title: 'Resume',
      subtitle: 'The PDF visitors download from the hero section.',
      child: GlassCard(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              resumeAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Failed to load: $e'),
                data: (resume) => resume == null
                    ? const Text('No resume uploaded yet.', style: TextStyle(color: AppColors.textSecondary))
                    : Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_outlined, color: AppColors.accentEnd),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(resume.filename, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  'Uploaded ${DateFormat('yyyy-MM-dd HH:mm').format(resume.uploadedAt)}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Open',
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () => launchUrl(Uri.parse(resume.url), webOnlyWindowName: '_blank'),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _uploading ? null : _upload,
                icon: _uploading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload_file_outlined),
                label: Text(_uploading ? 'Uploading...' : 'Upload New Resume (PDF)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
