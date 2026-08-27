// Proof Types and Status Enums

enum ProofType {
  none,
  photo,
  video,
  photoOrVideo,
  sensor,
}

enum ProofStatus {
  localCaptured,
  localAccepted,
  processing,
  queued,
  uploading,
  uploaded,
  registered,
  submitted,
  verifying,
  accepted,
  rejected,
  uploadFailed,
  processingFailed,
  invalid,
}
