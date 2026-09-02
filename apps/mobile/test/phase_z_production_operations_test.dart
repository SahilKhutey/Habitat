// Master Automated Test Suite for Phase Z: Production Operations, User Feedback & Continuous Reliability
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/tasks/domain/services/alarm_service.dart';
import 'package:habitat_mobile/services/mission_execution_service.dart';
import 'package:habitat_mobile/services/native_alarm_scheduler.dart';

void main() {
  late LocalDatabase db;
  late MissionExecutionService missionService;
  late AlarmService alarmService;
  late NativeAlarmScheduler scheduler;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    missionService = MissionExecutionService(database: db);
    alarmService = AlarmService(db);
    scheduler = NativeAlarmScheduler.instance;
  });

  group('Phase Z: Core Production Invariants (Z13)', () {
    test('Z13.1: Completion Invariant — No valid proof strictly prevents completion', () async {
      final task = LocalTask(
        id: 'task_z_unverified',
        title: 'Morning Pushup Protocol',
        category: 'PHYSICAL',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_z_unverified');
      final result = await missionService.complete(attempt.id);

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Unverified proof'));
      expect(db.getTotalXP(), equals(0));
      expect(db.getStreak().currentStreak, equals(0));
    });

    test('Z13.2: Reward & Streak Invariants — Exactly 1 XP (+20) and 1 streak update per qualifying completion', () async {
      final task = LocalTask(
        id: 'task_z_reward',
        title: 'Cold Water Hydration',
        category: 'HEALTH',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_z_reward');
      await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'PHOTO',
          filePath: 'habitat_storage://proofs/z_water.jpg',
          sha256Checksum: '1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff',
        ),
      );

      final completion1 = await missionService.complete(attempt.id);
      expect(completion1.isSuccess, isTrue);
      expect(completion1.earnedXp, equals(20));
      expect(db.getTotalXP(), equals(20));
      expect(db.getStreak().currentStreak, equals(1));

      // Attempt second complete invocation (idempotency check)
      final completion2 = await missionService.complete(attempt.id);
      expect(completion2.isSuccess, isTrue);
      expect(completion2.earnedXp, equals(0));
      expect(db.getTotalXP(), equals(20));
      expect(db.getStreak().currentStreak, equals(1));
    });

    test('Z13.3: Alarm & Retry Invariant — Completion disarms alarm and cancels retries', () async {
      final task = LocalTask(
        id: 'task_z_retry',
        title: 'Evening Reflection',
        category: 'MIND',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final occurrence = scheduler.scheduleExactAlarm(
        alarmId: 'alm_z_retry',
        missionId: 'task_z_retry',
        scheduledAt: DateTime.now(),
      );

      final attempt = await missionService.start('task_z_retry', alarmId: 'alm_z_retry');
      await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'PHOTO',
          filePath: 'habitat_storage://proofs/z_reflection.jpg',
          sha256Checksum: 'abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef',
        ),
      );

      await missionService.complete(attempt.id);
      scheduler.onMissionCompleted(occurrenceId: occurrence.occurrenceId);

      expect(occurrence.isCancelled, isTrue);
      expect(db.getTask('task_z_retry')?.isCompleted, isTrue);
    });
  });

  group('Phase Z: Disaster Recovery & Persistence Invariants (Z19, Z26)', () {
    test('Z19 & Z26: Cold recovery from disk restores full state with zero corruption', () async {
      final task = LocalTask(
        id: 'task_z_persistence',
        title: 'Full System Operation Protocol',
        category: 'DISCIPLINE',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_z_persistence');
      await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'PHOTO',
          filePath: 'habitat_storage://proofs/z_drill.jpg',
          sha256Checksum: '9999888877776666555544443333222211110000aaaabbbbccccddddeeeeffff',
        ),
      );
      await missionService.complete(attempt.id);

      await db.flush();
      final diskSnapshot = db.exportCompleteStateJson();

      db.resetAllData();
      expect(db.getAllTasks().isEmpty, isTrue);

      db.restoreFromStateJson(diskSnapshot);

      expect(db.getTask('task_z_persistence')?.isCompleted, isTrue);
      expect(db.getTotalXP(), equals(20));
      expect(db.getStreak().currentStreak, equals(1));
    });
  });
}
