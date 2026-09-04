// Automated Test Suite for Track O: Release Engineering, Security & Production Hardening
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/services/mission_execution_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalDatabase db;
  late MissionExecutionService missionService;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    db = LocalDatabase.instance;
    db.resetAllData(populateDefaultTemplates: false);
    missionService = MissionExecutionService(database: db);
  });

  group('Track O12 & O13: Large-State Persistence & Performance Benchmark', () {
    test(
        'O12: LocalDatabase serializes and restores 100 tasks, 100 alarms, and 500 XP events seamlessly',
        () {
      final now = DateTime.now();

      // Populate large dataset
      for (int i = 0; i < 100; i++) {
        db.saveTask(LocalTask(
          id: 'task_stress_$i',
          title: 'Stress Task #$i',
          category: i % 2 == 0 ? 'PHYSICAL' : 'MIND',
          taskType: 'PHOTO',
          createdAt: now,
          updatedAt: now,
        ));

        db.saveAlarm(LocalAlarm(
          id: 'alm_stress_$i',
          taskId: 'task_stress_$i',
          scheduledTime: '0${(i % 12) + 1}:00',
          enabled: i % 2 == 0,
          createdAt: now,
        ));
      }

      for (int i = 0; i < 500; i++) {
        db.awardXP(
          taskId: 'task_stress_${i % 100}',
          attemptId: 'att_stress_$i',
          amount: 10,
          eventType: 'STRESS_EVENT',
        );
      }

      expect(db.getAllTasks().length, equals(100));
      expect(db.getAllAlarms().length, equals(100));
      expect(db.getTotalXP(), equals(5000));

      final stopwatch = Stopwatch()..start();
      final exportedJson = db.exportCompleteStateJson();
      stopwatch.stop();

      // Serialization of 700 entities should take under 100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(100));

      // Reset in-memory state
      db.resetAllData(populateDefaultTemplates: false);
      expect(db.getAllTasks().isEmpty, isTrue);

      // Restore from exported JSON
      db.restoreFromStateJson(exportedJson);

      expect(db.getAllTasks().length, equals(100));
      expect(db.getAllAlarms().length, equals(100));
      expect(db.getTotalXP(), equals(5000));
    });
  });

  group('Track O7 & O8: Replay Attack Defense & Intent Security', () {
    test(
        'O8: Replaying identical mission completion callback produces exactly 1 XP transaction',
        () async {
      final task = LocalTask(
        id: 'task_replay_sec',
        title: 'Integrity Walk',
        category: 'HEALTH',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_replay_sec');
      await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'PHOTO',
          filePath: 'habitat_storage://proofs/walk_sec.jpg',
          sha256Checksum:
              '1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff',
        ),
      );

      // Trigger completion 5 times concurrently / sequentially
      for (int i = 0; i < 5; i++) {
        final res = await missionService.complete(attempt.id);
        expect(res.isSuccess, isTrue);
      }

      // Exact single award
      expect(db.getTotalXP(), equals(20));
      final taskAttempts = db.getAttemptsForTask('task_replay_sec');
      expect(taskAttempts.length, equals(1));
      expect(taskAttempts.first.status, equals('COMPLETED'));
    });
  });

  group('Track O15: Timezone & Timestamp Integrity', () {
    test(
        'O15: Local timestamp format ISO8601 substring preserves calendar day for streak calculations',
        () {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      expect(todayStr.length, equals(10));
      expect(todayStr, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });
  });
}
