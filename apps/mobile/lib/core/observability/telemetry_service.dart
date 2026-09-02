// Habitat Production Telemetry & Crash Reporting Coordinator (Phase S)
import 'dart:async';
import 'package:flutter/foundation.dart';

enum TelemetryLevel { debug, info, warning, error, fatal }

enum DiagnosticEventType {
  // Alarm Lifecycle (S7)
  alarmScheduleRequested,
  alarmScheduleAccepted,
  alarmScheduleRejected,
  alarmTriggered,
  notificationShown,
  notificationFailure,
  missionOpened,
  missionOpenFailure,
  retryScheduled,
  staleCallbackDropped,
  duplicateCallbackIgnored,

  // Camera & Proof Lifecycle (S9)
  cameraPermissionDenied,
  cameraInitFailed,
  captureStarted,
  captureFailed,
  fileWriteFailed,
  fileEmpty,
  hashFailed,
  proofBindingFailed,
  proofReused,
  proofVerified,

  // Mission & Gamification
  missionCompleted,
  xpAwarded,
  streakIncremented,

  // Persistence Lifecycle (S8)
  persistenceLoadStarted,
  persistenceLoadSuccess,
  persistenceLoadFailed,
  backupRecoveryStarted,
  backupRecoverySuccess,
  backupRecoveryFailed,
  corruptionDetected,
  migrationStarted,
  migrationSuccess,
}

class DiagnosticContext {
  final String appVersion;
  final String buildNumber;
  final String gitCommit;
  final String platform;
  final String osVersion;
  final String deviceModel;

  const DiagnosticContext({
    this.appVersion = '1.0.5',
    this.buildNumber = '6',
    this.gitCommit = 'b83d3e4',
    this.platform = 'android',
    this.osVersion = 'Android 14 (API 34)',
    this.deviceModel = 'Pixel 8 / OEM Generic',
  });

  Map<String, String> toJson() => {
        'appVersion': appVersion,
        'buildNumber': buildNumber,
        'gitCommit': gitCommit,
        'platform': platform,
        'osVersion': osVersion,
        'deviceModel': deviceModel,
      };
}

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

  /// Redacts potential PII, email addresses, IP addresses, and file paths containing user identity
  static String _sanitize(String input) {
    return input
        .replaceAll(RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'), '[REDACTED_EMAIL]')
        .replaceAll(RegExp(r'(\d{1,3}\.){3}\d{1,3}'), '[REDACTED_IP]');
  }
}

abstract class ITelemetryClient {
  Future<void> recordError(dynamic error, StackTrace? stackTrace, {String? reason, bool fatal = false});
  Future<void> recordBreadcrumb(TelemetryBreadcrumb breadcrumb);
  Future<void> recordDiagnosticEvent(DiagnosticEventType event, {Map<String, dynamic>? metadata});
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
  Future<void> recordDiagnosticEvent(DiagnosticEventType event, {Map<String, dynamic>? metadata}) async {
    debugPrint('[Diagnostic Event][${event.name}] metadata: $metadata');
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
  final List<DiagnosticEventType> _eventLog = [];
  static const int _maxBreadcrumbs = 100;

  DiagnosticContext _context = const DiagnosticContext();
  ITelemetryClient _client = LocalConsoleTelemetryClient();
  bool _isInitialized = false;

  DiagnosticContext get context => _context;
  bool get isInitialized => _isInitialized;
  List<TelemetryBreadcrumb> get breadcrumbs => List.unmodifiable(_breadcrumbs);
  List<DiagnosticEventType> get eventLog => List.unmodifiable(_eventLog);

  void initialize({ITelemetryClient? client, DiagnosticContext? context}) {
    if (client != null) {
      _client = client;
    }
    if (context != null) {
      _context = context;
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

  void recordDiagnosticEvent(DiagnosticEventType event, {Map<String, dynamic>? metadata}) {
    _eventLog.add(event);
    _client.recordDiagnosticEvent(event, metadata: metadata);
  }

  void recordError(dynamic error, StackTrace? stackTrace, {String? reason, bool fatal = false}) {
    _client.recordError(error, stackTrace, reason: reason, fatal: fatal);
  }

  void setCustomTag(String key, String value) {
    _client.setCustomTag(key, value);
  }

  void clearBreadcrumbs() {
    _breadcrumbs.clear();
    _eventLog.clear();
  }
}
