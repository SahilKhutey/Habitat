// Habitat Action Execution & Verification Service
import '../models/habitat_action.dart';

abstract interface class IActionExecutor {
  Future<bool> executeAndVerify(
      HabitatAction action, Map<String, dynamic> inputPayload);
}

class ActionExecutor implements IActionExecutor {
  @override
  Future<bool> executeAndVerify(
      HabitatAction action, Map<String, dynamic> inputPayload) async {
    switch (action.type) {
      case ActionType.checklist:
        final items = inputPayload['checkedItems'] as List<dynamic>? ?? [];
        final total = action.configuration['totalItems'] as int? ?? 1;
        return items.length >= total;

      case ActionType.photo:
        final hasImage = inputPayload['imageBytes'] != null ||
            inputPayload['imagePath'] != null;
        final confidence = inputPayload['confidenceScore'] as double? ?? 1.0;
        return hasImage && confidence >= 0.7;

      case ActionType.video:
        final hasVideo = inputPayload['videoPath'] != null ||
            inputPayload['repsCompleted'] != null;
        final reps = inputPayload['repsCompleted'] as int? ?? 0;
        final targetReps = action.configuration['targetReps'] as int? ?? 10;
        return hasVideo && reps >= targetReps;

      case ActionType.timer:
        final elapsedSeconds = inputPayload['elapsedSeconds'] as int? ?? 0;
        final targetSeconds =
            action.configuration['durationSeconds'] as int? ?? 60;
        return elapsedSeconds >= targetSeconds;

      case ActionType.confirmation:
        return inputPayload['confirmed'] == true;
    }
  }
}
