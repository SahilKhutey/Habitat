// Habitat Centralized Platform Permission Manager
import 'package:flutter/foundation.dart';

enum HabitatPermissionType {
  notifications,
  exactAlarms,
  camera,
  microphone,
  batteryOptimization,
}

enum HabitatPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unavailable,
}

abstract interface class IPermissionManager {
  Future<HabitatPermissionStatus> checkStatus(HabitatPermissionType type);
  Future<HabitatPermissionStatus> requestPermission(HabitatPermissionType type);
  Future<bool> openAppSettings();
}

class PermissionManager implements IPermissionManager {
  final Map<HabitatPermissionType, HabitatPermissionStatus> _permissionStatuses;

  PermissionManager({
    Map<HabitatPermissionType, HabitatPermissionStatus>? initialStatuses,
  }) : _permissionStatuses = initialStatuses ??
            {
              HabitatPermissionType.notifications:
                  HabitatPermissionStatus.granted,
              HabitatPermissionType.exactAlarms:
                  HabitatPermissionStatus.granted,
              HabitatPermissionType.camera: HabitatPermissionStatus.granted,
              HabitatPermissionType.microphone: HabitatPermissionStatus.denied,
              HabitatPermissionType.batteryOptimization:
                  HabitatPermissionStatus.granted,
            };

  @override
  Future<HabitatPermissionStatus> checkStatus(
      HabitatPermissionType type) async {
    return _permissionStatuses[type] ?? HabitatPermissionStatus.denied;
  }

  @override
  Future<HabitatPermissionStatus> requestPermission(
      HabitatPermissionType type) async {
    // In production runtime, stores granted status
    _permissionStatuses[type] = HabitatPermissionStatus.granted;
    return HabitatPermissionStatus.granted;
  }

  @override
  Future<bool> openAppSettings() async {
    // In production, opens native system settings
    return true;
  }
}
