// Habitat Application & Network Configuration
import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _defaultProdApiUrl = 'https://api.habitat.app/api/v1';
  static const String _defaultDevApiUrl = 'http://10.0.2.2:4000/api/v1';

  /// Environment-injected API Base URL (passed via --dart-define=HABITAT_API_URL=...)
  static const String _injectedApiUrl =
      String.fromEnvironment('HABITAT_API_URL');

  /// Runtime override if configured dynamically by the user
  static String? _runtimeOverrideUrl;

  /// Effective API Base URL with strict production validation
  static String get apiBaseUrl {
    final effectiveUrl = () {
      if (_runtimeOverrideUrl != null && _runtimeOverrideUrl!.isNotEmpty) {
        return _runtimeOverrideUrl!;
      }
      if (_injectedApiUrl.isNotEmpty) {
        return _injectedApiUrl;
      }
      return kReleaseMode ? _defaultProdApiUrl : _defaultDevApiUrl;
    }();

    if (kReleaseMode) {
      final uri = Uri.tryParse(effectiveUrl);
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host == 'localhost' ||
          uri.host == '127.0.0.1' ||
          uri.host == '10.0.2.2' ||
          uri.host.contains('mock') ||
          uri.host.contains('development-server')) {
        throw StateError(
          'Production Security Violation: Release builds must strictly connect via secure HTTPS to official Habitat infrastructure. Prohibited target: $effectiveUrl',
        );
      }
    }

    return effectiveUrl;
  }

  /// Override API URL dynamically (e.g., custom self-hosted server)
  static void setApiBaseUrl(String? url) {
    if (kReleaseMode && url != null) {
      final uri = Uri.tryParse(url);
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host == 'localhost' ||
          uri.host == '127.0.0.1' ||
          uri.host == '10.0.2.2') {
        throw ArgumentError(
          'Release builds require a secure HTTPS endpoint. Insecure or loopback address rejected: $url',
        );
      }
    }
    _runtimeOverrideUrl = url;
  }

  /// Whether the app is currently running a production release build
  static bool get isProduction => kReleaseMode;

  /// Application version identifier
  static const String appVersion = '1.1.0';
}
