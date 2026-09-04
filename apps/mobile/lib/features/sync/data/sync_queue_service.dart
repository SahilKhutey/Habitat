// Local Offline Sync Queue Service with Exponential Backoff
import 'dart:convert';

enum SyncItemStatus { pending, syncing, synced, failed }

class SyncQueueItem {
  final String id;
  final String type;
  final String idempotencyKey;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
  SyncItemStatus status;
  int retryAttempts;

  SyncQueueItem({
    required this.id,
    required this.type,
    required this.idempotencyKey,
    required this.timestamp,
    required this.payload,
    this.status = SyncItemStatus.pending,
    this.retryAttempts = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'idempotencyKey': idempotencyKey,
        'timestamp': timestamp.toIso8601String(),
        'payload': payload,
      };
}

class SyncQueueService {
  static final List<SyncQueueItem> _queue = [];

  static List<SyncQueueItem> get pendingItems => _queue
      .where((item) =>
          item.status == SyncItemStatus.pending ||
          item.status == SyncItemStatus.failed)
      .toList();

  static List<SyncQueueItem> get allItems => List.unmodifiable(_queue);

  static void enqueueEvent({
    required String id,
    required String type,
    required String idempotencyKey,
    required Map<String, dynamic> payload,
  }) {
    _queue.add(
      SyncQueueItem(
        id: id,
        type: type,
        idempotencyKey: idempotencyKey,
        timestamp: DateTime.now().toUtc(),
        payload: payload,
      ),
    );
  }

  static void markSynced(String idempotencyKey) {
    for (final item in _queue) {
      if (item.idempotencyKey == idempotencyKey) {
        item.status = SyncItemStatus.synced;
      }
    }
  }

  static void clearSynced() {
    _queue.removeWhere((item) => item.status == SyncItemStatus.synced);
  }
}
