// Habitat Accessibility & Semantics Layer (Phase 17)
import 'dart:ui';
import 'package:flutter/material.dart';

abstract final class HabitatA11y {
  /// Accessible button wrapper exposing proper semantic role, action label, and hint
  static Widget button({
    required String label,
    String? hint,
    required Widget child,
    VoidCallback? onTap,
    bool isEnabled = true,
  }) {
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: label,
      hint: hint,
      onTap: isEnabled ? onTap : null,
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: child,
      ),
    );
  }

  /// Structural heading semantic wrapper for screen readers (TalkBack / VoiceOver)
  static Widget heading({
    required String label,
    int level = 1,
    required Widget child,
  }) {
    return Semantics(
      header: true,
      label: label,
      child: child,
    );
  }

  /// Dynamic status announcement region for live metrics (XP, Streaks, Timer)
  static Widget status({
    required String label,
    required String value,
    required Widget child,
  }) {
    return Semantics(
      liveRegion: true,
      label: '$label: $value',
      child: child,
    );
  }

  /// Accessible chart wrapper presenting complete textual descriptions for visual charts
  static Widget chartAlternative({
    required String description,
    required Widget child,
  }) {
    return Semantics(
      label: description,
      child: child,
    );
  }
}

/// Unified scroll behavior supporting touch, mouse, trackpad, and stylus drag-scrolling
class HabitatAccessibilityScrollBehavior extends MaterialScrollBehavior {
  const HabitatAccessibilityScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
