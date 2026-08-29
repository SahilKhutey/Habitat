// Offline Feedback Management & Export Service
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../database/local_database.dart';

class FeedbackService {
  static final FeedbackService instance = FeedbackService._internal();
  FeedbackService._internal();

  LocalFeedback submitFeedback({
    required String type,
    required String title,
    required String message,
    required int rating,
    String? screenshotPath,
  }) {
    final fb = LocalFeedback(
      id: const Uuid().v4(),
      type: type,
      title: title,
      message: message,
      rating: rating,
      screenshotPath: screenshotPath,
      createdAt: DateTime.now(),
    );

    LocalDatabase.instance.addFeedback(fb);
    return fb;
  }

  /// Exports all feedback to JSON string for manual sharing / diagnostics
  String exportFeedbackJson() {
    final feedbackList = LocalDatabase.instance.getAllFeedback();
    return jsonEncode({
      'exportDate': DateTime.now().toIso8601String(),
      'feedbackCount': feedbackList.length,
      'items': feedbackList.map((f) => f.toJson()).toList(),
    });
  }
}
