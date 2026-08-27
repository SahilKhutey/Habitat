// Domain Proof Models & Policies
enum ProofType { photo, video, manualConfirmation }

enum ProofStatus {
  capturing,
  captured,
  uploadPending,
  uploading,
  uploaded,
  validating,
  accepted,
  rejected,
  deleted,
}

class ProofPolicy {
  final ProofType type;
  final bool required;
  final bool allowCamera;
  final bool allowGallery;
  final int minimumDurationSeconds;
  final int maximumDurationSeconds;
  final int maxFileSizeBytes;
  final String preferredCamera; // "FRONT" | "BACK"

  const ProofPolicy({
    required this.type,
    this.required = true,
    this.allowCamera = true,
    this.allowGallery = false,
    this.minimumDurationSeconds = 10,
    this.maximumDurationSeconds = 60,
    this.maxFileSizeBytes = 100 * 1024 * 1024,
    this.preferredCamera = 'FRONT',
  });
}

class ProofModel {
  final String id;
  final String missionId;
  final ProofType type;
  final ProofStatus status;
  final String? localFilePath;
  final String? remoteStorageKey;
  final String? rejectionReason;
  final DateTime capturedAt;

  ProofModel({
    required this.id,
    required this.missionId,
    required this.type,
    required this.status,
    this.localFilePath,
    this.remoteStorageKey,
    this.rejectionReason,
    required this.capturedAt,
  });
}
