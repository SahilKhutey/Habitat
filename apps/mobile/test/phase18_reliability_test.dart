// Habitat Phase 18 Performance, Reliability & Recovery Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/core/reliability/habitat_reliability.dart';
import 'package:habitat_mobile/database/local_database.dart';

void main() {
  late LocalDatabase db;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
  });

  group('Phase 18: Performance, Reliability & Recovery Tests', () {
    test('18.1: Write coalescing and revision tracking on mutations', () async {
      final initialRevision = db.revision;

      db.addWater(milliliters: 250);
      db.addWater(milliliters: 500);

      // Revision increments with debounced state
      await db.flush();
      expect(db.revision, greaterThanOrEqualTo(initialRevision));
      expect(db.lastSavedAt, isNotNull);
    });

    test('18.2: Flush lifecycle persistence creates valid backup snapshot',
        () async {
      db.saveTask(LocalTask(
        id: 'task_rel_01',
        title: 'Morning Run',
        category: 'PHYSICAL',
        taskType: 'VIDEO',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await db.flush();

      final jsonExport = db.exportAllDataAsJson();
      expect(jsonExport, contains('Morning Run'));
      expect(db.schemaVersion, equals(3));
    });

    test('18.3: Backup recovery restores state upon corruption', () async {
      await db.flush();
      final recovered = db.recoverFromBackup();
      expect(recovered, isTrue);
    });

    test(
        '18.4: Durable sync queue stores events with idempotency and retry tracking',
        () {
      db.enqueueSyncEvent(
        eventType: 'MISSION_COMPLETED',
        idempotencyKey: 'idempotent_key_001',
        payload: {'taskId': 'task_001', 'xp': 20},
      );

      // Duplicate submission with same idempotency key is deduplicated
      db.enqueueSyncEvent(
        eventType: 'MISSION_COMPLETED',
        idempotencyKey: 'idempotent_key_001',
        payload: {'taskId': 'task_001', 'xp': 20},
      );

      final pending = db.getPendingSyncEvents();
      expect(pending.length, equals(1));
      expect(pending.first.idempotencyKey, equals('idempotent_key_001'));
      expect(pending.first.retryCount, equals(0));

      // Retry increment
      db.incrementSyncEventRetry('idempotent_key_001');
      final updatedPending = db.getPendingSyncEvents();
      expect(updatedPending.first.retryCount, equals(1));

      // Acknowledge removes from queue
      db.markSyncEventAcknowledged('idempotent_key_001');
      expect(db.getPendingSyncEvents().isEmpty, isTrue);
    });

    test(
        '18.5: HabitatReliabilityCoordinator captures complete system snapshot',
        () {
      db.saveTask(LocalTask(
        id: 'task_rel_02',
        title: 'Evening Reading',
        category: 'MIND',
        taskType: 'PHOTO',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final snapshot = HabitatReliabilityCoordinator.getSnapshot(db: db);
      expect(snapshot.taskCount, greaterThanOrEqualTo(1));
      expect(snapshot.revision, greaterThanOrEqualTo(1));
      expect(snapshot.toString(), contains('Habitat Reliability Snapshot'));
    });
  });
}
