// Local Data Export, Import & Diagnostics Service
import 'dart:convert';
import '../database/local_database.dart';

class ExportService {
  static final ExportService instance = ExportService._internal();
  ExportService._internal();

  /// Generates a diagnostic report containing app stats, task counts, and error logs
  String generateDiagnosticReport() {
    final db = LocalDatabase.instance;
    return jsonEncode({
      'appVersion': '1.0.0-mvp.1',
      'appMode': 'offlineMvp',
      'generatedAt': DateTime.now().toIso8601String(),
      'totalTasks': db.getAllTasks().length,
      'totalAlarms': db.getAllAlarms().length,
      'totalXP': db.getTotalXP(),
      'streak': db.getStreak().currentStreak,
      'longestStreak': db.getStreak().longestStreak,
      'feedbackCount': db.getAllFeedback().length,
    });
  }

  /// Exports complete user database state to JSON
  String exportAllUserDataJson() {
    final db = LocalDatabase.instance;
    return jsonEncode({
      'exportVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': db.getAllTasks().map((t) => t.toMap()).toList(),
      'totalXP': db.getTotalXP(),
      'streak': {
        'currentStreak': db.getStreak().currentStreak,
        'longestStreak': db.getStreak().longestStreak,
        'lastCompletedDate': db.getStreak().lastCompletedDate,
      },
      'feedback': db.getAllFeedback().map((f) => f.toJson()).toList(),
    });
  }
}
