// Habitat Performance, Reliability & Recovery Coordinator (Phase 18)
import 'package:flutter/foundation.dart';
import '../../database/local_database.dart';

@immutable
class ReliabilitySnapshot {
  final int taskCount;
  final int alarmCount;
  final int attemptCount;
  final int proofCount;
  final int healthLogCount;
  final int revision;
  final DateTime lastPersist;
  final int pendingSyncCount;

  const ReliabilitySnapshot({
    required this.taskCount,
    required this.alarmCount,
    required this.attemptCount,
    required this.proofCount,
    required this.healthLogCount,
    required this.revision,
    required this.lastPersist,
    required this.pendingSyncCount,
  });

  Map<String, dynamic> toMap() => {
        'taskCount': taskCount,
        'alarmCount': alarmCount,
        'attemptCount': attemptCount,
        'proofCount': proofCount,
        'healthLogCount': healthLogCount,
        'revision': revision,
        'lastPersist': lastPersist.toIso8601String(),
        'pendingSyncCount': pendingSyncCount,
      };

  @override
  String toString() {
    return 'Habitat Reliability Snapshot\n'
        'Tasks:          $taskCount\n'
        'Alarms:         $alarmCount\n'
        'Attempts:       $attemptCount\n'
        'Proofs:         $proofCount\n'
        'Health logs:    $healthLogCount\n'
        'Revision:       $revision\n'
        'Pending sync:   $pendingSyncCount\n'
        'Last Persist:   ${lastPersist.toIso8601String()}';
  }
}

class HabitatReliabilityCoordinator {
  static ReliabilitySnapshot getSnapshot({LocalDatabase? db}) {
    final database = db ?? LocalDatabase.instance;
    return ReliabilitySnapshot(
      taskCount: database.getAllTasks().length,
      alarmCount: database.getAllAlarms().length,
      attemptCount: database.getAllAttempts().length,
      proofCount: database.getAllAttempts().fold<int>(0, (sum, a) => sum + database.getProofsForAttempt(a.id).length),
      healthLogCount: database.getAllHealthLogs().length,
      revision: database.revision,
      lastPersist: database.lastSavedAt,
      pendingSyncCount: database.getPendingSyncEvents().length,
    );
  }

  static Future<void> flush({LocalDatabase? db}) async {
    final database = db ?? LocalDatabase.instance;
    await database.flush();
  }

  static bool recover({LocalDatabase? db}) {
    final database = db ?? LocalDatabase.instance;
    return database.recoverFromBackup();
  }
}
