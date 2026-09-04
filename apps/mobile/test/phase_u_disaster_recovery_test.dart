// Automated Test Suite for Phase U: Disaster Recovery, Data Integrity & Upgrade/Migration Certification
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/tasks/domain/services/alarm_service.dart';
import 'package:habitat_mobile/services/mission_execution_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalDatabase db;
  late MissionExecutionService missionService;
  late AlarmService alarmService;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    db = LocalDatabase.instance;
    db.resetAllData(populateDefaultTemplates: false);
    missionService = MissionExecutionService(database: db);
    alarmService = AlarmService(db);
  });

  group('Phase U: Versioned Schema Migrations (U2, U3, U4, U21, U23)', () {
    test(
        'U2 & U3: Migrates Schema V1 payload to Current Schema V3 without data loss',
        () {
      final v1Payload = jsonEncode({
        'version': 1,
        'user': {
          'id': 'user_v1',
          'displayName': 'Veteran Explorer',
          'timezone': 'UTC',
          'createdAt': '2026-08-01T06:00:00.000Z',
        },
        'tasks': [
          {
            'id': 'task_v1_1',
            'title': 'Morning Sun Salutation',
            'category': 'PHYSICAL',
            'taskType': 'VIDEO',
            'createdAt': '2026-08-01T06:00:00.000Z',
            'updatedAt': '2026-08-01T06:00:00.000Z',
          }
        ],
        'alarms': [
          {
            'id': 'alm_v1_1',
            'taskId': 'task_v1_1',
            'scheduledTime': '06:15',
            'enabled': true,
            'createdAt': '2026-08-01T06:00:00.000Z',
          }
        ],
        'streak': {
          'currentStreak': 14,
          'longestStreak': 20,
          'lastCompletedDate': '2026-08-15',
        },
        'xpEvents': [
          {
            'id': 'xp_v1_1',
            'eventType': 'MISSION_COMPLETED',
            'taskId': 'task_v1_1',
            'amount': 20,
            'createdAt': '2026-08-15T06:20:00.000Z',
          }
        ],
      });

      db.restoreFromStateJson(v1Payload);

      // Invariant U4 Checks
      expect(db.schemaVersion, equals(3));
      expect(db.getTask('task_v1_1')?.title, equals('Morning Sun Salutation'));
      expect(db.getAlarmsForTask('task_v1_1').length, equals(1));
      expect(db.getStreak().currentStreak, equals(14));
      expect(db.getTotalXP(), equals(20));
      expect(db.getOrCreateProfile().displayName, equals('Veteran Explorer'));
    });

    test('U23: Migration is strictly idempotent', () {
      final stateSnapshot = db.exportCompleteStateJson();

      // First restore
      db.restoreFromStateJson(stateSnapshot);
      final tasksCount1 = db.getAllTasks().length;

      // Second restore with same payload
      db.restoreFromStateJson(stateSnapshot);
      final tasksCount2 = db.getAllTasks().length;

      expect(tasksCount1, equals(tasksCount2));
    });
  });

  group('Phase U: Backup & Corruption Recovery Matrix (U8, U9, U10)', () {
    test('U9: Recovers from backup snapshot when primary state is corrupted',
        () async {
      final task = LocalTask(
        id: 'task_disaster_backup',
        title: 'Deep Meditation',
        category: 'MIND',
        taskType: 'PHOTO',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);
      await db.flush();

      expect(db.getTask('task_disaster_backup'), isNotNull);

      // Simulate primary corruption with corrupted JSON
      const corruptedJson =
          '{"version": 3, "tasks": [{"id": "broken", "title": truncated';
      db.restoreFromStateJson(corruptedJson);

      // Trigger backup recovery
      final recovered = db.recoverFromBackup();
      expect(recovered, isTrue);
      expect(
          db.getTask('task_disaster_backup')?.title, equals('Deep Meditation'));
    });

    test(
        'U10: Handles empty, truncated, or unknown fields gracefully without crashing',
        () {
      expect(() => db.restoreFromStateJson(''), returnsNormally);
      expect(
          () => db.restoreFromStateJson('{ "unknown_future_field": [1,2,3] }'),
          returnsNormally);
      expect(
          () => db.restoreFromStateJson(
              '{ "tasks": null, "streak": "invalid_type" }'),
          returnsNormally);
    });
  });

  group('Phase U: Referential Integrity & Duplicate Detection (U11, U12, U14)',
      () {
    test(
        'U11 & U14: Interrupted or duplicate XP/Streak awards are strictly deduplicated',
        () async {
      final task = LocalTask(
        id: 'task_u_idempotency',
        title: '15 Diamond Pushups',
        category: 'PHYSICAL',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_u_idempotency');

      await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'PHOTO',
          filePath: 'habitat_storage://proofs/u_proof.jpg',
          sha256Checksum:
              '1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff',
        ),
      );

      // First completion
      final res1 = await missionService.complete(attempt.id);
      expect(res1.isSuccess, isTrue);
      expect(res1.earnedXp, equals(20));
      expect(db.getTotalXP(), equals(20));

      // Simulate interrupted restart & second completion invocation
      final res2 = await missionService.complete(attempt.id);
      expect(res2.isSuccess, isTrue);
      expect(res2.earnedXp, equals(0)); // 0 duplicate XP awarded
      expect(db.getTotalXP(), equals(20));

      // Streak incremented exactly once
      expect(db.getStreak().currentStreak, equals(1));
    });
  });

  group('Phase U: Full Disaster Scenario Certification (U24)', () {
    test(
        'U24: Full Disaster Cycle — Old state -> Active mission -> Corrupted disk -> Restore -> Intact state',
        () async {
      // 1. Seed historical state
      final task = LocalTask(
        id: 'task_disaster_full',
        title: 'Full Disaster Drill',
        category: 'DISCIPLINE',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      db.saveAlarm(LocalAlarm(
        id: 'alm_disaster_full',
        taskId: 'task_disaster_full',
        scheduledTime: '06:30',
        enabled: true,
        createdAt: DateTime.now(),
      ));

      // 2. Complete Mission with Proof
      final attempt = await missionService.start('task_disaster_full',
          alarmId: 'alm_disaster_full');
      await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'PHOTO',
          filePath: 'habitat_storage://proofs/disaster_proof.jpg',
          sha256Checksum:
              '9999888877776666555544443333222211110000aaaabbbbccccddddeeeeffff',
        ),
      );
      final completion = await missionService.complete(attempt.id);
      expect(completion.isSuccess, isTrue);
      expect(db.getTotalXP(), equals(20));

      // 3. Persist and simulate disk snapshot
      await db.flush();
      final validSnapshot = db.exportCompleteStateJson();

      // 4. Simulate crash & corruption
      db.resetAllData(populateDefaultTemplates: false);
      db.restoreFromStateJson('{"corrupted": true}');

      // 5. Restore from snapshot
      db.restoreFromStateJson(validSnapshot);

      // 6. Verify full referential integrity
      expect(db.getTask('task_disaster_full')?.isCompleted, isTrue);
      expect(db.getTotalXP(), equals(20));
      expect(db.getStreak().currentStreak, equals(1));
      expect(db.getProofsForTask('task_disaster_full').length, equals(1));
      expect(
          db.getProofsForTask('task_disaster_full').first.isVerified, isTrue);
    });
  });
}
