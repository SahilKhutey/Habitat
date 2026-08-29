// Habitat Event System & Event Ledger Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/core/events/habitat_events.dart';
import 'package:habitat_mobile/database/local_database.dart';

void main() {
  late LocalDatabase db;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
  });

  group('Event Ledger & EventBus Unit Tests', () {
    test('recordEvent() records events into append-only database ledger', () {
      db.recordEvent(
        eventType: 'TASK_COMPLETED',
        entityId: 'task_001',
        metadata: {'earnedXp': 50, 'source': 'MoveNet_Radar'},
      );

      final events = db.getRecentEvents();
      expect(events.length, equals(1));
      expect(events.first.eventType, equals('TASK_COMPLETED'));
      expect(events.first.entityId, equals('task_001'));
      expect(events.first.metadata['earnedXp'], equals(50));
    });

    test('getRecentEvents() limits returned events count', () {
      for (int i = 1; i <= 5; i++) {
        db.recordEvent(eventType: 'WATER_LOGGED', entityId: 'water_$i');
      }

      final recent = db.getRecentEvents(limit: 3);
      expect(recent.length, equals(3));
      expect(recent.first.entityId, equals('water_5'));
    });

    test('HabitatEventBus publishes events to subscribers', () async {
      final bus = HabitatEventBus.instance;
      HabitatEvent? receivedEvent;

      final sub = bus.stream.listen((event) {
        receivedEvent = event;
      });

      bus.publish(TaskCompletedEvent(taskId: 'task_abc', earnedXp: 25));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(receivedEvent, isNotNull);
      expect(receivedEvent, isA<TaskCompletedEvent>());
      expect((receivedEvent as TaskCompletedEvent).taskId, equals('task_abc'));

      await sub.cancel();
    });
  });
}
