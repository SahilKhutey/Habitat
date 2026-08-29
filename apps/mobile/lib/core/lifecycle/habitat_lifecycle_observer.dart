// Habitat Application Lifecycle & State Synchronization Observer
import 'package:flutter/material.dart';

class HabitatLifecycleObserver with WidgetsBindingObserver {
  final VoidCallback? onResume;
  final VoidCallback? onPause;

  HabitatLifecycleObserver({this.onResume, this.onPause});

  void register() {
    WidgetsBinding.instance.addObserver(this);
  }

  void unregister() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        onResume?.call();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        onPause?.call();
        break;
      default:
        break;
    }
  }
}
