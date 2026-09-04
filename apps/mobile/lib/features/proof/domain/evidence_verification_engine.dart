// Habitat Authoritative Evidence Verification & Integrity Engine (Phase 14)
import 'package:flutter/foundation.dart';
import '../../../../database/local_database.dart';
import 'capture_result.dart';

@immutable
class EvidenceVerificationResult {
  final bool isPassed;
  final double confidenceScore;
  final List<String> failedRules;
  final String? failureMessage;
  final Map<String, dynamic> telemetry;

  const EvidenceVerificationResult({
    required this.isPassed,
    this.confidenceScore = 1.0,
    this.failedRules = const [],
    this.failureMessage,
    this.telemetry = const {},
  });

  static const EvidenceVerificationResult passed = EvidenceVerificationResult(
    isPassed: true,
    confidenceScore: 0.98,
  );

  static EvidenceVerificationResult failed({
    required List<String> rules,
    required String message,
    Map<String, dynamic> telemetry = const {},
  }) {
    return EvidenceVerificationResult(
      isPassed: false,
      confidenceScore: 0.0,
      failedRules: rules,
      failureMessage: message,
      telemetry: telemetry,
    );
  }
}

class EvidenceVerificationEngine {
  final Set<String> _seenChecksums = {};

  EvidenceVerificationEngine({Set<String>? initialChecksums}) {
    if (initialChecksums != null) {
      _seenChecksums.addAll(initialChecksums);
    }
  }

  Future<EvidenceVerificationResult> verifyEvidence(
    CaptureResult capture, {
    required LocalTask task,
    required String attemptId,
  }) async {
    final failedRules = <String>[];
    final now = DateTime.now();

    // 1. Checksum Format & Integrity Rule
    final hexRegex = RegExp(r'^[a-fA-F0-9]{64}$');
    final isChecksumValid = capture.sha256Checksum.isNotEmpty &&
        (capture.sha256Checksum.length == 64 &&
            hexRegex.hasMatch(capture.sha256Checksum));

    if (!isChecksumValid) {
      failedRules.add('INVALID_SHA256_CHECKSUM');
    }

    // 2. Anti-Replay & Duplicate Evidence Rule
    if (_seenChecksums.contains(capture.sha256Checksum)) {
      failedRules.add('DUPLICATE_PROOF_REPLAY_DETECTED');
    }

    // 3. File Byte Bounds Rule
    if (capture.byteSize <= 0) {
      failedRules.add('EMPTY_FILE_BYTES');
    } else if (capture.isPhoto && capture.byteSize < 1024) {
      failedRules.add('PHOTO_UNDERSIZED');
    } else if (capture.isVideo && capture.byteSize < 4096) {
      failedRules.add('VIDEO_UNDERSIZED');
    }

    // 4. Temporal Freshness Window Rule (10 minutes tolerance)
    final freshnessDelta = now.difference(capture.capturedAt).inSeconds;
    if (freshnessDelta > 600) {
      failedRules.add('PROOF_EXPIRED_STALE');
    } else if (freshnessDelta < -60) {
      failedRules.add('FUTURE_TIMESTAMP_DETECTED');
    }

    // 5. Video Duration Rule (Min 3.0s, Max 300s)
    if (capture.isVideo || task.requiresVideo) {
      if (capture.durationSeconds < 3) {
        failedRules.add('VIDEO_DURATION_TOO_SHORT');
      } else if (capture.durationSeconds > 300) {
        failedRules.add('VIDEO_DURATION_EXCEEDED');
      }
    }

    // 6. Task Categorical Constraint Rule
    if (task.requiresVideo && !capture.isVideo) {
      failedRules.add('REQUIRED_VIDEO_PROOF_MISSING');
    } else if (task.requiresPhoto && capture.isVideo) {
      failedRules.add('REQUIRED_PHOTO_PROOF_MISMATCH');
    }

    // Telemetry Summary
    final telemetry = {
      'checksum': capture.sha256Checksum,
      'byteSize': capture.byteSize,
      'durationSeconds': capture.durationSeconds,
      'freshnessDeltaSeconds': freshnessDelta,
      'isFrontCamera': capture.isFrontCamera,
      'rulesEvaluatedCount': 6,
      'passedCount': 6 - failedRules.length,
    };

    if (failedRules.isNotEmpty) {
      final primaryFailure = switch (failedRules.first) {
        'DUPLICATE_PROOF_REPLAY_DETECTED' =>
          'Duplicate proof detected: proof reuse rejected (replay attack prevention)',
        'VIDEO_DURATION_TOO_SHORT' =>
          'Video duration must be at least 3 seconds (got ${capture.durationSeconds}s)',
        'PROOF_EXPIRED_STALE' =>
          'Proof expired or captured outside active mission window',
        'INVALID_SHA256_CHECKSUM' => 'Invalid media integrity checksum',
        'REQUIRED_VIDEO_PROOF_MISSING' => 'Task requires motion video proof',
        _ => 'Evidence verification failed: ${failedRules.join(", ")}',
      };

      return EvidenceVerificationResult.failed(
        rules: failedRules,
        message: primaryFailure,
        telemetry: telemetry,
      );
    }

    // Register checksum into Anti-Replay Ledger
    _seenChecksums.add(capture.sha256Checksum);

    return EvidenceVerificationResult(
      isPassed: true,
      confidenceScore: 0.98,
      telemetry: telemetry,
    );
  }

  void resetAntiReplayLedger() {
    _seenChecksums.clear();
  }
}
