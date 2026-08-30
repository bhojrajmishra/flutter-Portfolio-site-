import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/models/social_link.dart';

final _resumeMonthYear = DateFormat('yyyy');

String _resumeRange(DateTime start, DateTime? end) =>
    '${_resumeMonthYear.format(start)}-${end != null ? _resumeMonthYear.format(end) : 'present'}';

SocialLink? _findLink(List<SocialLink> links, String platform) {
  for (final l in links) {
    if (l.platform.toLowerCase() == platform) return l;
  }
  return null;
}

/// A real, in-app rendering of the resume/CV as a document — not a raw PDF
/// opened in a new tab. Reuses the same real content (hero/about/skills/
/// experience/social links) shown elsewhere on the site, laid out like a
/// printed page. The download/share buttons act on the actual uploaded
/// resume file, so "download" still gets you the real PDF if you want it.
class ResumeWindowContent extends ConsumerWidget {
  const ResumeWindowContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hero = ref.watch(heroProvider).value;
    final about = ref.watch(aboutProvider).value;
    final skills = ref.watch(skillsProvider).value ?? [];
    final experience = ref.watch(experienceProvider).value ?? [];
    final socialLinks = ref.watch(socialLinksProvider).value ?? [];
    final resume = ref.watch(resumeProvider).value;

    final name = hero?.name.isNotEmpty == true ? hero!.name : 'Portfolio';
    final title = hero?.title ?? '';
    final email = _findLink(socialLinks, 'email');
    final linkedin = _findLink(socialLinks, 'linkedin');
    final website = _findLink(socialLinks, 'website');

    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (title.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                title.toUpperCase(),
                                style: TextStyle(fontSize: 15, color: Colors.grey[600], letterSpacing: 1.2),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (resume != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 44),
                          child: QrImageView(
                            data: resume.url,
                            size: 88,
                            backgroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (about != null && about.bio.isNotEmpty) ...[
                    const _ResumeHeading('About Me'),
                    const SizedBox(height: 6),
                    Text(about.bio, style: const TextStyle(fontSize: 13.5, height: 1.5, color: Colors.black87)),
                    const SizedBox(height: 24),
                  ],
                  if (email != null || linkedin != null || website != null || skills.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (email != null || linkedin != null || website != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _ResumeHeading('Contact'),
                                const SizedBox(height: 8),
                                if (email != null) _ResumeContactRow('Email', email.url.replaceFirst('mailto:', '')),
                                if (website != null) _ResumeContactRow('Portfolio', website.url),
                                if (linkedin != null) _ResumeContactRow('LinkedIn', linkedin.url),
                              ],
                            ),
                          ),
                        if ((email != null || linkedin != null || website != null) && skills.isNotEmpty)
                          const SizedBox(width: 32),
                        if (skills.isNotEmpty)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _ResumeHeading('Skills'),
                                const SizedBox(height: 8),
                                for (final s in skills.take(10))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('•  ', style: TextStyle(fontSize: 13, color: Colors.black87)),
                                        Expanded(
                                          child: Text(s.name, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  if (experience.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _ResumeHeading('Experience'),
                    const SizedBox(height: 10),
                    for (final e in experience) ...[
                      Text(e.role, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.black)),
                      const SizedBox(height: 2),
                      Text(
                        '${e.company} | ${_resumeRange(e.startDate, e.endDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (e.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(e.description, style: const TextStyle(fontSize: 12.5, height: 1.45, color: Colors.black87)),
                      ],
                      const SizedBox(height: 14),
                    ],
                  ],
                  if (resume == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Text(
                        'No resume file uploaded yet — add one from the admin panel.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (resume != null)
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ResumeToolbarButton(
                    icon: Icons.file_download_outlined,
                    tooltip: 'Download PDF',
                    onTap: () => launchUrl(Uri.parse(resume.url), webOnlyWindowName: '_blank'),
                  ),
                  _ResumeToolbarButton(
                    icon: Icons.ios_share_rounded,
                    tooltip: 'Copy link',
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: resume.url));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Resume link copied to clipboard'), duration: Duration(seconds: 2)),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ResumeHeading extends StatelessWidget {
  final String text;
  const _ResumeHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black, letterSpacing: 0.5),
    );
  }
}

class _ResumeContactRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResumeContactRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12.5, color: Colors.black87),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: value, style: const TextStyle(color: Color(0xFF1A56DB))),
          ],
        ),
      ),
    );
  }
}

class _ResumeToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _ResumeToolbarButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 17, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
