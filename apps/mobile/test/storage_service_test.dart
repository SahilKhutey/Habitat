// Habitat Storage Service Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:habitat_mobile/features/profile/domain/services/storage_service.dart';

void main() {
  late LocalDatabase db;
  late StorageService storageService;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    storageService = StorageService(ProfileRepository(db));
  });

  group('StorageService Unit Tests', () {
    test('getStorageInfo() calculates storage usage metrics', () {
      final info = storageService.getStorageInfo();
      expect(info.totalBytes, greaterThan(0));
      expect(info.formattedTotal, isNotEmpty);
      expect(info.formattedTasks, isNotEmpty);
    });

    test('exportJson() returns portable valid JSON string', () {
      final json = storageService.exportJson();
      expect(json, contains('"version"'));
      expect(json, contains('"displayName"'));
      expect(json, contains('"tasksCount"'));
    });

    test('resetAllData() clears data and restores default templates', () {
      db.saveTask(LocalTask(
        id: 'custom-task',
        title: 'Custom Habit',
        category: 'HEALTH',
        taskType: 'PHOTO',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      expect(db.getAllTasks().any((t) => t.id == 'custom-task'), isTrue);

      storageService.resetAllData();

      expect(db.getAllTasks().any((t) => t.id == 'custom-task'), isFalse);
      expect(db.getAllTasks().length, equals(8)); // 8 default templates
    });
  });
}
