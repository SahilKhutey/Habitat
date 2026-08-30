// Habitat Task Repository
import '../../../../database/local_database.dart';

class TaskRepository {
  final LocalDatabase _database;

  TaskRepository([LocalDatabase? database])
      : _database = database ?? LocalDatabase.instance;

  List<LocalTask> getTodayTasks() => _database.getAllTasks();

  List<LocalTask> getAllTasks() => _database.getAllTasks();

  LocalTask? getTaskById(String id) => _database.getTaskById(id);

  void createTask(LocalTask task) {
    _database.saveTask(task);
  }

  void updateTask(LocalTask task) {
    _database.saveTask(task);
  }

  void deleteTask(String id) {
    _database.deleteTask(id);
  }

  void completeTask(String id) {
    final task = _database.getTaskById(id);
    if (task != null) {
      _database.saveTask(task.copyWith(
        isCompleted: true,
        updatedAt: DateTime.now(),
      ));
    }
  }
}
