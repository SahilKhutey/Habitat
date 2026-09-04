// Habitat Task Execution Service Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/tasks/domain/models/execution_model.dart';
import 'package:habitat_mobile/features/tasks/domain/services/execution_service.dart';
import 'package:habitat_mobile/features/tasks/domain/services/verification_service.dart';

void main() {
  late LocalDatabase db;
  late ExecutionServiceMockVerification verificationService;
  late TaskExecutionService executionService;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    verificationService = ExecutionServiceMockVerification();
    executionService = TaskExecutionService(
      database: db,
      verificationService: verificationService,
    );
  });

  group('TaskExecutionService Unit Tests', () {
    test('startTaskExecution() creates attempt and returns inProgress model',
        () {
      final execution = executionService.startTaskExecution(
        taskId: 'task-brush',
        taskTitle: 'Brush Teeth',
      );

      expect(execution.attemptId, startsWith('exec-'));
      expect(execution.taskId, equals('task-brush'));
      expect(execution.taskTitle, equals('Brush Teeth'));
      expect(execution.status, equals(ExecutionStatus.inProgress));

      final attempts = db.getAttemptsForTask('task-brush');
      expect(attempts, isNotEmpty);
      expect(attempts.last.status, equals('AWAITING_ACTION'));
    });

    test(
        'submitProofAndVerify() with success completes task, awards XP, and updates streak',
        () async {
      verificationService.shouldSucceed = true;

      final initialXP = db.getTotalXP();
      final execution = executionService.startTaskExecution(
        taskId: 'task-brush',
        taskTitle: 'Brush Teeth',
      );

      final result = await executionService.submitProofAndVerify(
        execution: execution,
        proofPath: '/tmp/test_proof.jpg',
        resistanceSeconds: 45, // Under 2 minutes -> speed bonus
      );

      expect(result.status, equals(ExecutionStatus.completed));
      expect(result.isVerified, isTrue);
      expect(result.isSpeedBonus, isTrue);
      expect(result.xpAwarded, equals(45)); // 30 base + 15 speed bonus

      expect(db.getTotalXP(), equals(initialXP + 45));
      expect(db.getStreak().currentStreak, greaterThanOrEqualTo(1));

      final proofs = db.getProofsForTask('task-brush');
      expect(proofs, isNotEmpty);
      expect(proofs.last.isVerified, isTrue);
    });

    test('submitProofAndVerify() with failure arms 5-minute escalation retry',
        () async {
      verificationService.shouldSucceed = false;

      final execution = executionService.startTaskExecution(
        taskId: 'task-pushups',
        taskTitle: '15 Pushups',
      );

      final result = await executionService.submitProofAndVerify(
        execution: execution,
        proofPath: '/tmp/bad_proof.mp4',
        resistanceSeconds: 30,
      );

      expect(result.status, equals(ExecutionStatus.retrying));
      expect(
          result.attemptNumber, equals(2)); // Incremented for next escalation
      expect(result.isVerified, isFalse);

      final attempts = db.getAttemptsForTask('task-pushups');
      expect(attempts.last.status, equals('RETRY'));
    });
  });
}

class ExecutionServiceMockVerification extends VerificationService {
  bool shouldSucceed = true;

  @override
  Future<VerificationResult> verifyProof({
    required String taskId,
    required dynamic verificationType,
    required String proofPath,
    int durationSeconds = 0,
    int resistanceSeconds = 0,
    String? missionId,
    List<int>? mediaBytes,
  }) async {
    final isSpeedBonus = resistanceSeconds > 0 && resistanceSeconds <= 120;
    if (shouldSucceed) {
      return VerificationResult(
        isSuccess: true,
        message: 'Verified',
        score: 100,
        bonusXp: isSpeedBonus ? 15 : 0,
      );
    } else {
      return const VerificationResult(
        isSuccess: false,
        message: 'Failed',
        score: 0,
        bonusXp: 0,
      );
    }
  }
}
