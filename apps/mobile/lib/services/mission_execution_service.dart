// Habitat Mission Execution Orchestration Service
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/events/habitat_events.dart';
import '../core/platform/alarm/platform_alarm_service.dart';
import '../core/platform/media/native_camera_proof_pipeline.dart';
import '../database/local_database.dart';
import '../features/proof/domain/capture_result.dart';
import '../features/proof/domain/evidence_verification_engine.dart';

@immutable
class ProofSubmission {
  final String type; // PHOTO or VIDEO
  final String filePath;
  final String sha256Checksum;
  final int durationSeconds;

  const ProofSubmission({
    required this.type,
    required this.filePath,
    required this.sha256Checksum,
    this.durationSeconds = 0,
  });
}

@immutable
class MissionCompletionResult {
  final bool isSuccess;
  final int earnedXp;
  final int currentStreak;
  final String? message;

  const MissionCompletionResult({
    required this.isSuccess,
    this.earnedXp = 0,
    this.currentStreak = 0,
    this.message,
  });
}

class MissionExecutionService {
  final LocalDatabase _database;
  final EvidenceVerificationEngine _verificationEngine;
  final PlatformAlarmService _alarmService;

  MissionExecutionService({
    required LocalDatabase database,
    EvidenceVerificationEngine? verificationEngine,
    PlatformAlarmService? alarmService,
  })  : _database = database,
        _verificationEngine = verificationEngine ?? EvidenceVerificationEngine(),
        _alarmService = alarmService ?? PlatformAlarmService.create();

  Future<LocalTaskAttempt> start(String taskId, {String? alarmId}) async {
    final task = _database.getTask(taskId);
    if (task == null) throw ArgumentError('Task not found: $taskId');

    final existingAttempts = _database.getAttemptsForTask(taskId);
    final attemptNumber = existingAttempts.length + 1;

    final attempt = LocalTaskAttempt(
      id: 'attempt_${const Uuid().v4()}',
      taskId: taskId,
      alarmId: alarmId ?? '',
      attemptNumber: attemptNumber,
      status: 'AWAITING_ACTION',
      triggeredAt: DateTime.now(),
    );

    _database.saveAttempt(attempt);
    _database.recordEvent(
      eventType: 'MISSION_STARTED',
      entityId: taskId,
      metadata: {'attemptId': attempt.id, 'attemptNumber': attemptNumber},
    );

    return attempt;
  }

  Future<VerificationResult> submitProof(
    String attemptId,
    ProofSubmission submission,
  ) async {
    final attempt = _database.getAttempt(attemptId);
    if (attempt == null) throw ArgumentError('Attempt not found: $attemptId');

    final task = _database.getTask(attempt.taskId);
    if (task == null) throw ArgumentError('Task not found: ${attempt.taskId}');

    _database.updateAttemptStatus(attemptId: attemptId, status: 'VERIFYING');

    final capture = CaptureResult(
      filePath: submission.filePath,
      mimeType: submission.type == 'VIDEO' ? 'video/mp4' : 'image/jpeg',
      byteSize: submission.type == 'VIDEO' ? 1024 * 1024 : 1024 * 256,
      sha256Checksum: submission.sha256Checksum,
      durationSeconds: submission.durationSeconds,
      capturedAt: DateTime.now(),
    );

    final verification = await _verificationEngine.verifyEvidence(
      capture,
      task: task,
      attemptId: attemptId,
    );

    final proof = LocalProof(
      id: 'proof_${const Uuid().v4()}',
      taskId: attempt.taskId,
      attemptId: attemptId,
      type: submission.type,
      localPath: submission.filePath,
      durationSeconds: submission.durationSeconds,
      isVerified: verification.isPassed,
      createdAt: DateTime.now(),
    );

    _database.saveProof(proof);

    if (verification.isPassed) {
      _database.updateAttemptStatus(attemptId: attemptId, status: 'PROOF_VERIFIED');
    } else {
      _database.updateAttemptStatus(attemptId: attemptId, status: 'FAILED');
    }

    return VerificationResult(
      isPassed: verification.isPassed,
      confidenceScore: verification.confidenceScore,
      failureReason: verification.failureMessage,
      details: verification.telemetry,
    );
  }

  Future<MissionCompletionResult> complete(String attemptId) async {
    final attempt = _database.getAttempt(attemptId);
    if (attempt == null) throw ArgumentError('Attempt not found: $attemptId');

    // 1. Mark Attempt as Completed
    _database.updateAttemptStatus(
      attemptId: attemptId,
      status: 'COMPLETED',
      completedAt: DateTime.now(),
    );

    // 2. Mark Task as Completed in Database
    _database.completeTask(attempt.taskId);

    // 3. Award XP (+20 XP standard mission bonus)
    const missionXp = 20;
    _database.awardXP(
      taskId: attempt.taskId,
      attemptId: attemptId,
      amount: missionXp,
      eventType: 'MISSION_COMPLETED',
    );

    // 4. Advance Streak
    _database.updateStreak();

    // 5. Silence / Cancel Native Siren & Alarm
    if (attempt.alarmId.isNotEmpty) {
      await _alarmService.cancel(attempt.alarmId);
    }

    // 6. Record Event in Ledger
    _database.recordEvent(
      eventType: 'MISSION_COMPLETED',
      entityId: attempt.taskId,
      metadata: {'attemptId': attemptId, 'earnedXp': missionXp},
    );

    HabitatEventBus.instance.publish(
      TaskCompletedEvent(taskId: attempt.taskId, earnedXp: missionXp),
    );

    final streak = _database.getStreak();
    return MissionCompletionResult(
      isSuccess: true,
      earnedXp: missionXp,
      currentStreak: streak.currentStreak,
      message: 'Mission verified and completed!',
    );
  }

  Future<void> fail(String attemptId, {String? reason}) async {
    _database.updateAttemptStatus(
      attemptId: attemptId,
      status: 'FAILED',
      completedAt: DateTime.now(),
    );

    final attempt = _database.getAttempt(attemptId);
    if (attempt != null) {
      _database.recordEvent(
        eventType: 'MISSION_FAILED',
        entityId: attempt.taskId,
        metadata: {'attemptId': attemptId, 'reason': reason ?? 'Verification failed'},
      );
    }
  }
}
