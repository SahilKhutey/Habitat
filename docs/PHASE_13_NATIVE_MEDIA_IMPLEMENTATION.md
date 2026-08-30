# Habitat Phase 13 — Native Camera, Media & Proof Storage Architecture

## Overview
Phase 13 replaces simulated media proof placeholders with a real camera and media pipeline across Android, iOS, and Web.

## Component Structure
- `CameraService`: Native camera controller interface (`takePhoto`, `startVideoRecording`, `stopVideoRecording`, `switchCamera`).
- `ProofFileStore`: Multi-platform app-private storage engine generating SHA-256 digests.
- `ProofCameraScreen`: Full-screen viewfinder HUD with recording timer and lens flip.
- `CaptureResult`: Immutable proof envelope with file path, MIME type, byte size, duration, timestamp, and SHA-256 hash.

## Platform Permissions
- **Android**: `CAMERA`, `RECORD_AUDIO`, `WAKE_LOCK`.
- **iOS**: `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`.
- **Web**: Browser mediaDevices with session blob fallback.
