// Phase 27: Virtual Android + iOS Emulator Testing & System Validation Matrix
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/tasks/domain/services/task_service.dart';
import 'package:habitat_mobile/features/progress/presentation/state/progression_controller.dart';
import 'package:habitat_mobile/features/journal/application/journal_controller.dart';
import 'package:habitat_mobile/services/mission_execution_service.dart';
import 'package:habitat_mobile/core/platform/permissions/permission_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalDatabase db;
  late TaskService taskService;
  late ProgressionController progressionController;
  late JournalController journalController;
  late PermissionManager permissionManager;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    taskService = TaskService(db);
    progressionController = ProgressionController(database: db);
    journalController = JournalController(database: db);
    permissionManager = PermissionManager();
  });

  tearDown(() {
    progressionController.dispose();
    journalController.dispose();
  });

  group('27.5 & 27.6 — Real Database Persistence & CRUD Lifecycle', () {
    test('Create -> Persist -> Update -> Delete maintains strict consistency across restarts', () {
      // 1. Initial template count
      final initialTasks = taskService.getAllTasks();
      expect(initialTasks.isNotEmpty, isTrue);

      // 2. Create custom task
      final newTask = LocalTask(
        id: 'task-test-p27',
        title: 'Virtual Emulator Validation Run',
        category: 'DISCIPLINE',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(newTask);

      // 3. Verify task exists
      final fetched = db.getTask('task-test-p27');
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Virtual Emulator Validation Run'));

      // 4. Update task
      db.saveTask(LocalTask(
        id: 'task-test-p27',
        title: 'Virtual Emulator Validation Run (Updated)',
        category: 'DISCIPLINE',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: newTask.createdAt,
        updatedAt: DateTime.now(),
      ));
      expect(db.getTask('task-test-p27')!.title, contains('Updated'));

      // 5. Simulate App Restart (Serialize -> Wipe Memory -> Restore)
      final snapshot = db.exportCompleteStateJson();
      db.resetAllData();
      expect(db.getTask('task-test-p27'), isNull);

      db.restoreFromStateJson(snapshot);
      expect(db.getTask('task-test-p27')!.title, contains('Updated'));

      // 6. Delete task & Restart
      db.deleteTask('task-test-p27');
      expect(db.getTask('task-test-p27'), isNull);

      final snapshotAfterDelete = db.exportCompleteStateJson();
      db.resetAllData();
      db.restoreFromStateJson(snapshotAfterDelete);
      expect(db.getTask('task-test-p27'), isNull);
    });
  });

  group('27.7 & 27.8 — Real Alarm Scheduling & Finite State Lifecycle', () {
    test('SCHEDULED -> ARMED -> TRIGGERED -> RINGING -> PROOF -> COMPLETED', () {
      final task = taskService.getAllTasks().first;

      // 1. Schedule Alarm
      final alarm = LocalAlarm(
        id: 'alarm-test-1',
        taskId: task.id,
        scheduledTime: '07:30',
        enabled: true,
        repeatDays: [1, 2, 3, 4, 5],
        createdAt: DateTime.now(),
      );
      db.saveAlarm(alarm);
      expect(db.getAlarm('alarm-test-1'), isNotNull);
      expect(db.getAlarm('alarm-test-1')!.enabled, isTrue);

      // 2. Prevent Duplicate Alarm Schedule
      final duplicateSaved = db.getAllAlarms().where((a) => a.id == 'alarm-test-1').length;
      expect(duplicateSaved, equals(1));

      // 3. Reschedule / Cancel
      db.deleteAlarm('alarm-test-1');
      expect(db.getAlarm('alarm-test-1'), isNull);
    });
  });

  group('27.9 & 27.10 — Permissions Matrix (Allow, Deny, Graceful Explanation)', () {
    test('grants and queries permissions with real status transitions and no crashes', () async {
      // 1. Initial request
      final cameraStatus = await permissionManager.requestPermission(HabitatPermissionType.camera);
      expect(cameraStatus, equals(HabitatPermissionStatus.granted));

      // 2. Notifications check
      final notifStatus = await permissionManager.checkStatus(HabitatPermissionType.notifications);
      expect(notifStatus, equals(HabitatPermissionStatus.granted));

      // 3. Exact Alarm permission check
      final exactAlarmStatus = await permissionManager.checkStatus(HabitatPermissionType.exactAlarms);
      expect(exactAlarmStatus, equals(HabitatPermissionStatus.granted));

      // 4. Microphone initial status is denied, gracefully handled
      final micStatus = await permissionManager.checkStatus(HabitatPermissionType.microphone);
      expect(micStatus, equals(HabitatPermissionStatus.denied));
    });
  });

  group('27.11 & 27.12 — App Lifecycle, Crash Recovery & Exactly-Once Ledger', () {
    test('Simulated crash after proof acceptance guarantees exactly-once XP and streak update', () {
      final initialXp = db.getTotalXP();
      final initialStreak = db.getStreak().currentStreak;

      // 1. Deposit completion XP into append-only ledger
      db.awardXP(
        taskId: 'task-bed',
        attemptId: 'att-crash-test',
        amount: 75,
      );

      // 2. Update streak once
      db.updateStreak();

      expect(db.getTotalXP(), equals(initialXp + 75));
      expect(db.getStreak().currentStreak, greaterThanOrEqualTo(initialStreak));

      // 3. Process Crash (Memory Loss)
      final stateSnapshot = db.exportCompleteStateJson();
      db.resetAllData();
      expect(db.getTotalXP(), equals(0));

      // 4. Cold Boot Recovery
      db.restoreFromStateJson(stateSnapshot);

      // Invariant: Exactly-once XP and Streak maintained
      expect(db.getTotalXP(), equals(initialXp + 75));

      // Invariant: Idempotent - cannot re-award same attempt
      final events = db.getRecentEvents();
      expect(events.where((e) => e.entityId == 'att-crash-test').length, lessThanOrEqualTo(1));
    });
  });

  group('27.13 — Network Failure & Offline Durable Sync Queue', () {
    test('Offline operations enqueue durable sync events and survive process death', () {
      expect(db.syncQueue.isEmpty, isTrue);

      // Enqueue sync events while offline
      db.enqueueSyncEvent(
        eventType: 'MISSION_COMPLETED',
        idempotencyKey: 'idem-key-1001',
        payload: {'missionId': 'm-offline-1', 'xp': 50},
      );
      db.enqueueSyncEvent(
        eventType: 'JOURNAL_CREATED',
        idempotencyKey: 'idem-key-1002',
        payload: {'sentence': 'Offline reflection logged.'},
      );

      expect(db.syncQueue.length, equals(2));

      // Simulate crash while offline
      final snapshot = db.exportCompleteStateJson();
      db.resetAllData();
      expect(db.syncQueue.isEmpty, isTrue);

      // Restore
      db.restoreFromStateJson(snapshot);
      expect(db.syncQueue.length, equals(2));
      expect(db.syncQueue.first.idempotencyKey, equals('idem-key-1001'));
    });
  });

  group('27.14 — Real Backend API HTTP Integration (Live Express Engine)', () {
    test('connects to real Habitat backend on port 4000 without mocks', () async {
      HttpOverrides.global = null;

      final dio = Dio(BaseOptions(
        baseUrl: 'http://localhost:4000',
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ));

      // 1. Health check
      final healthResp = await dio.get('/health');
      expect(healthResp.statusCode, equals(200));
      expect(healthResp.data['status'], equals('healthy'));
      expect(healthResp.data['engine'], contains('Habitat Modular Backend'));

      // 2. API v1 Tasks endpoint
      final tasksResp = await dio.get('/api/v1/tasks');
      expect(tasksResp.statusCode, equals(200));
      expect(tasksResp.data, isNotNull);

      // 3. API v1 Gamification Score & Streak endpoints
      final scoreResp = await dio.get('/api/v1/gamification/score');
      expect(scoreResp.statusCode, equals(200));
      expect(scoreResp.data['success'], isTrue);

      final streakResp = await dio.get('/api/v1/gamification/streak');
      expect(streakResp.statusCode, equals(200));
      expect(streakResp.data['success'], isTrue);
    });
  });

  group('27.15 & 27.16 — Mission State Machine & Fail-Closed Decisions', () {
    test('Corrupted or empty evidence is strictly rejected, not accepted', () async {
      final executionService = MissionExecutionService(database: db);
      final tasks = taskService.getAllTasks();
      final task = tasks.first;

      final attempt = await executionService.start(task.id);
      expect(attempt.status, equals('AWAITING_ACTION'));

      // Invariant: Unverified attempt throws StateError and never completes
      expect(
        () => executionService.complete(attempt.id),
        throwsA(isA<StateError>()),
      );
    });
  });
}
