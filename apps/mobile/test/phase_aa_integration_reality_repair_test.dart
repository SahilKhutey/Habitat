// Automated Test Suite for Phase AA: Repository Reality Gap & Integration Repair
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/tasks/domain/services/alarm_service.dart';
import 'package:habitat_mobile/services/mission_execution_service.dart';
import 'package:habitat_mobile/services/native_alarm_scheduler.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalDatabase db;
  late MissionExecutionService missionService;
  late AlarmService alarmService;
  late NativeAlarmScheduler scheduler;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    db = LocalDatabase.instance;
    db.resetAllData();
    missionService = MissionExecutionService(database: db);
    alarmService = AlarmService(db);
    scheduler = NativeAlarmScheduler.instance;
    scheduler.reset();
  });

  group('Phase AA: Reality Gap Repairs & Durable Persistence (AA1, AA2, AA3)',
      () {
    test(
        'AA2: JSON export uses strict jsonEncode without string concatenation corruption',
        () {
      final user = db.getOrCreateProfile(name: 'Explorer "Pro"');
      db.updateProfile(
          displayName: 'Explorer "Pro"',
          bio: 'Line 1\nLine 2 with "quotes" and \\backslashes\\');

      final exportedAll = db.exportAllDataAsJson();
      expect(() => jsonDecode(exportedAll), returnsNormally);

      final decoded = jsonDecode(exportedAll) as Map<String, dynamic>;
      expect(decoded['version'], equals('1.0.5'));
      expect(decoded['user']['displayName'], equals('Explorer "Pro"'));
      expect(decoded['user']['bio'], contains('Line 1\nLine 2 with "quotes"'));
    });

    test(
        'AA3: Cold load restores state and preserves customized tasks over defaults',
        () async {
      final task = LocalTask(
        id: 'task_custom_user',
        title: 'Customized Morning Routine',
        category: 'DISCIPLINE',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);
      await db.flush();

      final snapshot = db.exportCompleteStateJson();
      db.resetAllData();
      expect(db.getAllTasks().length,
          greaterThan(1)); // template defaults loaded on reset

      // Simulate startup: load from disk before seeding defaults
      db.restoreFromStateJson(snapshot);
      expect(db.getTask('task_custom_user')?.title,
          equals('Customized Morning Routine'));
    });
  });

  group('Phase AA: Authoritative Completion Coordinator (AA5, AA6, AA7)', () {
    test(
        'AA6 & AA7: MissionExecutionService is the single authority for atomic completion',
        () async {
      final task = LocalTask(
        id: 'task_aa_authority',
        title: 'Tactical Pushups',
        category: 'PHYSICAL',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_aa_authority');

      // 1. Unverified completion strictly rejected
      final unverifiedRes = await missionService.complete(attempt.id);
      expect(unverifiedRes.isSuccess, isFalse);
      expect(db.getTotalXP(), equals(0));
      expect(db.getStreak().currentStreak, equals(0));

      // 2. Submit valid proof
      final proofRes = await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'PHOTO',
          filePath: 'habitat_storage://proofs/aa_pushup.jpg',
          sha256Checksum:
              '1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff',
        ),
      );
      expect(proofRes.isPassed, isTrue);

      // 3. Complete atomically
      final verifiedRes = await missionService.complete(attempt.id);
      expect(verifiedRes.isSuccess, isTrue);
      expect(verifiedRes.earnedXp, equals(20));
      expect(db.getTotalXP(), equals(20));
      expect(db.getStreak().currentStreak, equals(1));
    });
  });

  group(
      'Phase AA: Task -> Alarm -> Mission OS Synchronization (AA8, AA9, AA10)',
      () {
    test(
        'AA8 & AA9: Synchronizes persisted alarm with OS scheduler and disarms upon completion',
        () async {
      final task = LocalTask(
        id: 'task_aa_sync',
        title: 'Morning Awakening',
        category: 'DISCIPLINE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      db.saveAlarm(LocalAlarm(
        id: 'alm_aa_sync',
        taskId: 'task_aa_sync',
        scheduledTime: '06:00',
        enabled: true,
        createdAt: DateTime.now(),
      ));

      final reconciled = await alarmService.reconcilePersistedAlarmsOnStartup();
      expect(reconciled, equals(1));

      final occurrence = scheduler.scheduleExactAlarm(
        alarmId: 'alm_aa_sync',
        missionId: 'task_aa_sync',
        scheduledAt: DateTime.now(),
      );
      expect(occurrence.isDisarmed, isFalse);

      scheduler.onMissionCompleted(occurrenceId: occurrence.occurrenceId);
      expect(occurrence.isCancelled, isTrue);
    });
  });
}
