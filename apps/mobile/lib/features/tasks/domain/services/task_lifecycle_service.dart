// Habitat Master Task Lifecycle & Progression Integration Service
import '../../../../database/local_database.dart';
import '../models/habitat_action.dart';
import '../repositories/task_repository.dart';
import 'action_executor.dart';

class TaskLifecycleService {
  final TaskRepository _taskRepository;
  final LocalDatabase _database;
  final IActionExecutor _actionExecutor;

  TaskLifecycleService({
    required TaskRepository taskRepository,
    required LocalDatabase database,
    IActionExecutor? actionExecutor,
  })  : _taskRepository = taskRepository,
        _database = database,
        _actionExecutor = actionExecutor ?? ActionExecutor();

  List<LocalTask> getTodayTasks() => _taskRepository.getTodayTasks();

  List<LocalTask> getAllTasks() => _taskRepository.getAllTasks();

  LocalTask? getTaskById(String id) => _taskRepository.getTaskById(id);

  void createTask(LocalTask task) {
    _taskRepository.createTask(task);
  }

  void updateTask(LocalTask task) {
    _taskRepository.updateTask(task);
  }

  void deleteTask(String id) {
    _taskRepository.deleteTask(id);
  }

  Future<bool> completeTaskWithAction(
    String taskId, {
    HabitatAction? action,
    Map<String, dynamic> actionPayload = const {},
  }) async {
    // 1. Verify Action if required
    if (action != null) {
      final verified = await _actionExecutor.executeAndVerify(action, actionPayload);
      if (!verified) {
        return false;
      }
    }

    // 2. Mark completed in database
    _taskRepository.completeTask(taskId);

    // 3. Record task attempt log
    _database.saveAttempt(LocalTaskAttempt(
      id: 'attempt_${DateTime.now().millisecondsSinceEpoch}',
      taskId: taskId,
      status: 'VERIFIED',
      startedAt: DateTime.now().subtract(const Duration(minutes: 2)),
      completedAt: DateTime.now(),
      score: 1.0,
    ));

    return true;
  }

  void reopenTask(String taskId) {
    final task = _taskRepository.getTaskById(taskId);
    if (task != null) {
      final updated = task.copyWith(
        isCompleted: false,
        updatedAt: DateTime.now(),
      );
      _taskRepository.updateTask(updated);
    }
  }
}
