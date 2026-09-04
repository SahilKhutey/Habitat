// Automated Test Suite for Track L: End-to-End Reliability & State Consistency
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

  group('Track L: Single State Owner & Mutation Invariants', () {
    test(
        'L1 & L2: LocalDatabase is the authoritative source of truth for all domain entities',
        () {
      final user = db.getOrCreateProfile(name: 'Commander');
      expect(user.displayName, equals('Commander'));

      db.saveTask(LocalTask(
        id: 'task_l1',
        title: 'Morning Breathwork',
        category: 'MIND',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      expect(db.getAllTasks().length, equals(1));
      expect(db.getTask('task_l1')?.title, equals('Morning Breathwork'));
    });
  });

  group('Track L: Idempotent Mission Completion & Deduplication', () {
    test(
        'L5 & L6: Triple completion produces exactly 1 XP event and 1 streak update',
        () async {
      final task = LocalTask(
        id: 'task_idempotent_flow',
        title: '20 Strict Pushups',
        category: 'PHYSICAL',
        taskType: 'VIDEO',
        requiresVideo: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_idempotent_flow');

      // Submit verified proof
      await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'VIDEO',
          filePath: 'habitat_storage://proofs/pushups_valid.mp4',
          sha256Checksum:
              '1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff',
          durationSeconds: 10,
        ),
      );

      // 1. First complete call
      final res1 = await missionService.complete(attempt.id);
      expect(res1.isSuccess, isTrue);
      expect(res1.earnedXp, equals(20));
      expect(db.getTotalXP(), equals(20));
      final streak1 = db.getStreak().currentStreak;
      expect(streak1, greaterThanOrEqualTo(1));

      // 2. Second complete call (duplicate)
      final res2 = await missionService.complete(attempt.id);
      expect(res2.isSuccess, isTrue);
      expect(res2.earnedXp, equals(0)); // 0 duplicate XP
      expect(db.getTotalXP(), equals(20)); // XP remains 20

      // 3. Third complete call (duplicate)
      final res3 = await missionService.complete(attempt.id);
      expect(res3.isSuccess, isTrue);
      expect(res3.earnedXp, equals(0));
      expect(db.getTotalXP(), equals(20));
      expect(db.getStreak().currentStreak, equals(streak1)); // Streak unchanged
    });

    test(
        'L7 & L8: XP events use deterministic composite keys to prevent duplicate awards',
        () {
      db.awardXP(taskId: 'task_001', attemptId: 'att_001', amount: 50);
      expect(db.getTotalXP(), equals(50));

      // Re-invoking with identical taskId and attemptId must not add extra XP
      db.awardXP(taskId: 'task_001', attemptId: 'att_001', amount: 50);
      expect(db.getTotalXP(), equals(50));

      // Re-invoking with different attemptId awards distinct XP
      db.awardXP(taskId: 'task_001', attemptId: 'att_002', amount: 50);
      expect(db.getTotalXP(), equals(100));
    });
  });

  group('Track L: Alarm Startup Reconciliation & Recovery', () {
    test(
        'L13 & L14: reconcilePersistedAlarmsOnStartup synchronizes enabled alarms',
        () async {
      db.saveTask(LocalTask(
        id: 'task_reconcile',
        title: 'Cold Plunge',
        category: 'DISCIPLINE',
        taskType: 'PHOTO',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      db.saveAlarm(LocalAlarm(
        id: 'alm_enabled',
        taskId: 'task_reconcile',
        scheduledTime: '06:00',
        enabled: true,
        createdAt: DateTime.now(),
      ));

      db.saveAlarm(LocalAlarm(
        id: 'alm_disabled',
        taskId: 'task_reconcile',
        scheduledTime: '09:00',
        enabled: false,
        createdAt: DateTime.now(),
      ));

      final reconciledCount =
          await alarmService.reconcilePersistedAlarmsOnStartup();
      expect(reconciledCount, equals(1)); // Only the enabled alarm is scheduled
    });

    test('L10 & L11: Corrupt payload recovery restores defaults without crash',
        () {
      const corruptPayload =
          '{ "invalid_json": true, "tasks": "corrupted_non_list" }';

      // Restoring corrupt data should safely fall back and seed default templates
      db.restoreFromStateJson(corruptPayload);

      expect(db.getAllTasks().isNotEmpty, isTrue); // Templates safely seeded
      expect(db.getTotalXP(), equals(0));
    });
  });
}
