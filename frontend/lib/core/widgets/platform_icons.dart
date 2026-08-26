import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Icon + brand color for a social/platform link name (case-insensitive),
/// used wherever social links are rendered (desktop icons, dock, etc).
/// Brand icons come from font_awesome_flutter (Font Awesome Free brand set)
/// — standard practice for "follow me on X" links, not an impersonation
/// claim. FontAwesomeIcons constants are [FaIconData] (not plain
/// [IconData]) as of font_awesome_flutter 11, so this wraps whichever kind
/// each platform needs and exposes a single [build] method.
class PlatformIconInfo {
  final IconData? _materialIcon;
  final FaIconData? _faIcon;
  final Color color;

  const PlatformIconInfo.material(IconData icon, this.color)
      : _materialIcon = icon,
        _faIcon = null;

  const PlatformIconInfo.fa(FaIconData icon, this.color)
      : _faIcon = icon,
        _materialIcon = null;

  Widget build({double size = 24, Color? color}) {
    final resolvedColor = color ?? this.color;
    if (_faIcon != null) return FaIcon(_faIcon, size: size, color: resolvedColor);
    return Icon(_materialIcon, size: size, color: resolvedColor);
  }
}

final platformIconInfo = <String, PlatformIconInfo>{
  'github': const PlatformIconInfo.fa(FontAwesomeIcons.github, Color(0xFFFFFFFF)),
  'linkedin': const PlatformIconInfo.fa(FontAwesomeIcons.linkedinIn, Color(0xFF0A66C2)),
  'pubdev': const PlatformIconInfo.material(Icons.inventory_2_rounded, Color(0xFF00589B)),
  'twitter': const PlatformIconInfo.fa(FontAwesomeIcons.xTwitter, Color(0xFFFFFFFF)),
  'x': const PlatformIconInfo.fa(FontAwesomeIcons.xTwitter, Color(0xFFFFFFFF)),
  'instagram': const PlatformIconInfo.fa(FontAwesomeIcons.instagram, Color(0xFFE1306C)),
  'youtube': const PlatformIconInfo.fa(FontAwesomeIcons.youtube, Color(0xFFFF0000)),
  'email': const PlatformIconInfo.material(Icons.email_rounded, Color(0xFFEA4335)),
  'website': const PlatformIconInfo.material(Icons.public_rounded, Color(0xFF34D5E0)),
  'buymeacoffee': const PlatformIconInfo.fa(FontAwesomeIcons.mugSaucer, Color(0xFFFFDD00)),
  'coffee': const PlatformIconInfo.fa(FontAwesomeIcons.mugSaucer, Color(0xFFFFDD00)),
};

final _fallback = const PlatformIconInfo.material(Icons.link_rounded, Color(0xFF7C5CFF));

PlatformIconInfo platformIconInfoFor(String platform) =>
    platformIconInfo[platform.toLowerCase()] ?? _fallback;
