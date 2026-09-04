// Automated Test Suite for Phase 3 / Track J7: Local Persistence Roundtrip & Schema Migrations
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';

void main() {
  group('Track J7: 14-Model Serialization & Deserialization Invariants', () {
    test('LocalUser roundtrips perfectly via toMap and fromMap', () {
      final now = DateTime.now();
      final user = LocalUser(
        id: 'usr_alex',
        displayName: 'Alex Mercer',
        bio: 'Discipline Master',
        avatarUrl: 'https://cdn.habitat.discipline/avatar.png',
        disciplineLevel: 'Master',
        timezone: 'America/New_York',
        createdAt: now,
      );

      final map = user.toMap();
      final deserialized = LocalUser.fromMap(map);

      expect(deserialized.id, equals(user.id));
      expect(deserialized.displayName, equals(user.displayName));
      expect(deserialized.bio, equals(user.bio));
      expect(deserialized.avatarUrl, equals(user.avatarUrl));
      expect(deserialized.disciplineLevel, equals(user.disciplineLevel));
      expect(deserialized.timezone, equals(user.timezone));
      expect(deserialized.createdAt.toIso8601String(),
          equals(now.toIso8601String()));
    });

    test('LocalTask roundtrips with all boolean constraints', () {
      final now = DateTime.now();
      final task = LocalTask(
        id: 'task_001',
        title: '20 Strict Pushups',
        description: 'Chest to floor form',
        category: 'PHYSICAL',
        taskType: 'VIDEO',
        difficulty: 'HARD',
        requiresPhoto: false,
        requiresVideo: true,
        requiresVerification: true,
        isCompleted: false,
        active: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = task.toMap();
      final deserialized = LocalTask.fromMap(map);

      expect(deserialized.id, equals(task.id));
      expect(deserialized.title, equals(task.title));
      expect(deserialized.description, equals(task.description));
      expect(deserialized.category, equals(task.category));
      expect(deserialized.taskType, equals(task.taskType));
      expect(deserialized.difficulty, equals(task.difficulty));
      expect(deserialized.requiresPhoto, isFalse);
      expect(deserialized.requiresVideo, isTrue);
      expect(deserialized.requiresVerification, isTrue);
      expect(deserialized.isCompleted, isFalse);
      expect(deserialized.active, isTrue);
    });

    test('LocalAlarm roundtrips with repeat days list', () {
      final now = DateTime.now();
      final alarm = LocalAlarm(
        id: 'alm_001',
        taskId: 'task_001',
        scheduledTime: '06:30',
        enabled: true,
        repeatType: 'CUSTOM',
        repeatDays: [1, 3, 5],
        retryIntervalMinutes: 3,
        maxRetries: 5,
        nextTrigger: now.add(const Duration(hours: 12)),
        createdAt: now,
      );

      final map = alarm.toMap();
      final deserialized = LocalAlarm.fromMap(map);

      expect(deserialized.id, equals(alarm.id));
      expect(deserialized.taskId, equals(alarm.taskId));
      expect(deserialized.scheduledTime, equals(alarm.scheduledTime));
      expect(deserialized.enabled, isTrue);
      expect(deserialized.repeatType, equals('CUSTOM'));
      expect(deserialized.repeatDays, equals([1, 3, 5]));
      expect(deserialized.retryIntervalMinutes, equals(3));
      expect(deserialized.maxRetries, equals(5));
      expect(deserialized.nextTrigger?.toIso8601String(),
          equals(alarm.nextTrigger?.toIso8601String()));
    });

    test('LocalProof roundtrips with file path and verified flag', () {
      final now = DateTime.now();
      final proof = LocalProof(
        id: 'prf_001',
        taskId: 'task_001',
        attemptId: 'att_001',
        type: 'VIDEO',
        localPath: 'app_storage://proofs/task_001_att_001_video.mp4',
        durationSeconds: 12,
        isVerified: true,
        createdAt: now,
      );

      final map = proof.toMap();
      final deserialized = LocalProof.fromMap(map);

      expect(deserialized.id, equals(proof.id));
      expect(deserialized.taskId, equals(proof.taskId));
      expect(deserialized.attemptId, equals(proof.attemptId));
      expect(deserialized.type, equals(proof.type));
      expect(deserialized.localPath, equals(proof.localPath));
      expect(deserialized.durationSeconds, equals(12));
      expect(deserialized.isVerified, isTrue);
    });

    test('LocalXPEvent, LocalStreak, and Health entries roundtrip', () {
      final now = DateTime.now();

      final xp = LocalXPEvent(
        id: 'xp_001',
        eventType: 'TASK_COMPLETED',
        taskId: 'task_001',
        amount: 50,
        createdAt: now,
      );
      final deserializedXp = LocalXPEvent.fromMap(xp.toMap());
      expect(deserializedXp.amount, equals(50));
      expect(deserializedXp.eventType, equals('TASK_COMPLETED'));

      final streak = LocalStreak(
        currentStreak: 7,
        longestStreak: 14,
        lastCompletedDate: '2026-09-02',
      );
      final deserializedStreak = LocalStreak.fromMap(streak.toMap());
      expect(deserializedStreak.currentStreak, equals(7));
      expect(deserializedStreak.longestStreak, equals(14));
      expect(deserializedStreak.lastCompletedDate, equals('2026-09-02'));

      final water = LocalWaterEntry(
        id: 'wtr_001',
        milliliters: 500,
        recordedAt: now,
      );
      final deserializedWater = LocalWaterEntry.fromMap(water.toMap());
      expect(deserializedWater.milliliters, equals(500));

      final meal = LocalMealEntry(
        id: 'meal_001',
        type: 'LUNCH',
        recordedAt: now,
        notes: 'High protein discipline bowl',
      );
      final deserializedMeal = LocalMealEntry.fromMap(meal.toMap());
      expect(deserializedMeal.type, equals('LUNCH'));
      expect(deserializedMeal.notes, equals('High protein discipline bowl'));

      final nap = LocalNapEntry(
        id: 'nap_001',
        startedAt: now.subtract(const Duration(minutes: 25)),
        endedAt: now,
      );
      final deserializedNap = LocalNapEntry.fromMap(nap.toMap());
      expect(deserializedNap.durationMinutes, equals(25));
      expect(deserializedNap.isRunning, isFalse);
    });
  });

  group('Track J7: Full Database Export, Restore & Migration', () {
    late LocalDatabase db;

    setUp(() {
      db = LocalDatabase.instance;
      db.resetAllData();
    });

    test(
        'exportCompleteStateJson & restoreFromStateJson preserves full app state',
        () {
      db.getOrCreateProfile(name: 'Commander');
      db.saveTask(LocalTask(
        id: 'task_custom_1',
        title: 'Cold Plunge 3min',
        category: 'DISCIPLINE',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      db.saveAlarm(LocalAlarm(
        id: 'alm_custom_1',
        taskId: 'task_custom_1',
        scheduledTime: '05:00',
        createdAt: DateTime.now(),
      ));
      db.awardXP(taskId: 'task_custom_1', amount: 100);
      db.addWater(milliliters: 750);

      final exportedJson = db.exportCompleteStateJson();
      expect(exportedJson, isNotEmpty);

      // Clear in-memory and restore from exported JSON
      db.resetAllData();
      expect(db.getAllTasks().any((t) => t.id == 'task_custom_1'), isFalse);

      db.restoreFromStateJson(exportedJson);

      expect(db.getTask('task_custom_1'), isNotNull);
      expect(db.getTask('task_custom_1')!.title, equals('Cold Plunge 3min'));
      expect(db.getAllAlarms().any((a) => a.id == 'alm_custom_1'), isTrue);
      expect(db.getTotalXP(), equals(100));
      expect(
          db
              .getWaterEntriesToday()
              .fold<int>(0, (sum, e) => sum + e.milliliters),
          equals(750));
    });

    test('Schema migration v1 -> v3 upgrades legacy records gracefully', () {
      final legacyV1Payload = jsonEncode({
        'schemaVersion': 1,
        'revision': 5,
        'tasks': [
          {
            'id': 'task_legacy_1',
            'title': 'Legacy Task',
            'category': 'HEALTH',
            'taskType': 'PHOTO',
            'requiresPhoto': 1,
            'requiresVideo': 0,
            'requiresVerification': 1,
            'isCompleted': 0,
            'active': 1,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          }
        ],
        'alarms': [
          {
            'id': 'alm_legacy_1',
            'taskId': 'task_legacy_1',
            'scheduledTime': '07:00',
            'enabled': 1,
            'repeatType': 'DAILY',
            'repeatDays': null, // V1 omitted repeatDays
            'retryIntervalMinutes': 5,
            'maxRetries': 6,
            'createdAt': DateTime.now().toIso8601String(),
          }
        ],
        'proofs': [
          {
            'id': 'prf_legacy_1',
            'taskId': 'task_legacy_1',
            'attemptId': 'att_1',
            'type': 'PHOTO',
            'localPath': 'legacy_path.jpg',
            'durationSeconds': 0,
            'isVerified': null, // V2 omitted isVerified
            'createdAt': DateTime.now().toIso8601String(),
          }
        ]
      });

      db.restoreFromStateJson(legacyV1Payload);

      final task = db.getTask('task_legacy_1');
      expect(task, isNotNull);
      expect(task!.title, equals('Legacy Task'));

      final alarm = db.getAllAlarms().firstWhere((a) => a.id == 'alm_legacy_1');
      expect(alarm.repeatDays, equals([1, 2, 3, 4, 5, 6, 7]));

      final proofs = db.getProofsForTask('task_legacy_1');
      expect(proofs, hasLength(1));
      expect(proofs.first.isVerified, isFalse);
    });
  });
}
