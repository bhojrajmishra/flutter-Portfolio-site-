import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/data_providers.dart';
import '../../../../core/api/portfolio_repository.dart';
import '../../../../core/models/app_listing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../widgets/admin_helpers.dart';
import '../../widgets/admin_page.dart';
import '../../widgets/file_pick_helpers.dart';

final _uploadedFormat = DateFormat('MMM d, yyyy');

String _formatSize(int? bytes) {
  if (bytes == null || bytes <= 0) return '—';
  final mb = bytes / (1024 * 1024);
  return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)} MB';
}

/// Publishes/removes apps in the public "App Store" window. Every field
/// entered here (name, category, description, version) shows up verbatim
/// on the public listing — same real-content-only rule as the rest of the
/// admin panel.
class AppStoreAdminPage extends ConsumerWidget {
  const AppStoreAdminPage({super.key});

  Future<void> _openUploadForm(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final versionController = TextEditingController();
    String category = appCategories.first;
    PickedFileBytes? picked;
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Publish App'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'App name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        for (final c in appCategories) DropdownMenuItem(value: c, child: Text(c)),
                      ],
                      onChanged: (v) => setDialogState(() => category = v ?? category),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description (optional)'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: versionController,
                      decoration: const InputDecoration(labelText: 'Version label (optional, e.g. "1.2.0")'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final result = await pickFileBytes(
                              type: FileType.custom,
                              allowedExtensions: const ['apk'],
                            );
                            if (result != null) setDialogState(() => picked = result);
                          },
                          icon: const Icon(Icons.upload_file_outlined),
                          label: const Text('Choose .apk'),
                        ),
                        const SizedBox(width: 12),
                        if (picked != null)
                          Expanded(child: Text(picked!.name, overflow: TextOverflow.ellipsis, maxLines: 1)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (picked == null) {
                  showSnack(context, 'Choose an .apk file first.', isError: true);
                  return;
                }
                if (formKey.currentState!.validate()) Navigator.pop(context, true);
              },
              child: const Text('Publish'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || picked == null) return;

    // Large APKs on a slow/unstable connection can have the upload
    // connection drop mid-transfer (confirmed against production: identical
    // uploads succeed fine over a stable connection, so this is real-world
    // network flakiness, not a server bug) — retry a couple of times before
    // giving up, since a second attempt often just goes through.
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await ref.read(portfolioRepositoryProvider).createApp(
              picked!.bytes,
              picked!.name,
              name: nameController.text.trim(),
              category: category,
              description: descriptionController.text.trim(),
              versionLabel: versionController.text.trim(),
            );
        ref.invalidate(appsProvider);
        if (context.mounted) showSnack(context, 'App published.');
        return;
      } catch (e) {
        final isConnectionError =
            e is DioException && (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.unknown);
        if (isConnectionError && attempt < maxAttempts) {
          if (context.mounted) {
            showSnack(context, 'Upload interrupted, retrying ($attempt/$maxAttempts)...');
          }
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }
        if (context.mounted) showSnack(context, 'Upload failed: ${_describeUploadError(e)}', isError: true);
        return;
      }
    }
  }

  /// Dio reports a dropped connection (e.g. a large APK cut off mid-upload
  /// by a slow/unstable connection) the same way it reports an actual CORS
  /// block — a generic "connection error" — so the raw exception text is
  /// misleading here. Give the admin the likely real explanation instead.
  String _describeUploadError(Object e) {
    if (e is DioException &&
        (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.unknown)) {
      return 'the connection was interrupted while sending the file. This usually means '
          'the APK is large and the connection is slow or unstable — try again on a '
          'faster/more stable connection, or use a smaller APK.';
    }
    return '$e';
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, AppListing app) async {
    final confirmed = await confirmDelete(context, itemLabel: app.name);
    if (!confirmed) return;
    await ref.read(portfolioRepositoryProvider).deleteApp(app.id);
    ref.invalidate(appsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(appsProvider);

    return AdminPage(
      title: 'App Store',
      subtitle: 'Apps shown in the public "App Store" window\'s listing, newest first.',
      action: ElevatedButton.icon(
        onPressed: () => _openUploadForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Publish App'),
      ),
      child: appsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Text('Failed to load: $e'),
        data: (apps) {
          if (apps.isEmpty) {
            return const Text('No apps published yet.', style: TextStyle(color: AppColors.textSecondary));
          }
          return Column(
            children: apps
                .map((app) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(app.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.glassFill,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: AppColors.glassBorder),
                                        ),
                                        child: Text(app.category,
                                            style: const TextStyle(fontSize: 11, color: AppColors.accentEnd)),
                                      ),
                                    ],
                                  ),
                                  if (app.description != null && app.description!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(app.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: AppColors.textSecondary)),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(
                                    [
                                      if (app.versionLabel != null && app.versionLabel!.isNotEmpty)
                                        'v${app.versionLabel}',
                                      _formatSize(app.sizeBytes),
                                      _uploadedFormat.format(app.uploadedAt),
                                    ].join(' · '),
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                              onPressed: () => _delete(context, ref, app),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}
