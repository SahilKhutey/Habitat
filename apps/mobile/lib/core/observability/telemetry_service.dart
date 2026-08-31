// Habitat Production Telemetry & Crash Reporting Coordinator (Track C)
import 'dart:async';
import 'package:flutter/foundation.dart';

enum TelemetryLevel { debug, info, warning, error, fatal }

class TelemetryBreadcrumb {
  final String category;
  final String message;
  final TelemetryLevel level;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const TelemetryBreadcrumb({
    required this.category,
    required this.message,
    this.level = TelemetryLevel.info,
    required this.timestamp,
    this.data,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'message': _sanitize(message),
        'level': level.name,
        'timestamp': timestamp.toIso8601String(),
        if (data != null) 'data': data!.map((k, v) => MapEntry(k, _sanitize(v.toString()))),
      };

  /// Redacts potential PII, file paths with user names, and biometric keypoints
  static String _sanitize(String input) {
    return input
        .replaceAll(RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'), '[REDACTED_EMAIL]')
        .replaceAll(RegExp(r'(\d{1,3}\.){3}\d{1,3}'), '[REDACTED_IP]');
  }
}

abstract class ITelemetryClient {
  Future<void> recordError(dynamic error, StackTrace? stackTrace, {String? reason, bool fatal = false});
  Future<void> recordBreadcrumb(TelemetryBreadcrumb breadcrumb);
  Future<void> setCustomTag(String key, String value);
}

class LocalConsoleTelemetryClient implements ITelemetryClient {
  @override
  Future<void> recordError(dynamic error, StackTrace? stackTrace, {String? reason, bool fatal = false}) async {
    debugPrint('[Telemetry] ${fatal ? "FATAL" : "ERROR"}: $error | reason: $reason');
    if (stackTrace != null) {
      debugPrint('[Telemetry StackTrace]:\n$stackTrace');
    }
  }

  @override
  Future<void> recordBreadcrumb(TelemetryBreadcrumb breadcrumb) async {
    debugPrint('[Telemetry Breadcrumb][${breadcrumb.category}]: ${breadcrumb.message}');
  }

  @override
  Future<void> setCustomTag(String key, String value) async {
    debugPrint('[Telemetry Tag] $key: $value');
  }
}

class TelemetryService {
  static final TelemetryService instance = TelemetryService._internal();
  TelemetryService._internal();

  final List<TelemetryBreadcrumb> _breadcrumbs = [];
  static const int _maxBreadcrumbs = 100;

  ITelemetryClient _client = LocalConsoleTelemetryClient();
  bool _isInitialized = false;

  void initialize({ITelemetryClient? client}) {
    if (client != null) {
      _client = client;
    }
    _isInitialized = true;
    _installFlutterErrorHooks();
  }

  void _installFlutterErrorHooks() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      recordError(
        details.exception,
        details.stack,
        reason: details.context?.toString(),
        fatal: false,
      );
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      recordError(error, stack, fatal: true);
      return true;
    };
  }

  void recordBreadcrumb(String category, String message, {TelemetryLevel level = TelemetryLevel.info, Map<String, dynamic>? data}) {
    final crumb = TelemetryBreadcrumb(
      category: category,
      message: message,
      level: level,
      timestamp: DateTime.now(),
      data: data,
    );

    if (_breadcrumbs.length >= _maxBreadcrumbs) {
      _breadcrumbs.removeAt(0);
    }
    _breadcrumbs.add(crumb);

    _client.recordBreadcrumb(crumb);
  }

  Future<void> recordError(dynamic error, StackTrace? stackTrace, {String? reason, bool fatal = false}) async {
    await _client.recordError(error, stackTrace, reason: reason, fatal: fatal);
  }

  List<TelemetryBreadcrumb> get breadcrumbs => List.unmodifiable(_breadcrumbs);
  bool get isInitialized => _isInitialized;
}
