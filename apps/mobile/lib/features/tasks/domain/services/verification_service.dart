// Habitat Verification Strategy Service
import '../models/action_model.dart';

class VerificationResult {
  final bool isSuccess;
  final String message;
  final int score;
  final int bonusXp;

  const VerificationResult({
    required this.isSuccess,
    required this.message,
    this.score = 100,
    this.bonusXp = 0,
  });
}

class VerificationService {
  Future<VerificationResult> verifyProof({
    required String taskId,
    required VerificationType verificationType,
    required String proofPath,
    int resistanceSeconds = 0,
  }) async {
    // Simulated fast local AI / Smart CV pipeline validation
    await Future.delayed(const Duration(milliseconds: 600));

    final isSpeedBonus = resistanceSeconds > 0 && resistanceSeconds <= 120;
    final bonus = isSpeedBonus ? 15 : 0;

    return switch (verificationType) {
      VerificationType.videoProof => VerificationResult(
          isSuccess: true,
          message: 'Video motion validated. Strict form accepted.',
          score: 96,
          bonusXp: bonus,
        ),
      VerificationType.photoProof => VerificationResult(
          isSuccess: true,
          message: 'Photo evidence verified cleanly.',
          score: 100,
          bonusXp: bonus,
        ),
      VerificationType.timerElapsed => VerificationResult(
          isSuccess: true,
          message: 'Duration threshold satisfied.',
          score: 100,
          bonusXp: bonus,
        ),
      VerificationType.manualConfirm || VerificationType.aiObjectDetect =>
        VerificationResult(
          isSuccess: true,
          message: 'Check-in confirmed.',
          score: 100,
          bonusXp: bonus,
        ),
    };
  }
}
