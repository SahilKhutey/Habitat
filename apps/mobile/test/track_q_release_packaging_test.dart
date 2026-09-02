// Automated Test Suite for Track Q: Store-Readiness, Android/OEM Certification & Final Release Packaging
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/profile/domain/models/permission_status.dart';
import 'package:habitat_mobile/features/tasks/domain/services/alarm_service.dart';
import 'package:habitat_mobile/services/mission_execution_service.dart';

void main() {
  late LocalDatabase db;
  late MissionExecutionService missionService;
  late AlarmService alarmService;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    missionService = MissionExecutionService(database: db);
    alarmService = AlarmService(db);
  });

  group('Track Q: Permissions Rationale & Store Compliance Models', () {
    test('Q1: AppPermissionModel reports correct descriptor and rationale strings', () {
      const cameraPerm = AppPermission(
        type: AppPermissionType.camera,
        name: 'Camera',
        description: 'Required for real physical photo & video proof capture.',
        status: PermissionAuthorizationStatus.granted,
      );

      expect(cameraPerm.name, equals('Camera'));
      expect(cameraPerm.isGranted, isTrue);

      const notifPerm = AppPermission(
        type: AppPermissionType.notifications,
        name: 'Notifications',
        description: 'Required for high-priority mission alarms and escalation reminders.',
        status: PermissionAuthorizationStatus.denied,
      );

      expect(notifPerm.isGranted, isFalse);
    });
  });

  group('Track Q: Release Packaging & End-to-End System Integrity', () {
    test('Q2: Full Release Flow — Zero regression across Startup -> Alarm -> Proof -> XP -> Persistence', () async {
      // 1. Seed Task & Alarm
      final task = LocalTask(
        id: 'task_q_release',
        title: '5km Morning Run',
        category: 'PHYSICAL',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      db.saveAlarm(LocalAlarm(
        id: 'alm_q_release',
        taskId: 'task_q_release',
        scheduledTime: '06:30',
        enabled: true,
        createdAt: DateTime.now(),
      ));

      // 2. Startup Reconciliation
      final reconciled = await alarmService.reconcilePersistedAlarmsOnStartup();
      expect(reconciled, equals(1));

      // 3. Trigger & Start Mission
      final attempt = await missionService.start('task_q_release', alarmId: 'alm_q_release');
      expect(attempt.status, equals('AWAITING_ACTION'));

      // 4. Submit Proof with 64-char SHA-256
      final verification = await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'PHOTO',
          filePath: 'habitat_storage://proofs/run_proof.jpg',
          sha256Checksum: '1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff',
        ),
      );
      expect(verification.isPassed, isTrue);

      // 5. Complete Mission (Atomic)
      final completionResult = await missionService.complete(attempt.id);
      expect(completionResult.isSuccess, isTrue);
      expect(completionResult.earnedXp, equals(20));
      expect(db.getTotalXP(), equals(20));

      // 6. Persistence & Cold Reload
      final savedState = db.exportCompleteStateJson();
      db.resetAllData();
      expect(db.getAllTasks().isEmpty, isTrue);

      db.restoreFromStateJson(savedState);
      expect(db.getTask('task_q_release')?.isCompleted, isTrue);
      expect(db.getTotalXP(), equals(20));
      expect(db.getStreak().currentStreak, greaterThanOrEqualTo(1));
    });
  });
}
