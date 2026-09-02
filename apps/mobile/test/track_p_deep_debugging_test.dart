// Automated Test Suite for Track P: Deep Debugging & Failure Elimination
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

  group('Track P5: Persistence Failure Modes & Corruption Defense', () {
    test('P5.1: Malformed JSON payload safely triggers fallback template seeding', () {
      const corruptPayload = 'INVALID_NON_JSON_DATA_###';
      db.restoreFromStateJson(corruptPayload);

      // Verify safe recovery to default templates without crashing
      expect(db.getAllTasks().isNotEmpty, isTrue);
      expect(db.getTotalXP(), equals(0));
    });

    test('P5.2: Missing entity collections in JSON payload defaults to empty collections', () {
      const partialJson = '{"version": 3, "tasks": []}';
      db.restoreFromStateJson(partialJson);

      expect(db.getAllAlarms().isEmpty, isTrue);
      expect(db.getAllAttempts().isEmpty, isTrue);
      expect(db.getTotalXP(), equals(0));
    });
  });

  group('Track P7 & P8: Alarm Scheduling Idempotency & Deduplication', () {
    test('P7: Scheduling same alarm 3 times results in single active schedule', () {
      final now = DateTime.now().add(const Duration(hours: 1));
      final occ1 = scheduler.scheduleExactAlarm(
        alarmId: 'alm_p7_1',
        missionId: 'task_p7_1',
        scheduledAt: now,
      );
      final occ2 = scheduler.scheduleExactAlarm(
        alarmId: 'alm_p7_1',
        missionId: 'task_p7_1',
        scheduledAt: now,
      );
      final occ3 = scheduler.scheduleExactAlarm(
        alarmId: 'alm_p7_1',
        missionId: 'task_p7_1',
        scheduledAt: now,
      );

      expect(occ1.occurrenceId, equals(occ2.occurrenceId));
      expect(occ2.occurrenceId, equals(occ3.occurrenceId));
      expect(scheduler.activeCount, equals(1));
    });
  });

  group('Track P12, P14, P15 & P16: Proof Integrity, Idempotent XP, Streak & Retry Cancellation', () {
    test('P12: Proof with mismatched sha256 checksum format is rejected', () async {
      final task = LocalTask(
        id: 'task_p12_1',
        title: 'Pushups',
        category: 'PHYSICAL',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_p12_1');
      expect(
        () => missionService.submitProof(
          attempt.id,
          const ProofSubmission(
            type: 'PHOTO',
            filePath: 'habitat_storage://proofs/p12.jpg',
            sha256Checksum: 'short_hash',
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('P14, P15 & P16: Full Mission Lifecycle — XP, Streak, and Retry cancellation', () async {
      final task = LocalTask(
        id: 'task_p14_1',
        title: 'Deep Meditation',
        category: 'MIND',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_p14_1', alarmId: 'alm_p14_1');
      final occ = scheduler.scheduleExactAlarm(
        alarmId: 'alm_p14_1',
        missionId: attempt.id,
        scheduledAt: DateTime.now(),
      );

      // Submit valid proof
      await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'PHOTO',
          filePath: 'habitat_storage://proofs/meditation.jpg',
          sha256Checksum: '1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff',
        ),
      );

      // Complete mission
      final res = await missionService.complete(attempt.id);
      expect(res.isSuccess, isTrue);
      expect(res.earnedXp, equals(20));
      expect(db.getTotalXP(), equals(20));

      // Disarm scheduler
      scheduler.onMissionCompleted(occurrenceId: occ.occurrenceId);
      expect(occ.isCancelled, isTrue);

      // Idempotent secondary completion call produces 0 extra XP
      final resDuplicate = await missionService.complete(attempt.id);
      expect(resDuplicate.isSuccess, isTrue);
      expect(resDuplicate.earnedXp, equals(0));
      expect(db.getTotalXP(), equals(20));
    });
  });
}
