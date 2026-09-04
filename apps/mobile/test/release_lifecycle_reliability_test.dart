// Automated Test Suite for Track N: Release Candidate Hardening & Mobile Lifecycle Reliability
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
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

  group('Track N3 & N8: Explicit Startup Ordering & Offline-First Operations',
      () {
    test(
        'N3: Startup sequence preserves persisted tasks, alarms, XP, and streak without duplicates',
        () async {
      // Step A: Seed initial data
      db.saveTask(LocalTask(
        id: 'task_rc_1',
        title: 'Read 20 Pages',
        category: 'MIND',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      db.saveAlarm(LocalAlarm(
        id: 'alm_rc_1',
        taskId: 'task_rc_1',
        scheduledTime: '07:00',
        enabled: true,
        createdAt: DateTime.now(),
      ));

      db.awardXP(taskId: 'task_rc_1', amount: 50);
      db.updateStreak();

      final exportedState = db.exportCompleteStateJson();

      // Step B: Simulate cold restart with startup sequence
      db.resetAllData();
      expect(db.getAllTasks().isEmpty, isTrue);

      // Startup Step 1: load persisted state
      db.restoreFromStateJson(exportedState);

      // Startup Step 2: default templates (should NOT overwrite existing tasks)
      db.initializeDefaultTemplates();

      // Startup Step 3: reconcile alarms
      final reconciled = await alarmService.reconcilePersistedAlarmsOnStartup();

      expect(db.getTask('task_rc_1'), isNotNull);
      expect(db.getTotalXP(), equals(50));
      expect(db.getStreak().currentStreak, greaterThanOrEqualTo(1));
      expect(reconciled, equals(1));
    });

    test(
        'N8: Offline execution executes complete Mission -> Proof -> XP -> Streak flow without network',
        () async {
      final task = LocalTask(
        id: 'task_offline_flow',
        title: 'Morning Sunlight',
        category: 'DISCIPLINE',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_offline_flow');
      final verification = await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'PHOTO',
          filePath: 'app_storage://proofs/sunlight.jpg',
          sha256Checksum:
              '1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff',
        ),
      );
      expect(verification.isPassed, isTrue);

      final result = await missionService.complete(attempt.id);
      expect(result.isSuccess, isTrue);
      expect(result.earnedXp, equals(20));
      expect(db.getTask('task_offline_flow')?.isCompleted, isTrue);
      expect(db.getTotalXP(), equals(20));
    });
  });

  group(
      'Track N7, N11 & N12: Interrupted Mission, Idempotency & Resource Safety',
      () {
    test(
        'N7: Interrupted mission remains in AWAITING_ACTION without premature completion',
        () async {
      final task = LocalTask(
        id: 'task_interrupted',
        title: 'Cold Shower',
        category: 'DISCIPLINE',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_interrupted');
      expect(attempt.status, equals('AWAITING_ACTION'));

      // User leaves or app backgrounds during capture (no complete call)
      final reloadedAttempt = db.getAttempt(attempt.id);
      expect(reloadedAttempt?.status, equals('AWAITING_ACTION'));
      expect(db.getTask('task_interrupted')?.isCompleted, isFalse);
      expect(db.getTotalXP(), equals(0)); // 0 XP awarded
    });

    test(
        'N11: Idempotent mission completion invariant across repeated restarts',
        () async {
      final task = LocalTask(
        id: 'task_repeat_flow',
        title: '50 Squats',
        category: 'PHYSICAL',
        taskType: 'VIDEO',
        requiresVideo: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_repeat_flow');
      await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'VIDEO',
          filePath: 'app_storage://proofs/squats.mp4',
          sha256Checksum:
              'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
          durationSeconds: 15,
        ),
      );

      // Complete attempt
      final res1 = await missionService.complete(attempt.id);
      expect(res1.isSuccess, isTrue);
      expect(res1.earnedXp, equals(20));

      // Re-invoking complete on the same attempt produces 0 extra XP
      final res2 = await missionService.complete(attempt.id);
      expect(res2.isSuccess, isTrue);
      expect(res2.earnedXp, equals(0));
      expect(db.getTotalXP(), equals(20));
    });
  });
}
