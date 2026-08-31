import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/data_providers.dart';

// Mirrors the currently uploaded resume PDF
// ("Bhoj_Raj_Mishra_CV_Remote.pdf") verbatim — phone number, per-category
// skill groupings, per-bullet experience/project detail, and education
// location have no field in the admin schema, so this is transcribed by
// hand rather than pulled from the CMS. If a new resume with different
// content is uploaded from the admin panel, update these constants to
// match it; the file itself (QR code, download, share) always tracks
// whatever PDF is currently uploaded via [resumeProvider].
const _name = 'Bhoj Raj Mishra';
const _tagline = 'Full-Stack Developer | Flutter & Web | Remote';
const _location = 'Kathmandu, Nepal (UTC+5:45)';
const _availability = 'Open to Remote Worldwide & Relocation';
const _email = 'bhojrajmishra4@gmail.com';
const _phone = '+977 9848420005';
const _portfolio = 'bhojrajmishra.com.np';
const _linkedin = 'linkedin.com/in/bhoj-raj-mishra-11b850203';
const _github = 'github.com/bhojrajmishra';

const _summary =
    'Full-Stack Developer with 2+ years of experience delivering production mobile and web applications for '
    'international clients, working fully remote and asynchronously across time zones. Independently scoped, '
    'built, shipped, and now maintain a live e-commerce platform for an Australian client using Next.js, Node.js, '
    'and MySQL, self-hosted on DigitalOcean with Docker, Caddy, and GitHub Actions CI/CD. Strong in Flutter and '
    'Dart with Provider state management, Stacked Architecture, and REST integration via Dio and Retrofit. Fluent '
    'written and spoken English. Comfortable owning delivery end to end with minimal supervision. Open to remote '
    'roles worldwide and to relocation with visa sponsorship.';

class _SkillGroup {
  final String category;
  final String items;
  const _SkillGroup(this.category, this.items);
}

const _skillGroups = [
  _SkillGroup(
    'Mobile Development',
    'Flutter, Dart, Provider, Stacked Architecture, Clean Architecture, Firebase Authentication, Firestore, Dio, '
        'Retrofit, WebSocket, Platform Channels, Responsive UI, Android, iOS',
  ),
  _SkillGroup(
    'Web Development',
    'JavaScript, Next.js, React, Node.js, Express, EJS, HTML, CSS, RESTful APIs, JSON, Server-Side Rendering',
  ),
  _SkillGroup('Databases', 'MySQL, SQL, Firestore, Sequelize ORM'),
  _SkillGroup(
    'DevOps & Cloud',
    'Docker, DigitalOcean, Linux Server Administration, Caddy, TLS/SSL, DNS Configuration, GitHub Actions, CI/CD',
  ),
  _SkillGroup('Other Tools', 'Kotlin, Java, Spring Boot, Git, GitHub, Android Studio, VS Code, IntelliJ, Postman'),
  _SkillGroup(
    'Practices',
    'Remote & Asynchronous Collaboration, Agile, Code Review, Unit & Widget Testing, Performance Optimization, '
        'Object-Oriented Programming, Data Structures & Algorithms',
  ),
];

class _ResumeExperience {
  final String role;
  final String org;
  final String dateRange;
  final String location;
  final List<String> bullets;
  const _ResumeExperience({
    required this.role,
    required this.org,
    required this.dateRange,
    required this.location,
    required this.bullets,
  });
}

const _experience = [
  _ResumeExperience(
    role: 'Freelance Full-Stack Developer (Remote)',
    org: 'Self-Employed — Client based in Australia',
    dateRange: 'November 2024 – Present',
    location: 'Remote, async',
    bullets: [
      'Designed, developed, and deployed defconpeptides.com.au, a production e-commerce platform for an '
          'Australian retailer using Next.js, Node.js, and MySQL, currently live and serving customers.',
      'Implemented the full storefront: product catalogue with size and price variants, stock status, cart, '
          'bank-transfer checkout, and browsing across seven categories.',
      'Built an admin dashboard enabling the client to independently manage inventory, orders, products, customer '
          'feedback, and blog content.',
      'Provisioned the full production environment on a DigitalOcean droplet: Docker containerisation, DNS, and '
          'Caddy reverse proxy with automatic TLS; also self-host bhojrajmishra.com.np on the same server.',
      'Automated build and deployment pipelines using GitHub Actions CI/CD, eliminating manual server access for '
          'releases.',
      'Achieved Google Lighthouse scores of 100 Best Practices, 100 SEO, 96 Accessibility, and 92 Performance on '
          'desktop through server-side rendering, semantic HTML, and WCAG-compliant contrast.',
      'Worked fully remote and asynchronously with a client 5 hours ahead, handling scoping, delivery, and '
          'ongoing support in English without on-site supervision.',
    ],
  ),
  _ResumeExperience(
    role: 'Mobile App Development Intern',
    org: 'Awecode Solution Pvt. Ltd. (Internship Letter)',
    dateRange: 'August – November 2024',
    location: 'Kathmandu, Nepal',
    bullets: [
      'Developed and maintained cross-platform Flutter and Dart mobile applications for Android, implementing '
          'responsive UI layouts and integrating RESTful APIs using Dio and Retrofit with Futures and Streams.',
      'Applied Provider state management following Stacked Architecture patterns, building reusable Flutter '
          'widgets and a shared UI kit for interface consistency.',
      'Collaborated with cross-functional teams to ship features, participating in code reviews to uphold coding '
          'standards.',
    ],
  ),
];

