// Automated Test Suite for Phase S: Observability, Crash Triage & Hotfix Reliability
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/core/observability/telemetry_service.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/tasks/domain/services/alarm_service.dart';
import 'package:habitat_mobile/services/mission_execution_service.dart';

void main() {
  late LocalDatabase db;
  late TelemetryService telemetry;
  late MissionExecutionService missionService;
  late AlarmService alarmService;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    telemetry = TelemetryService.instance;
    telemetry.clearBreadcrumbs();
    telemetry.initialize();
    missionService = MissionExecutionService(database: db);
    alarmService = AlarmService(db);
  });

  group('Phase S: Diagnostic Identity & PII Sanitization', () {
    test('S1 & S2: Context holds valid release metadata and breadcrumbs redact PII', () {
      final ctx = telemetry.context;
      expect(ctx.appVersion, equals('1.0.5'));
      expect(ctx.buildNumber, equals('6'));
      expect(ctx.platform, equals('android'));

      telemetry.recordBreadcrumb('auth', 'User user.name@domain.com from IP 192.168.1.50 initialized mission');
      expect(telemetry.breadcrumbs.length, equals(1));

      final serialized = telemetry.breadcrumbs.first.toJson();
      expect(serialized['message'], contains('[REDACTED_EMAIL]'));
      expect(serialized['message'], contains('[REDACTED_IP]'));
      expect(serialized['message'], isNot(contains('user.name@domain.com')));
      expect(serialized['message'], isNot(contains('192.168.1.50')));
    });
  });

  group('Phase S: Structured Diagnostic Event Logging (S4, S7, S8, S9)', () {
    test('S7: Alarm Lifecycle Events are logged deterministically', () {
      telemetry.recordDiagnosticEvent(DiagnosticEventType.alarmScheduleRequested, metadata: {'alarmId': 'alm_101'});
      telemetry.recordDiagnosticEvent(DiagnosticEventType.alarmScheduleAccepted, metadata: {'alarmId': 'alm_101'});
      telemetry.recordDiagnosticEvent(DiagnosticEventType.alarmTriggered, metadata: {'alarmId': 'alm_101'});
      telemetry.recordDiagnosticEvent(DiagnosticEventType.notificationShown, metadata: {'channel': 'habitat_alarm_channel'});
      telemetry.recordDiagnosticEvent(DiagnosticEventType.missionOpened, metadata: {'missionId': 'task_101'});

      expect(telemetry.eventLog.length, equals(5));
      expect(telemetry.eventLog[0], equals(DiagnosticEventType.alarmScheduleRequested));
      expect(telemetry.eventLog[3], equals(DiagnosticEventType.notificationShown));
      expect(telemetry.eventLog[4], equals(DiagnosticEventType.missionOpened));
    });

    test('S9: Camera & Proof Failures are classified with exact diagnostic types', () {
      telemetry.recordDiagnosticEvent(DiagnosticEventType.cameraPermissionDenied);
      telemetry.recordDiagnosticEvent(DiagnosticEventType.fileEmpty);
      telemetry.recordDiagnosticEvent(DiagnosticEventType.hashFailed);
      telemetry.recordDiagnosticEvent(DiagnosticEventType.proofReused);

      expect(telemetry.eventLog, contains(DiagnosticEventType.cameraPermissionDenied));
      expect(telemetry.eventLog, contains(DiagnosticEventType.fileEmpty));
      expect(telemetry.eventLog, contains(DiagnosticEventType.hashFailed));
      expect(telemetry.eventLog, contains(DiagnosticEventType.proofReused));
    });

    test('S8: Persistence Lifecycle & Recovery Events are tracked cleanly', () {
      telemetry.recordDiagnosticEvent(DiagnosticEventType.persistenceLoadStarted);
      telemetry.recordDiagnosticEvent(DiagnosticEventType.migrationStarted, metadata: {'from': 'v1', 'to': 'v3'});
      telemetry.recordDiagnosticEvent(DiagnosticEventType.migrationSuccess);
      telemetry.recordDiagnosticEvent(DiagnosticEventType.persistenceLoadSuccess);

      expect(telemetry.eventLog.length, equals(4));
      expect(telemetry.eventLog.first, equals(DiagnosticEventType.persistenceLoadStarted));
      expect(telemetry.eventLog.last, equals(DiagnosticEventType.persistenceLoadSuccess));
    });
  });

  group('Phase S: Safe Error Recovery & Core Invariants (S5, S19)', () {
    test('S5 & S19: Failed proof or missing verification never produces false mission completion or fake XP', () async {
      final task = LocalTask(
        id: 'task_s_safety',
        title: 'Morning Cold Shower',
        category: 'DISCIPLINE',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_s_safety');
      expect(attempt.status, equals('AWAITING_ACTION'));

      // Attempt complete without submitting valid proof
      final completionResult = await missionService.complete(attempt.id);
      expect(completionResult.isSuccess, isFalse);
      expect(completionResult.errorMessage, contains('Unverified proof'));
      expect(db.getTotalXP(), equals(0));
      expect(db.getTask('task_s_safety')?.isCompleted, isFalse);

      // Now submit valid proof
      final proof = await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'PHOTO',
          filePath: 'habitat_storage://proofs/shower.jpg',
          sha256Checksum: 'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
        ),
      );
      expect(proof.isPassed, isTrue);

      // Complete succeeds once
      final successCompletion = await missionService.complete(attempt.id);
      expect(successCompletion.isSuccess, isTrue);
      expect(successCompletion.earnedXp, equals(20));
      expect(db.getTotalXP(), equals(20));

      // Redundant completion is idempotent (0 extra XP)
      final duplicateCompletion = await missionService.complete(attempt.id);
      expect(duplicateCompletion.isSuccess, isTrue);
      expect(duplicateCompletion.earnedXp, equals(0));
      expect(db.getTotalXP(), equals(20));
    });
  });
}
