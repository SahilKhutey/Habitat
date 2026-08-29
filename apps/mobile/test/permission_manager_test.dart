// Habitat Permission Manager Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/core/platform/permissions/permission_manager.dart';

void main() {
  group('PermissionManager Unit Tests', () {
    test('checkStatus() returns valid status across platform types', () async {
      final manager = PermissionManager();

      final notifStatus = await manager.checkStatus(HabitatPermissionType.notifications);
      expect(notifStatus, equals(HabitatPermissionStatus.granted));

      final alarmStatus = await manager.checkStatus(HabitatPermissionType.exactAlarms);
      expect(alarmStatus, equals(HabitatPermissionStatus.granted));

      final cameraStatus = await manager.checkStatus(HabitatPermissionType.camera);
      expect(cameraStatus, equals(HabitatPermissionStatus.granted));
    });

    test('requestPermission() updates denied permission to granted', () async {
      final manager = PermissionManager(
        initialStatuses: {HabitatPermissionType.microphone: HabitatPermissionStatus.denied},
      );

      var status = await manager.checkStatus(HabitatPermissionType.microphone);
      expect(status, equals(HabitatPermissionStatus.denied));

      status = await manager.requestPermission(HabitatPermissionType.microphone);
      expect(status, equals(HabitatPermissionStatus.granted));
    });
  });
}
