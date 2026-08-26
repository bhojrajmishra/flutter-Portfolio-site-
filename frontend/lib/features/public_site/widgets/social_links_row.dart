import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/data_providers.dart';
import '../../../core/theme/app_theme.dart';

const _platformIcons = {
  'github': Icons.code,
  'linkedin': Icons.business_center_outlined,
  'pubdev': Icons.inventory_2_outlined,
  'twitter': Icons.alternate_email,
  'x': Icons.alternate_email,
  'email': Icons.email_outlined,
  'website': Icons.public,
};

class SocialLinksRow extends ConsumerWidget {
  const SocialLinksRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(socialLinksProvider);
    return linksAsync.maybeWhen(
      data: (links) {
        if (links.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 16,
          alignment: WrapAlignment.center,
          children: links
              .map((link) => IconButton(
                    tooltip: link.platform,
                    onPressed: () => launchUrl(Uri.parse(link.url), webOnlyWindowName: '_blank'),
                    icon: Icon(
                      _platformIcons[link.platform.toLowerCase()] ?? Icons.link,
                      color: AppColors.textSecondary,
                    ),
                  ))
              .toList(),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
