// Habitat Capture Result Domain Model
import 'package:flutter/foundation.dart';

@immutable
class CaptureResult {
  final String filePath;
  final String mimeType;
  final int byteSize;
  final String sha256Checksum;
  final int durationSeconds;
  final DateTime capturedAt;
  final bool isFrontCamera;
  final Map<String, dynamic> metadata;

  const CaptureResult({
    required this.filePath,
    required this.mimeType,
    required this.byteSize,
    required this.sha256Checksum,
    this.durationSeconds = 0,
    required this.capturedAt,
    this.isFrontCamera = false,
    this.metadata = const {},
  });

  bool get isVideo => mimeType.startsWith('video') || durationSeconds > 0;
  bool get isPhoto => !isVideo;

  Map<String, dynamic> toMap() => {
        'filePath': filePath,
        'mimeType': mimeType,
        'byteSize': byteSize,
        'sha256Checksum': sha256Checksum,
        'durationSeconds': durationSeconds,
        'capturedAt': capturedAt.toIso8601String(),
        'isFrontCamera': isFrontCamera,
        'metadata': metadata,
      };
}
