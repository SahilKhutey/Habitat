// Anti-Cheat & Proof Heuristic Validator
import '../models/task.dart';

class VerificationResult {
  final bool isValid;
  final double confidenceScore;
  final String? rejectionReason;

  const VerificationResult({
    required this.isValid,
    this.confidenceScore = 1.0,
    this.rejectionReason,
  });
}

class AntiCheatValidator {
  static VerificationResult validateProof({
    required DateTime capturedAt,
    required Map<String, dynamic> deviceTelemetry,
    required Task task,
    DateTime? submissionTime,
  }) {
    final now = submissionTime ?? DateTime.now();
    final ageSeconds = (now.difference(capturedAt).inSeconds).abs();

    // 1. Freshness Check: Must be captured within last 3 minutes
    if (ageSeconds > 180) {
      return const VerificationResult(
        isValid: false,
        confidenceScore: 0.1,
        rejectionReason: 'Proof timestamp indicates media was captured too long ago. Fresh capture required.',
      );
    }

    // 2. Minimum Illumination Check (Ambient Lux)
    final minLux = task.validationRules['minLuminance'] as num?;
    final ambientLux = deviceTelemetry['ambientLux'] as num?;
    if (minLux != null && ambientLux != null) {
      if (ambientLux < minLux) {
        return VerificationResult(
          isValid: false,
          confidenceScore: 0.2,
          rejectionReason: 'Scene is too dark ($ambientLux lux). Turn on lights or step into morning sunlight.',
        );
      }
    }

    // 3. Motion Telemetry for Exercise Tasks
    if (task.category == TaskCategory.physical) {
      final hasMotion = deviceTelemetry['accelerometerMotion'] as bool?;
      if (hasMotion == false) {
        return const VerificationResult(
          isValid: false,
          confidenceScore: 0.3,
          rejectionReason: 'No physical device motion detected during exercise task capture.',
        );
      }
    }

    return const VerificationResult(isValid: true, confidenceScore: 0.95);
  }
}
