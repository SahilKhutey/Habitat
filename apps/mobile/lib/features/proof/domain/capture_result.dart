// Capture Result & Proof Domain Entity in Flutter
import 'proof_type.dart';

class CaptureResult {
  final String localPath;
  final ProofType type;
  final int sizeBytes;
  final Duration? duration;
  final DateTime capturedAt;
  final int width;
  final int height;

  const CaptureResult({
    required this.localPath,
    required this.type,
    required this.sizeBytes,
    this.duration,
    required this.capturedAt,
    this.width = 1920,
    this.height = 1080,
  });
}

class ProofEntity {
  final String id;
  final String missionId;
  final String? attemptId;
  final ProofType type;
  final ProofStatus status;
  final String? localPath;
  final String? objectKey;
  final String? thumbnailKey;
  final String mimeType;
  final int sizeBytes;
  final Duration? duration;
  final DateTime capturedAt;

  const ProofEntity({
    required this.id,
    required this.missionId,
    this.attemptId,
    required this.type,
    required this.status,
    this.localPath,
    this.objectKey,
    this.thumbnailKey,
    required this.mimeType,
    required this.sizeBytes,
    this.duration,
    required this.capturedAt,
  });
}
