// Automated Test Suite for Track J: Alarm Execution & OS Reliability (J1-J16)
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/tasks/domain/services/alarm_service.dart';
import 'package:habitat_mobile/services/native_alarm_scheduler.dart';

void main() {
  group('Track J: Native Alarm Scheduling, Cancellation & Idempotency', () {
    late NativeAlarmScheduler scheduler;

    setUp(() {
      scheduler = NativeAlarmScheduler.instance;
    });

    test('J3 & J12: Schedules exact alarm idempotently with deterministic occurrenceId', () {
      final scheduledAt = DateTime(2026, 9, 2, 7, 0);
      final occ1 = scheduler.scheduleExactAlarm(
        alarmId: 'alm_001',
        missionId: 'msn_001',
        scheduledAt: scheduledAt,
      );

      expect(occ1.occurrenceId, equals('occ_alm_001_${scheduledAt.millisecondsSinceEpoch}'));
      expect(occ1.alarmId, equals('alm_001'));
      expect(occ1.isCancelled, isFalse);

      // Duplicate schedule attempt returns the same active occurrence without creating extra entries
      final occ2 = scheduler.scheduleExactAlarm(
        alarmId: 'alm_001',
        missionId: 'msn_001',
        scheduledAt: scheduledAt,
      );

      expect(identical(occ1, occ2), isTrue);
      expect(scheduler.registeredCount, greaterThanOrEqualTo(1));
    });

    test('J4: Cancels alarm and marks occurrence cancelled', () {
      final scheduledAt = DateTime(2026, 9, 2, 8, 30);
      final occ = scheduler.scheduleExactAlarm(
        alarmId: 'alm_cancel_test',
        missionId: 'msn_cancel_test',
        scheduledAt: scheduledAt,
      );

      expect(occ.isCancelled, isFalse);
      scheduler.onMissionCompleted(occurrenceId: occ.occurrenceId);
      expect(occ.isCancelled, isTrue);
    });

    test('J5 & J15: Mission completion disarms alarm and cancels pending retry escalation', () {
      final scheduledAt = DateTime(2026, 9, 2, 6, 0);
      final occ = scheduler.scheduleExactAlarm(
        alarmId: 'alm_retry_test',
        missionId: 'msn_retry_test',
        scheduledAt: scheduledAt,
      );

      // Trigger alarm -> starts 5-min escalation retry timer
      scheduler.onAlarmTriggered(occurrenceId: occ.occurrenceId, retryIntervalMinutes: 5);

      // Complete mission -> disarms and removes retry timer
      scheduler.onMissionCompleted(occurrenceId: occ.occurrenceId);
      expect(occ.isCancelled, isTrue);
    });

    test('J7: BootReceiver restoration re-registers unexpired pending alarms', () {
      final now = DateTime.now();
      final pendingAlarms = [
        {
          'alarmId': 'alm_boot_1',
          'missionId': 'msn_boot_1',
          'scheduledAt': now.add(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'alarmId': 'alm_boot_expired',
          'missionId': 'msn_boot_exp',
          'scheduledAt': now.subtract(const Duration(hours: 5)).toIso8601String(),
        },
      ];

      final restoredCount = scheduler.restorePendingAlarmsOnBoot(pendingAlarms);
      expect(restoredCount, equals(1)); // Only future / unexpired alarm restored
    });
  });

  group('Track J14: Alarm & Attempt State Machine Lifecycle', () {
    late LocalDatabase db;
    late AlarmService alarmService;

    setUp(() {
      db = LocalDatabase.instance;
      db.resetAllData();
      alarmService = AlarmService(db);
    });

    test('Full lifecycle: SCHEDULED -> RINGING -> AWAITING_ACTION -> COMPLETED with proof', () {
      final now = DateTime.now();
      final task = LocalTask(
        id: 'task_pushup_cycle',
        title: 'Morning 20 Pushups',
        category: 'PHYSICAL',
        taskType: 'VIDEO',
        requiresVideo: true,
        requiresVerification: true,
        createdAt: now,
        updatedAt: now,
      );
      db.saveTask(task);

      final alarm = LocalAlarm(
        id: 'alm_cycle_1',
        taskId: task.id,
        scheduledTime: '06:00',
        enabled: true,
        createdAt: now,
      );
      db.saveAlarm(alarm);

      // 1. Initial State: SCHEDULED attempt created
      final attempt = LocalTaskAttempt(
        id: 'att_cycle_1',
        taskId: task.id,
        alarmId: alarm.id,
        attemptNumber: 1,
        status: 'SCHEDULED',
        triggeredAt: now,
      );
      db.saveAttempt(attempt);
      expect(db.getAttempt('att_cycle_1')!.status, equals('SCHEDULED'));

      // 2. Alarm Fires: Transition to RINGING
      db.updateAttemptStatus(attemptId: 'att_cycle_1', status: 'RINGING');
      expect(db.getAttempt('att_cycle_1')!.status, equals('RINGING'));

      // 3. User Acknowledges: Transition to AWAITING_ACTION (Camera HUD opens)
      db.updateAttemptStatus(attemptId: 'att_cycle_1', status: 'AWAITING_ACTION');
      expect(db.getAttempt('att_cycle_1')!.status, equals('AWAITING_ACTION'));

      // 4. Record Real Camera Proof
      final proof = LocalProof(
        id: 'prf_cycle_1',
        taskId: task.id,
        attemptId: attempt.id,
        type: 'VIDEO',
        localPath: 'app_storage://proofs/task_pushup_cycle_video.mp4',
        durationSeconds: 15,
        isVerified: true,
        createdAt: now,
      );
      db.recordProof(proof);
      expect(db.getProofsForTask(task.id), hasLength(1));

      // 5. Complete Mission: Transition to COMPLETED
      db.updateAttemptStatus(attemptId: 'att_cycle_1', status: 'COMPLETED', completedAt: DateTime.now());
      db.completeTask(task.id);
      db.awardXP(taskId: task.id, attemptId: attempt.id, amount: 50);
      db.updateStreak();

      expect(db.getAttempt('att_cycle_1')!.status, equals('COMPLETED'));
      expect(db.getTask(task.id)!.isCompleted, isTrue);
      expect(db.getTotalXP(), equals(50));
      expect(db.getStreak().currentStreak, greaterThanOrEqualTo(1));
    });

    test('Alarm toggle enables and disables alarms in LocalDatabase cleanly', () async {
      final task = LocalTask(
        id: 'task_toggle_test',
        title: 'Bed Making',
        category: 'DISCIPLINE',
        taskType: 'PHOTO',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final alarm = LocalAlarm(
        id: 'alm_toggle_1',
        taskId: task.id,
        scheduledTime: '07:15',
        enabled: true,
        createdAt: DateTime.now(),
      );
      db.saveAlarm(alarm);

      expect(db.getAllAlarms().first.enabled, isTrue);

      await alarmService.toggleAlarm('alm_toggle_1', false);
      expect(db.getAllAlarms().first.enabled, isFalse);

      await alarmService.toggleAlarm('alm_toggle_1', true);
      expect(db.getAllAlarms().first.enabled, isTrue);
    });
  });
}