class _ResumeProject {
  final String title;
  final String tech;
  final List<String> bullets;
  const _ResumeProject({required this.title, required this.tech, required this.bullets});
}

const _projects = [
  _ResumeProject(
    title: 'Barber Appointment App',
    tech: 'Flutter, Dart, Provider, Spring Boot, MySQL, WebSocket',
    bullets: [
      'Cross-platform salon booking app with customer and barber interfaces, real-time booking over WebSocket, '
          'and GPS nearest-barber recommendations.',
    ],
  ),
  _ResumeProject(
    title: 'AudioTool App',
    tech: 'Flutter, Dart, Stacked Architecture, JustAudio, FFmpeg',
    bullets: [
      'Audio app supporting recording, playlists, trimming, and insertion using JustAudio and the ffmpeg kit '
          'Flutter package.',
      'Integrated waveform visualisation for timestamp selection, structured on Stacked Architecture with a '
          'reusable UI kit.',
    ],
  ),
  _ResumeProject(
    title: 'BookStore E-Commerce Application',
    tech: 'Flutter, Dart, Provider, Firebase, Dio, Retrofit',
    bullets: [
      'Mobile storefront with Firebase Authentication, dynamic listings, cart, and secure checkout, using Dio '
          'interceptors for automated JWT management.',
    ],
  ),
  _ResumeProject(
    title: 'LiveChat System',
    tech: 'Flutter, Dart, Firebase Authentication, Firestore',
    bullets: [
      'Real-time messaging with instant delivery via Firestore streams, reactive auth state, and timestamped '
          'history.',
    ],
  ),
  _ResumeProject(
    title: 'Content Management System',
    tech: 'Node.js, Express, MySQL, Sequelize, EJS, Passport.js',
    bullets: [
      'Full CRUD publishing system with Passport.js auth, Multer uploads, EJS server-side rendering, and '
          'Sequelize over MySQL.',
    ],
  ),
];

const _educationSchool = 'Nepal College of Information Technology, Pokhara University';
const _educationDegree = 'Bachelor of Engineering (BE) in Software Engineering';
const _educationRange = '2019 – 2024';
const _educationLocation = 'Lalitpur, Nepal';

/// A real, in-app rendering of the resume/CV as a document — not a raw PDF
/// opened in a new tab. Content is transcribed verbatim from the actual
/// uploaded resume PDF (see the constants above); the download/share
/// toolbar and QR code act on whatever PDF file is currently uploaded via
/// [resumeProvider].
class ResumeWindowContent extends ConsumerWidget {
  const ResumeWindowContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resume = ref.watch(resumeProvider).value;

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
                            const Text(
                              _name,
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(_tagline, style: TextStyle(fontSize: 15, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                      if (resume != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 8),
                          child: QrImageView(data: resume.url, size: 88, backgroundColor: Colors.white),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _ResumeHeading('Summary'),
                  const SizedBox(height: 6),
                  const Text(_summary, style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _ResumeHeading('Contact'),
                            SizedBox(height: 8),
                            _ResumeContactRow('Location', '$_location — $_availability'),
                            _ResumeContactRow('Phone', _phone),
                            _ResumeContactRow('Email', _email),
                            _ResumeContactRow('Portfolio', _portfolio),
                            _ResumeContactRow('LinkedIn', _linkedin),
                            _ResumeContactRow('GitHub', _github),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _ResumeHeading('Skills'),
                            const SizedBox(height: 8),
                            for (final g in _skillGroups)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 12, height: 1.45, color: Colors.black87),
                                    children: [
                                      TextSpan(
                                        text: '${g.category}: ',
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      TextSpan(text: g.items),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _ResumeHeading('Experience'),
                  const SizedBox(height: 10),
                  for (final e in _experience) ...[
                    _ResumeEntryHeader(title: e.role, org: e.org, dateRange: e.dateRange, location: e.location),
                    const SizedBox(height: 4),
                    for (final b in e.bullets) _ResumeBullet(b),
                    const SizedBox(height: 14),
                  ],
                  const _ResumeHeading('Projects'),
                  const SizedBox(height: 10),
                  for (final p in _projects) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            p.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          p.tech,
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    for (final b in p.bullets) _ResumeBullet(b),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
                  const _ResumeHeading('Education'),
                  const SizedBox(height: 10),
                  const _ResumeEntryHeader(
                    title: _educationSchool,
                    org: _educationDegree,
                    dateRange: _educationRange,
                    location: _educationLocation,
                  ),
                  if (resume == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Text(
                        'No resume file uploaded yet — add one from the admin panel to enable download/QR.',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text.toUpperCase(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black, letterSpacing: 0.6),
        ),
        const SizedBox(height: 4),
        Container(height: 1.5, color: const Color(0xFF1A56DB)),
      ],
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
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: value, style: const TextStyle(color: Color(0xFF1A56DB))),
          ],
        ),
      ),
    );
  }
}

/// Two-column entry header shared by Experience and Education: title/org
/// on the left, date range/location right-aligned — mirrors the PDF's
/// layout for each entry.
class _ResumeEntryHeader extends StatelessWidget {
  final String title;
  final String org;
  final String dateRange;
  final String location;
  const _ResumeEntryHeader({required this.title, required this.org, required this.dateRange, required this.location});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black)),
              const SizedBox(height: 1),
              Text(org, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[700])),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(dateRange, textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text(location, textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }
}

class _ResumeBullet extends StatelessWidget {
  final String text;
  const _ResumeBullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontSize: 12, color: Colors.black87)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, height: 1.45, color: Colors.black87))),
        ],
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
