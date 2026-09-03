// Phase 26: Real UI Integration & Mock Data Elimination Test Suite
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/tasks/application/task_controller.dart';
import 'package:habitat_mobile/features/tasks/domain/repositories/task_repository.dart';
import 'package:habitat_mobile/features/tasks/domain/services/task_service.dart';
import 'package:habitat_mobile/features/progress/presentation/state/progression_controller.dart';
import 'package:habitat_mobile/features/journal/application/journal_controller.dart';
import 'package:habitat_mobile/services/mission_execution_service.dart';

void main() {
  late LocalDatabase db;
  late TaskRepository taskRepo;
  late TaskService taskService;
  late TaskController taskController;
  late ProgressionController progressionController;
  late JournalController journalController;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    taskRepo = TaskRepository(db);
    taskService = TaskService(taskRepo);
    taskController = TaskController(taskService: taskService, database: db);
    progressionController = ProgressionController(database: db);
    journalController = JournalController(database: db);
  });

  tearDown(() {
    taskController.dispose();
    progressionController.dispose();
    journalController.dispose();
  });

  group('Phase 26.1 - Real Task Controller & Persistence', () {
    test('loads real tasks from LocalDatabase and updates on filter change', () {
      taskController.load();
      expect(taskController.tasks.isNotEmpty, isTrue);
      final initialCount = taskController.tasks.length;

      // Filter by EXERCISE
      taskController.setFilter('EXERCISE');
      expect(taskController.tasks.every((t) => t.category == 'EXERCISE'), isTrue);

      // Back to ALL
      taskController.setFilter('ALL');
      expect(taskController.tasks.length, equals(initialCount));
    });

    test('pausing and resuming tasks persists state in LocalDatabase', () {
      final task = taskService.getAllTasks().first;
      expect(task.active, isTrue);

      taskController.pauseTask(task.id);
      final pausedTask = db.getTask(task.id);
      expect(pausedTask?.active, isFalse);

      taskController.resumeTask(task.id);
      final resumedTask = db.getTask(task.id);
      expect(resumedTask?.active, isTrue);
    });
  });

  group('Phase 26.2 - Real Progression & XP Event Ledger', () {
    test('XP balance derives strictly from sum of ledger events, not fake UI counters', () {
      expect(progressionController.xpBalance, equals(0));
      expect(progressionController.level, equals(1));

      // Deposit XP via append-only ledger
      db.awardXP(taskId: 'task-pushups', attemptId: 'att-1', amount: 50);
      expect(progressionController.xpBalance, equals(50));
      expect(progressionController.level, equals(1));

      // Deposit 400 more XP (total 450) -> level 3: floor(sqrt(450/100)) + 1 = 3
      db.awardXP(taskId: 'task-outside', attemptId: 'att-2', amount: 400);
      expect(progressionController.xpBalance, equals(450));
      expect(progressionController.level, equals(3));
    });

    test('grace token consumption decrements vault cleanly', () {
      expect(progressionController.graceTokens, equals(1));

      final used = progressionController.useGraceToken();
      expect(used, isTrue);
      expect(progressionController.graceTokens, equals(0));

      // Second attempt with 0 tokens fails
      final secondUse = progressionController.useGraceToken();
      expect(secondUse, isFalse);
    });
  });

  group('Phase 26.3 - Real Daily Journal Persistence', () {
    test('saves, reads, and deletes reflections in LocalDatabase', () {
      final today = DateTime.now();
      expect(journalController.hasEntryForToday, isFalse);

      journalController.saveEntry(
        date: today,
        sentence: 'Maintained 100% mission discipline without hesitation.',
        emoji: '🔥',
        rating: 5,
      );

      expect(journalController.hasEntryForToday, isTrue);
      final entry = journalController.getEntryForDay(today);
      expect(entry, isNotNull);
      expect(entry!.sentence, contains('100% mission discipline'));
      expect(entry.emoji, equals('🔥'));
      expect(entry.rating, equals(5));

      journalController.deleteEntry(entry.id);
      expect(journalController.hasEntryForToday, isFalse);
    });
  });

  group('Phase 26.4 - Mission Completion Boundary (No Synthetic Completion)', () {
    test('mission cannot be marked completed without proof verification', async () {
      final executionService = MissionExecutionService(database: db);
      final tasks = taskService.getAllTasks();
      final task = tasks.first;

      final attempt = await executionService.start(task.id);
      expect(attempt.status, equals('IN_PROGRESS'));

      // Attempt cannot complete directly without proof verification
      final res = await executionService.complete(attempt.id);
      expect(res.isCompleted, isFalse);
      expect(res.earnedXp, equals(0));

      final attemptInDb = db.getAttempt(attempt.id);
      expect(attemptInDb?.status, isNot('COMPLETED'));
    });
  });

  group('Phase 26.5 - State Durability & Restart Recovery', () {
    test('all real state survives database serialization and restore', () {
      // 1. Create real state
      db.updateProfile(displayName: 'Commander Vanguard', bio: 'Discipline is destiny.');
      db.awardXP(taskId: 'task-1', attemptId: 'att-1', amount: 150);
      db.saveJournalEntry(LocalJournalEntry(
        id: 'journal-durable-1',
        date: DateTime(2026, 9, 3),
        sentence: 'Durable discipline execution verified.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // 2. Export complete snapshot
      final snapshot = db.exportCompleteStateJson();
      expect(snapshot.isNotEmpty, isTrue);

      // 3. Reset database (simulating app process death)
      db.resetAllData();
      expect(db.getTotalXP(), equals(0));

      // 4. Restore state snapshot (simulating app cold boot)
      db.restoreFromStateJson(snapshot);

      // 5. Verify durability
      final restoredProfile = db.getOrCreateProfile();
      expect(restoredProfile.displayName, equals('Commander Vanguard'));
      expect(db.getTotalXP(), equals(150));

      final restoredJournal = db.getJournalEntryForDay(DateTime(2026, 9, 3));
      expect(restoredJournal, isNotNull);
      expect(restoredJournal!.sentence, equals('Durable discipline execution verified.'));
    });
  });
}
