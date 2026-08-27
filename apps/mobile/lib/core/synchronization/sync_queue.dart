// Offline Sync Queue Manager
import 'dart:convert';
import 'package:uuid/uuid.dart';

class SyncEvent {
  final String id;
  final String idempotencyKey;
  final String type; // 'MISSION_COMPLETED'
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  SyncEvent({
    required this.id,
    required this.idempotencyKey,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'idempotencyKey': idempotencyKey,
        'type': type,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
      };
}

class SyncQueueManager {
  static final List<SyncEvent> _queue = [];
  static const _uuid = Uuid();

  /// Enqueue completed mission during offline state
  static SyncEvent enqueueMissionCompleted({
    required String userId,
    required String taskId,
    String? alarmId,
    required String disciplineMode,
    required String storageKey,
    required DateTime capturedAt,
    Map<String, dynamic>? deviceTelemetry,
  }) {
    final idempotencyKey = _uuid.v4();
    final event = SyncEvent(
      id: _uuid.v4(),
      idempotencyKey: idempotencyKey,
      type: 'MISSION_COMPLETED',
      payload: {
        'userId': userId,
        'taskId': taskId,
        'alarmId': alarmId,
        'disciplineMode': disciplineMode,
        'storageKey': storageKey,
        'capturedAt': capturedAt.toIso8601String(),
        'idempotencyKey': idempotencyKey,
        'deviceTelemetry': deviceTelemetry ?? {},
      },
      createdAt: DateTime.now(),
    );

    _queue.add(event);
    return event;
  }

  /// Get count of pending offline events
  static int get pendingCount => _queue.length;

  /// Clear successfully synced events
  static void markSynced(List<String> idempotencyKeys) {
    _queue.removeWhere((e) => idempotencyKeys.contains(e.idempotencyKey));
  }

  /// Exports payload for /api/v1/sync/batch
  static Map<String, dynamic> buildBatchPayload() {
    return {
      'events': _queue.map((e) => e.toJson()).toList(),
    };
  }
}
