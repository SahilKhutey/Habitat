// Habitat Application & Network Configuration
import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _defaultProdApiUrl = 'https://api.habitat.app/api/v1';
  static const String _defaultDevApiUrl = 'http://10.0.2.2:4000/api/v1';

  /// Environment-injected API Base URL (passed via --dart-define=HABITAT_API_URL=...)
  static const String _injectedApiUrl = String.fromEnvironment('HABITAT_API_URL');

  /// Runtime override if configured dynamically by the user
  static String? _runtimeOverrideUrl;

  /// Effective API Base URL
  static String get apiBaseUrl {
    if (_runtimeOverrideUrl != null && _runtimeOverrideUrl!.isNotEmpty) {
      return _runtimeOverrideUrl!;
    }
    if (_injectedApiUrl.isNotEmpty) {
      return _injectedApiUrl;
    }
    // Default to production in release mode; emulator loopback in debug mode
    return kReleaseMode ? _defaultProdApiUrl : _defaultDevApiUrl;
  }

  /// Override API URL dynamically (e.g., custom self-hosted server)
  static void setApiBaseUrl(String? url) {
    _runtimeOverrideUrl = url;
  }

  /// Whether the app is currently running a production release build
  static bool get isProduction => kReleaseMode;

  /// Application version identifier
  static const String appVersion = '1.1.0';
}
