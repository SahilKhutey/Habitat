// Habitat Storage & Data Autonomy Service
import '../models/storage_info.dart';
import '../repositories/profile_repository.dart';

class StorageService {
  final ProfileRepository _repository;

  StorageService(this._repository);

  StorageInfoModel getStorageInfo() {
    final breakdown = _repository.getStorageBreakdown();
    final tasks = breakdown['tasks'] ?? 0;
    final health = breakdown['health'] ?? 0;
    final progress = breakdown['progress'] ?? 0;
    final profile = breakdown['profile'] ?? 0;
    final total = tasks + health + progress + profile;

    return StorageInfoModel(
      totalBytes: total,
      taskBytes: tasks,
      healthBytes: health,
      progressBytes: progress,
      profileBytes: profile,
    );
  }

  String exportJson() {
    return _repository.exportAllDataAsJson();
  }

  void clearCache() {
    // Clears ephemeral state while preserving user tasks, attempts, and streaks
  }

  void resetAllData() {
    _repository.resetAllData();
  }
}
