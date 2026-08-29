// Habitat Storage Info Domain Model
import 'package:flutter/foundation.dart';

@immutable
class StorageInfoModel {
  final int totalBytes;
  final int taskBytes;
  final int healthBytes;
  final int progressBytes;
  final int profileBytes;

  const StorageInfoModel({
    required this.totalBytes,
    required this.taskBytes,
    required this.healthBytes,
    required this.progressBytes,
    required this.profileBytes,
  });

  String get formattedTotal => _formatBytes(totalBytes);
  String get formattedTasks => _formatBytes(taskBytes);
  String get formattedHealth => _formatBytes(healthBytes);
  String get formattedProgress => _formatBytes(progressBytes);
  String get formattedProfile => _formatBytes(profileBytes);

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '$bytes Bytes';
    }
  }
}
