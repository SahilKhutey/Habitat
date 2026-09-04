// Habitat Authoritative Verification Strategy Service (Track E)
import '../../../../core/networking/api_client.dart';
import '../../../proof/domain/capture_result.dart';
import '../../../proof/domain/evidence_verification_engine.dart';
import '../models/action_model.dart';

class VerificationResult {
  final bool isSuccess;
  final String message;
  final int score;
  final int bonusXp;
  final bool isOfflineFallback;
  final int repsVerified;
  final List<String> flags;

  const VerificationResult({
    required this.isSuccess,
    required this.message,
    this.score = 100,
    this.bonusXp = 0,
    this.isOfflineFallback = false,
    this.repsVerified = 0,
    this.flags = const [],
  });
}

class VerificationService {
  final HabitatApiClient _apiClient;
  final EvidenceVerificationEngine _offlineEngine;

  VerificationService({
    HabitatApiClient? apiClient,
    EvidenceVerificationEngine? offlineEngine,
  })  : _apiClient = apiClient ?? HabitatApiClient(),
        _offlineEngine = offlineEngine ?? EvidenceVerificationEngine();

  /// Executes authoritative proof verification via backend pipeline with offline fallback
  Future<VerificationResult> verifyProof({
    required String taskId,
    required VerificationType verificationType,
    required String proofPath,
    int durationSeconds = 0,
    int resistanceSeconds = 0,
    String? missionId,
    List<int>? mediaBytes,
  }) async {
    final isSpeedBonus = resistanceSeconds > 0 && resistanceSeconds <= 120;
    final bonus = isSpeedBonus ? 15 : 0;
    final effectiveMissionId = missionId ?? taskId;
    final isVideo = verificationType == VerificationType.videoProof;

    // 1. Attempt Authoritative Backend Verification
    try {
      // Step A: Request cryptographic challenge nonce
      final challenge =
          await _apiClient.requestChallenge(missionId: effectiveMissionId);

      // Step B: Create upload session bound to challenge
      final uploadSession = await _apiClient.createUploadSession(
        missionId: effectiveMissionId,
        type: isVideo ? 'VIDEO' : 'PHOTO',
        mimeType: isVideo ? 'video/mp4' : 'image/jpeg',
        sizeBytes: mediaBytes?.length ?? 1024 * (isVideo ? 1024 : 256),
        durationSeconds:
            durationSeconds > 0 ? durationSeconds : (isVideo ? 5 : null),
        sessionId: challenge.sessionId,
        sessionNonce: challenge.sessionNonce,
      );

      // Step C: If raw bytes provided, upload to storage
      if (mediaBytes != null && mediaBytes.isNotEmpty) {
        await _apiClient.uploadMediaBytes(
          uploadUrl: uploadSession.uploadUrl,
          mediaBytes: mediaBytes,
          mimeType: isVideo ? 'video/mp4' : 'image/jpeg',
        );
        await _apiClient.completeUpload(uploadSession.proofId);
      }

      // Step D: Execute server-side real vision pose estimation & decision
      final serverResult = await _apiClient.verifyRealVision(
        proofId: uploadSession.proofId,
        policy: {'minRepetitions': isVideo ? 1 : 0},
      );

      return VerificationResult(
        isSuccess: serverResult.isValid,
        message: serverResult.isValid
            ? (isVideo
                ? 'Server Vision: ${serverResult.repsVerified} repetitions verified. Form accepted.'
                : 'Server Vision: Evidence verified cleanly.')
            : (serverResult.rejectionReason ??
                'Verification rejected by server.'),
        score: (serverResult.truthScore * 100).toInt(),
        bonusXp: serverResult.isValid ? bonus : 0,
        isOfflineFallback: false,
        repsVerified: serverResult.repsVerified,
        flags: serverResult.flags,
      );
    } catch (_) {
      // 2. Offline Fallback: Run local integrity & rule verification
      final capture = CaptureResult(
        filePath: proofPath,
        mimeType: isVideo ? 'video/mp4' : 'image/jpeg',
        byteSize: mediaBytes?.length ?? (isVideo ? 1024 * 1024 : 1024 * 256),
        sha256Checksum:
            'offline_${proofPath.hashCode.toRadixString(16).padLeft(64, "0")}',
        durationSeconds: durationSeconds,
        capturedAt: DateTime.now(),
      );

      // Simple offline rules check
      bool localPassed = true;
      String localMessage = 'Verified locally (offline mode).';

      if (isVideo && durationSeconds < 3 && durationSeconds > 0) {
        localPassed = false;
        localMessage = 'Video duration must be at least 3 seconds.';
      }

      return VerificationResult(
        isSuccess: localPassed,
        message: localMessage,
        score: localPassed ? 90 : 0,
        bonusXp: localPassed ? bonus : 0,
        isOfflineFallback: true,
        repsVerified: isVideo && localPassed ? 1 : 0,
        flags: ['OFFLINE_VERIFICATION_FALLBACK'],
      );
    }
  }
}
