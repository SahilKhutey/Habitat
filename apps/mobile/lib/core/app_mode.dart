// Phase 19 Local-First MVP App Mode Architecture
enum AppMode {
  offlineMvp,
  online,
}

class AppConfig {
  static AppMode mode = AppMode.offlineMvp;

  static bool get isOfflineMvp => mode == AppMode.offlineMvp;
  static bool get isOnline => mode == AppMode.online;
}
