// Habitat Central Task Execution Service & Orchestrator
import '../../../../core/alarm/native_alarm_service.dart';
import '../../../../database/local_database.dart';
import '../models/action_model.dart';
import '../models/execution_model.dart';
import 'verification_service.dart';

class TaskExecutionService {
  final LocalDatabase _database;
  final VerificationService _verificationService;

  TaskExecutionService({
    required LocalDatabase database,
    VerificationService? verificationService,
  })  : _database = database,
        _verificationService = verificationService ?? VerificationService();

  TaskExecutionModel startTaskExecution({
    required String taskId,
    String? taskTitle,
  }) {
    final title =
        taskTitle ?? _database.getTask(taskId)?.title ?? 'Discipline Action';
    final task = _database.getTask(taskId);
    final attemptId = 'exec-${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now();

    _database.recordAttempt(LocalTaskAttempt(
      id: attemptId,
      taskId: taskId,
      alarmId: 'alarm-$taskId',
      attemptNumber: 1,
      status: 'AWAITING_ACTION',
      triggeredAt: now,
    ));

    return TaskExecutionModel(
      attemptId: attemptId,
      taskId: taskId,
      taskTitle: title,
      alarmId: 'alarm-$taskId',
      attemptNumber: 1,
      status: ExecutionStatus.inProgress,
      triggeredAt: now,
      proofType: task?.taskType ?? 'PHOTO',
    );
  }

  Future<TaskExecutionModel> submitProofAndVerify({
    required TaskExecutionModel execution,
    required String proofPath,
    int resistanceSeconds = 0,
  }) async {
    final now = DateTime.now();
    final isSpeedBonus = resistanceSeconds <= 120;

    // 1. Record Proof in LocalDatabase
    _database.recordProof(LocalProof(
      id: 'proof-${now.microsecondsSinceEpoch}',
      taskId: execution.taskId,
      attemptId: execution.attemptId,
      type: execution.proofType,
      localPath: proofPath,
      durationSeconds: resistanceSeconds,
      isVerified: true,
      createdAt: now,
    ));

    // 2. Run Verification Pipeline
    final verificationType = execution.proofType == 'VIDEO'
        ? VerificationType.videoProof
        : VerificationType.photoProof;

    final result = await _verificationService.verifyProof(
      taskId: execution.taskId,
      verificationType: verificationType,
      proofPath: proofPath,
      resistanceSeconds: resistanceSeconds,
    );

    if (result.isSuccess) {
      // 3. Mark Attempt Completed
      _database.updateAttemptStatus(
        attemptId: execution.attemptId,
        status: 'COMPLETED',
        completedAt: now,
      );

      final totalXp = 30 + result.bonusXp;
      _database.awardXP(
        taskId: execution.taskId,
        attemptId: execution.attemptId,
        amount: totalXp,
      );
      _database.updateStreak();

      // Stop native alarm siren if active
      await NativeAlarmService.stopSiren();

      return TaskExecutionModel(
        attemptId: execution.attemptId,
        taskId: execution.taskId,
        taskTitle: execution.taskTitle,
        alarmId: execution.alarmId,
        attemptNumber: execution.attemptNumber,
        status: ExecutionStatus.completed,
        triggeredAt: execution.triggeredAt,
        completedAt: now,
        resistanceSeconds: resistanceSeconds,
        isSpeedBonus: isSpeedBonus,
        proofPath: proofPath,
        proofType: execution.proofType,
        isVerified: true,
        xpAwarded: totalXp,
      );
    } else {
      // Failed attempt -> Trigger 5-minute escalation retry
      _database.updateAttemptStatus(
        attemptId: execution.attemptId,
        status: 'RETRY',
      );

      await NativeAlarmService.arm5MinuteRetry(
        missionId: execution.alarmId,
        taskTitle: execution.taskTitle,
        currentAttemptIndex: execution.attemptNumber,
      );

      return TaskExecutionModel(
        attemptId: execution.attemptId,
        taskId: execution.taskId,
        taskTitle: execution.taskTitle,
        alarmId: execution.alarmId,
        attemptNumber: execution.attemptNumber + 1,
        status: ExecutionStatus.retrying,
        triggeredAt: execution.triggeredAt,
        resistanceSeconds: resistanceSeconds,
        proofPath: proofPath,
        proofType: execution.proofType,
        isVerified: false,
      );
    }
  }
}
