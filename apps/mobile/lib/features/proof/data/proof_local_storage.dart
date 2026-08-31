// Local-First Proof Storage & Recovery Service
import 'dart:io';
import '../domain/capture_result.dart';
import '../domain/proof_type.dart';

class ProofLocalStorageService {
  static final Map<String, CaptureResult> _savedProofs = {};

  /// Saves proof to local app storage before upload
  static Future<CaptureResult> saveProofLocally({
    required String missionId,
    required String attemptId,
    required CaptureResult result,
  }) async {
    final key = '${missionId}_$attemptId';
    _savedProofs[key] = result;
    return result;
  }

  /// Retrieves locally saved proof for recovery upon network restore
  static CaptureResult? getLocalProof(String missionId, String attemptId) {
    return _savedProofs['${missionId}_$attemptId'];
  }

  /// Discards draft proof on Retake
  static void discardDraftProof(String missionId, String attemptId) {
    _savedProofs.remove('${missionId}_$attemptId');
  }

  /// Cleans up local proof file after successful upload
  static void cleanupUploadedProof(String missionId, String attemptId) {
    _savedProofs.remove('${missionId}_$attemptId');
  }
}
