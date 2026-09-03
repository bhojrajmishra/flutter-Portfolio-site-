import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/models/apk_file.dart';
import '../../../core/theme/app_theme.dart';
import '../window_manager.dart';

final _updatedFormat = DateFormat('MMM d, yyyy');

String _formatSize(int? bytes) {
  if (bytes == null || bytes <= 0) return '—';
  final mb = bytes / (1024 * 1024);
  return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)} MB';
}

/// The "App Store" window: a single-listing product page for this
/// project's own Android build, styled like a modern app store (icon,
/// GET button, stat strip, description) around the real file the admin
/// uploaded via the APK admin page — no invented ratings, download
/// counts, or screenshots, only facts the backend actually has.
class AppStoreWindowContent extends ConsumerWidget {
  const AppStoreWindowContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apkAsync = ref.watch(apkProvider);
    final hero = ref.watch(heroProvider).value;
    final notifier = ref.read(windowManagerProvider.notifier);

    return Column(
      children: [
        const _StoreTopBar(),
        Expanded(
          child: apkAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(
              child: Text('Failed to load: $e', style: const TextStyle(color: AppColors.textSecondary)),
            ),
            data: (apk) => apk == null
                ? const _EmptyStore()
                : _AppListing(
                    apk: apk,
                    developerName: hero?.name.isNotEmpty == true ? hero!.name : null,
                    onOpenAbout: () => notifier.openWindow('about', desktopSize: MediaQuery.sizeOf(context)),
                    onOpenProjects: () => notifier.openWindow('projects', desktopSize: MediaQuery.sizeOf(context)),
                  ),
          ),
        ),
      ],
    );
  }
}

class _StoreTopBar extends StatelessWidget {
  const _StoreTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
      ),
      child: const Row(
        children: [
          Icon(Icons.storefront_rounded, size: 16, color: AppColors.accentEnd),
          SizedBox(width: 8),
          Text('App Store', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EmptyStore extends StatelessWidget {
  const _EmptyStore();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 14),
            const Text('No apps published yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            const Text(
              'The Android app will appear here once it\'s uploaded from the admin panel.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppListing extends StatelessWidget {
  final ApkFile apk;
  final String? developerName;
  final VoidCallback onOpenAbout;
  final VoidCallback onOpenProjects;

  const _AppListing({
    required this.apk,
    required this.developerName,
    required this.onOpenAbout,
    required this.onOpenProjects,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFF3DDC84),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.android_rounded, color: Colors.white, size: 46),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Portfolio App', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                    if (developerName != null) ...[
                      const SizedBox(height: 3),
                      Text('by $developerName', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      children: [
                        const _Chip(label: 'Portfolio'),
                        if (apk.versionLabel != null && apk.versionLabel!.isNotEmpty)
                          _Chip(label: 'v${apk.versionLabel}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _GetButton(apk: apk),
          const SizedBox(height: 28),
          _StatsRow(apk: apk),
          const SizedBox(height: 28),
          const Divider(color: AppColors.glassBorder, height: 1),
          const SizedBox(height: 24),
          const Text(
            'ABOUT THIS APP',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.6),
          ),
          const SizedBox(height: 10),
          const Text(
            'The same portfolio, packaged as a native Android app — browse projects, '
            'experience, and get in touch, right from your phone. Built with Flutter, '
            'straight from this site\'s own codebase.',
            style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          const _RequirementNote(),
          const SizedBox(height: 20),
          _LinkRow(icon: Icons.person_outline_rounded, label: 'Meet the developer', onTap: onOpenAbout),
          _LinkRow(icon: Icons.work_outline_rounded, label: 'See more projects', onTap: onOpenProjects),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final ApkFile apk;
  const _StatsRow({required this.apk});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData('VERSION', apk.versionLabel?.isNotEmpty == true ? apk.versionLabel! : '1.0'),
      _StatData('SIZE', _formatSize(apk.sizeBytes)),
      _StatData('UPDATED', _updatedFormat.format(apk.uploadedAt)),
    ];
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i != 0)
            Container(width: 1, height: 32, color: AppColors.glassBorder, margin: const EdgeInsets.symmetric(horizontal: 4)),
          Expanded(
            child: Column(
              children: [
                Text(stats[i].value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(
                  stats[i].label,
                  style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary, letterSpacing: 0.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatData {
  final String label;
  final String value;
  const _StatData(this.label, this.value);
}

class _GetButton extends StatefulWidget {
  final ApkFile apk;
  const _GetButton({required this.apk});

  @override
  State<_GetButton> createState() => _GetButtonState();
}

class _GetButtonState extends State<_GetButton> {
  bool _justTapped = false;

  Future<void> _handleTap() async {
    await launchUrl(Uri.parse(widget.apk.url), webOnlyWindowName: '_blank');
    if (!mounted) return;
    setState(() => _justTapped = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _justTapped = false);
  }

  @override
  Widget build(BuildContext context) {
    final sizeLabel = _formatSize(widget.apk.sizeBytes);
    return Row(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _handleTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 11),
              decoration: BoxDecoration(
                gradient: _justTapped ? null : AppColors.accentGradient,
                color: _justTapped ? AppColors.glassFill : null,
                borderRadius: BorderRadius.circular(20),
                border: _justTapped ? Border.all(color: AppColors.glassBorder) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_justTapped) ...[
                    const Icon(Icons.check_rounded, size: 15, color: AppColors.accentEnd),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    _justTapped ? 'Downloading' : 'GET',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                      color: _justTapped ? AppColors.accentEnd : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('Direct download · $sizeLabel', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _RequirementNote extends StatelessWidget {
  const _RequirementNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 15, color: AppColors.accentEnd),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Not on the Play Store — this installs directly. Android may ask you to '
              'allow installs from this source the first time.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LinkRow({required this.icon, required this.label, required this.onTap});

  @override
  State<_LinkRow> createState() => _LinkRowState();
}

class _LinkRowState extends State<_LinkRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.glassFill : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: AppColors.textPrimary),
              const SizedBox(width: 10),
              Expanded(child: Text(widget.label, style: const TextStyle(fontSize: 13))),
              const Icon(Icons.chevron_right_rounded, size: 15, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
