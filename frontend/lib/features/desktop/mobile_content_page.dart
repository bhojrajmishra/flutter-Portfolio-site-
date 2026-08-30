import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'widgets/window_frame.dart';
import 'window_manager.dart';

/// Fullscreen equivalent of a desktop window, used on narrow viewports
/// where dragging/resizing floating windows isn't practical. Renders the
/// exact same content widget a desktop [WindowFrame] would.
class MobileContentPage extends StatelessWidget {
  final String windowId;
  const MobileContentPage({super.key, required this.windowId});

  @override
  Widget build(BuildContext context) {
    final def = windowDefinitions[windowId];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(def?.title ?? ''),
      ),
      body: buildWindowContent(windowId, MediaQuery.sizeOf(context)),
    );
  }
}
