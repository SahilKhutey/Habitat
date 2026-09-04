// Habitat Platform Permission Diagnostic Service
import '../models/permission_status.dart';

class PermissionService {
  List<PermissionItemModel> getPermissionsDiagnostic() {
    return const [
      PermissionItemModel(
        type: PermissionType.notifications,
        displayName: 'Push & Status Notifications',
        usageDescription:
            'Delivers scheduled task cues and progress milestones cleanly.',
        status: PermissionState.granted,
        isRequiredForDiscipline: true,
      ),
      PermissionItemModel(
        type: PermissionType.exactAlarms,
        displayName: 'Exact Android Alarm Execution',
        usageDescription:
            'Wakes the device reliably at exact scheduled discipline times.',
        status: PermissionState.granted,
        isRequiredForDiscipline: true,
      ),
      PermissionItemModel(
        type: PermissionType.camera,
        displayName: 'Camera Proof Capture',
        usageDescription:
            'Captures and verifies visual mission discipline proofs.',
        status: PermissionState.granted,
        isRequiredForDiscipline: true,
      ),
      PermissionItemModel(
        type: PermissionType.microphone,
        displayName: 'Microphone Audio Input',
        usageDescription:
            'Used for optional voice reflection and sound verification.',
        status: PermissionState.notRequested,
        isRequiredForDiscipline: false,
      ),
      PermissionItemModel(
        type: PermissionType.location,
        displayName: 'Location Services',
        usageDescription:
            'Optional context verification for location-based habits.',
        status: PermissionState.notRequested,
        isRequiredForDiscipline: false,
      ),
    ];
  }
}
