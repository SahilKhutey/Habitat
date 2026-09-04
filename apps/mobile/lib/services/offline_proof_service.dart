// Local Proof Storage & Rule-Based Validation Service
import 'package:uuid/uuid.dart';
import '../database/local_database.dart';

class OfflineProofService {
  static final OfflineProofService instance = OfflineProofService._internal();
  OfflineProofService._internal();

  /// Validates and stores local photo/video proof
  LocalProof submitLocalProof({
    required String taskId,
    required String attemptId,
    required String type, // PHOTO, VIDEO
    required String localPath,
    int durationSeconds = 0,
  }) {
    // Rule-based offline verification
    bool isValid = false;
    if (type == 'PHOTO' && localPath.isNotEmpty) {
      isValid = true;
    } else if (type == 'VIDEO' &&
        localPath.isNotEmpty &&
        durationSeconds >= 3) {
      isValid = true;
    }

    final proof = LocalProof(
      id: const Uuid().v4(),
      taskId: taskId,
      attemptId: attemptId,
      type: type,
      localPath: localPath,
      durationSeconds: durationSeconds,
      isVerified: isValid,
      createdAt: DateTime.now(),
    );

    LocalDatabase.instance.recordProof(proof);
    return proof;
  }
}
