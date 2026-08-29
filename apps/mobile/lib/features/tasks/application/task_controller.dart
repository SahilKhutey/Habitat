// Habitat Task List Application Controller
import 'package:flutter/foundation.dart';
import '../../../database/local_database.dart';
import '../domain/models/task_model.dart';
import '../domain/services/task_service.dart';

class TaskController extends ChangeNotifier {
  final TaskService _taskService;
  final LocalDatabase _database;

  String activeFilter = 'ALL';
  List<TaskModel> tasks = [];
  bool isLoading = false;

  TaskController({
    required TaskService taskService,
    required LocalDatabase database,
  })  : _taskService = taskService,
        _database = database {
    _database.changes.addListener(_refreshFromData);
  }

  void load() {
    isLoading = true;
    notifyListeners();
    _refresh();
  }

  void setFilter(String filter) {
    activeFilter = filter;
    _refresh();
  }

  void pauseTask(String taskId) {
    _taskService.pauseTask(taskId);
    _refresh();
  }

  void resumeTask(String taskId) {
    _taskService.resumeTask(taskId);
    _refresh();
  }

  void archiveTask(String taskId) {
    _taskService.archiveTask(taskId);
    _refresh();
  }

  void _refreshFromData() => _refresh();

  void _refresh() {
    tasks = _taskService.getTasksByFilter(activeFilter);
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _database.changes.removeListener(_refreshFromData);
    super.dispose();
  }
}
