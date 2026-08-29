// Habitat Task Execution HUD Controller
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/models/execution_model.dart';
import '../domain/services/execution_service.dart';

class ExecutionController extends ChangeNotifier {
  final TaskExecutionService _executionService;
  late TaskExecutionModel execution;

  int secondsElapsed = 0;
  Timer? _timer;
  bool isVerifying = false;
  String? errorMessage;

  ExecutionController({
    required TaskExecutionService executionService,
    required String taskId,
    String? taskTitle,
  }) : _executionService = executionService {
    execution = _executionService.startTaskExecution(
      taskId: taskId,
      taskTitle: taskTitle,
    );
    _startResistanceTimer();
  }

  bool get isSpeedBonusActive => secondsElapsed <= 120;

  String get formattedTimer {
    final m = (secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final s = (secondsElapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startResistanceTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      secondsElapsed++;
      notifyListeners();
    });
  }

  Future<bool> submitProof(String proofPath) async {
    _timer?.cancel();
    isVerifying = true;
    errorMessage = null;
    notifyListeners();

    try {
      final updated = await _executionService.submitProofAndVerify(
        execution: execution,
        proofPath: proofPath,
        resistanceSeconds: secondsElapsed,
      );

      execution = updated;
      isVerifying = false;
      notifyListeners();

      return updated.status == ExecutionStatus.completed;
    } catch (e) {
      isVerifying = false;
      errorMessage = 'Verification encountered an error. Please retry.';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
