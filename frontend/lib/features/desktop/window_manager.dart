import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Static metadata for each window "app" the desktop can open.
class WindowDef {
  final String title;
  final IconData icon;
  final Size defaultSize;
  const WindowDef({required this.title, required this.icon, required this.defaultSize});
}

const windowDefinitions = <String, WindowDef>{
  'about': WindowDef(title: 'About Me', icon: Icons.person_outline, defaultSize: Size(640, 480)),
  'projects': WindowDef(title: 'Projects', icon: Icons.work_outline, defaultSize: Size(780, 580)),
  'experience':
      WindowDef(title: 'Experience & Education', icon: Icons.timeline_outlined, defaultSize: Size(680, 560)),
  'contact': WindowDef(title: 'Contact', icon: Icons.mail_outline, defaultSize: Size(520, 540)),
  'blog': WindowDef(title: 'Blog', icon: Icons.travel_explore_rounded, defaultSize: Size(820, 620)),
};

@immutable
class DesktopWindow {
  final String id;
  final String title;
  final IconData icon;
  final Offset position;
  final Size size;
  final int zIndex;
  final bool minimized;
  final Rect? preMaximizeBounds;

  const DesktopWindow({
    required this.id,
    required this.title,
    required this.icon,
    required this.position,
    required this.size,
    required this.zIndex,
    this.minimized = false,
    this.preMaximizeBounds,
  });

  bool get isMaximized => preMaximizeBounds != null;

  DesktopWindow copyWith({
    Offset? position,
    Size? size,
    int? zIndex,
    bool? minimized,
    Rect? preMaximizeBounds,
    bool clearPreMaximizeBounds = false,
  }) {
    return DesktopWindow(
      id: id,
      title: title,
      icon: icon,
      position: position ?? this.position,
      size: size ?? this.size,
      zIndex: zIndex ?? this.zIndex,
      minimized: minimized ?? this.minimized,
      preMaximizeBounds: clearPreMaximizeBounds ? null : (preMaximizeBounds ?? this.preMaximizeBounds),
    );
  }
}

const _minWindowSize = Size(320, 240);
const _cascadeStep = 32.0;
const _edgeMargin = 16.0;

class WindowManagerNotifier extends Notifier<List<DesktopWindow>> {
  int _zCounter = 0;

  @override
  List<DesktopWindow> build() => [];

  void openWindow(String id, {required Size desktopSize}) {
    final existingIndex = state.indexWhere((w) => w.id == id);
    _zCounter++;

    if (existingIndex != -1) {
      state = [
        for (final w in state)
          if (w.id == id) w.copyWith(minimized: false, zIndex: _zCounter) else w,
      ];
      return;
    }

    final def = windowDefinitions[id];
    if (def == null) return;

    final cascadeIndex = state.length % 6;
    final cascade = Offset(cascadeIndex * _cascadeStep, cascadeIndex * _cascadeStep);
    final baseX = (desktopSize.width - def.defaultSize.width) / 2;
    final baseY = (desktopSize.height - def.defaultSize.height) / 2;

    final maxX = math.max(_edgeMargin, desktopSize.width - def.defaultSize.width - _edgeMargin);
    final maxY = math.max(_edgeMargin, desktopSize.height - def.defaultSize.height - _edgeMargin);
    final position = Offset(
      (baseX + cascade.dx).clamp(_edgeMargin, maxX),
      (baseY + cascade.dy).clamp(_edgeMargin, maxY),
    );

    state = [
      ...state,
      DesktopWindow(
        id: id,
        title: def.title,
        icon: def.icon,
        position: position,
        size: def.defaultSize,
        zIndex: _zCounter,
      ),
    ];
  }

  void closeWindow(String id) {
    state = state.where((w) => w.id != id).toList();
  }

  void focusWindow(String id) {
    if (state.isEmpty || state.last.id == id) return;
    _zCounter++;
    state = [
      for (final w in state)
        if (w.id == id) w.copyWith(zIndex: _zCounter) else w,
    ];
  }

  void minimizeWindow(String id) {
    state = [
      for (final w in state)
        if (w.id == id) w.copyWith(minimized: true) else w,
    ];
  }

  void moveWindow(String id, Offset newPosition, Size desktopSize) {
    state = [
      for (final w in state)
        if (w.id == id)
          w.copyWith(
            position: Offset(
              newPosition.dx.clamp(-w.size.width + 80, desktopSize.width - 80),
              newPosition.dy.clamp(0, desktopSize.height - 40),
            ),
          )
        else
          w,
    ];
  }

  void resizeWindow(String id, Size newSize) {
    final clamped = Size(
      math.max(_minWindowSize.width, newSize.width),
      math.max(_minWindowSize.height, newSize.height),
    );
    state = [
      for (final w in state)
        if (w.id == id) w.copyWith(size: clamped) else w,
    ];
  }

  void toggleMaximize(String id, Size desktopSize) {
    state = [
      for (final w in state)
        if (w.id == id)
          w.isMaximized
              ? w.copyWith(
                  position: w.preMaximizeBounds!.topLeft,
                  size: w.preMaximizeBounds!.size,
                  clearPreMaximizeBounds: true,
                )
              : w.copyWith(
                  preMaximizeBounds: Rect.fromLTWH(w.position.dx, w.position.dy, w.size.width, w.size.height),
                  position: const Offset(_edgeMargin, _edgeMargin),
                  size: Size(desktopSize.width - _edgeMargin * 2, desktopSize.height - _edgeMargin * 2),
                )
        else
          w,
    ];
  }
}

final windowManagerProvider = NotifierProvider<WindowManagerNotifier, List<DesktopWindow>>(
  WindowManagerNotifier.new,
);
