// Habitat Master Home Controller Integration Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/health/domain/repositories/water_repository.dart';
import 'package:habitat_mobile/features/health/domain/services/water_service.dart';
import 'package:habitat_mobile/features/home/application/home_controller.dart';
import 'package:habitat_mobile/features/tasks/domain/repositories/task_repository.dart';
import 'package:habitat_mobile/features/tasks/domain/services/task_lifecycle_service.dart';

void main() {
  late LocalDatabase db;
  late TaskRepository taskRepo;
  late TaskLifecycleService taskService;
  late WaterService waterService;
  late HomeController homeController;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    taskRepo = TaskRepository(db);
    taskService = TaskLifecycleService(taskRepository: taskRepo, database: db);
    waterService = WaterService(WaterRepository(db));
    homeController = HomeController(
      database: db,
      taskService: taskService,
      waterService: waterService,
    );
  });

  tearDown(() {
    homeController.dispose();
  });

  group('HomeController Live Aggregation Tests', () {
    test('initial state loads task counts and water metrics cleanly', () {
      final state = homeController.state;
      expect(state.tasksTotal, equals(8)); // 8 default templates
      expect(state.tasksCompleted, equals(0));
      expect(state.waterConsumedMl, equals(0));
      expect(state.userLevel, equals(1));
    });

    test('logWater() updates water consumption in real time', () {
      homeController.logWater(500);

      expect(homeController.state.waterConsumedMl, equals(500));
      expect(homeController.state.waterProgress, equals(0.2));
    });

    test('completeTask() updates tasksCompleted count and completion rate', () {
      final tasks = taskService.getTodayTasks();
      homeController.completeTask(tasks.first.id);

      expect(homeController.state.tasksCompleted, equals(1));
      expect(homeController.state.completionRate, greaterThan(0.0));
    });
  });
}
