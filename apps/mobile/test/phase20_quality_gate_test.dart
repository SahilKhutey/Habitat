// Habitat Phase 20 Cross-Phase Quality & Regression Gate Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/core/health/health_progress_service.dart';
import 'package:habitat_mobile/core/reliability/habitat_reliability.dart';

void main() {
  late LocalDatabase db;
  late HealthProgressService healthService;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    healthService = HealthProgressService(database: db);
  });

  group('Phase 20: Master Quality & Regression Gate Tests', () {
    test(
        '20.1: Full Core Product Loop Integration (Task -> Alarm -> Mission -> Verification -> XP -> Streak -> Progress)',
        () async {
      // 1. Task & Alarm Creation
      final task = LocalTask(
        id: 'gate_task_01',
        title: '20 Pushups Discipline',
        category: 'PHYSICAL',
        taskType: 'VIDEO',
        requiresVideo: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final alarm = LocalAlarm(
        id: 'gate_alarm_01',
        taskId: 'gate_task_01',
        scheduledTime: '07:00',
        createdAt: DateTime.now(),
      );
      db.saveAlarm(alarm);

      // 2. Mission Trigger & Attempt Creation
      final attempt = LocalTaskAttempt(
        id: 'gate_att_01',
        taskId: 'gate_task_01',
        alarmId: 'gate_alarm_01',
        attemptNumber: 1,
        status: 'RINGING',
        triggeredAt: DateTime.now(),
      );
      db.saveAttempt(attempt);

      // 3. Evidence Capture & Verification
      final proof = LocalProof(
        id: 'gate_proof_01',
        taskId: 'gate_task_01',
        attemptId: 'gate_att_01',
        type: 'VIDEO',
        localPath: '/data/proofs/pushups.mp4',
        durationSeconds: 15,
        isVerified: true,
        createdAt: DateTime.now(),
      );
      db.saveProof(proof);

      // 4. Mission Completion & Disarm
      db.updateAttemptStatus(
          attemptId: 'gate_att_01',
          status: 'COMPLETED',
          completedAt: DateTime.now());
      db.awardXP(taskId: 'gate_task_01', attemptId: 'gate_att_01', amount: 20);
      db.updateStreak();

      // 5. Verify Progression & Ledger State
      expect(db.getTotalXP(), greaterThanOrEqualTo(20));
      expect(db.getStreak().currentStreak, equals(1));
      final completions = db.getDailyCompletions();
      expect(completions.values.any((v) => v > 0), isTrue);
    });

    test('20.2: Health Integration & Persistence Gate', () async {
      healthService.addWaterMl(500);
      healthService.addWaterMl(750);
      healthService.logMeal('BREAKFAST');
      healthService.logNap(const Duration(minutes: 30));

      final summary = healthService.getTodaySummary();
      expect(summary.waterLiters, equals(1.25));
      expect(summary.mealCount, equals(1));
      expect(summary.napMinutes, equals(30));

      // Flush to ensure durable persistence
      await db.flush();
      expect(db.revision, greaterThanOrEqualTo(1));
    });

    test('20.3: Reliability & Snapshot Recovery Gate', () async {
      db.saveTask(LocalTask(
        id: 'rel_task_01',
        title: 'Read 10 Pages',
        category: 'MIND',
        taskType: 'PHOTO',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await db.flush();

      // Verify reliability coordinator snapshot
      final snapshot = HabitatReliabilityCoordinator.getSnapshot(db: db);
      expect(snapshot.taskCount, greaterThanOrEqualTo(1));
      expect(snapshot.revision, greaterThanOrEqualTo(1));

      // Verify recovery from backup
      final recovered = HabitatReliabilityCoordinator.recover(db: db);
      expect(recovered, isTrue);
    });

    test('20.4: Durable Offline Sync Queue Gate', () {
      db.enqueueSyncEvent(
        eventType: 'MISSION_COMPLETED',
        idempotencyKey: 'idemp_gate_001',
        payload: {'missionId': 'gate_task_01', 'xp': 20},
      );

      final pending = db.getPendingSyncEvents();
      expect(pending.length, equals(1));
      expect(pending.first.idempotencyKey, equals('idemp_gate_001'));
    });
  });
}
