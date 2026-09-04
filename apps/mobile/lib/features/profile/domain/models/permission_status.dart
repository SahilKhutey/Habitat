// Habitat Platform Permission Diagnostic Domain Model
import 'package:flutter/foundation.dart';

enum PermissionType {
  notifications,
  exactAlarms,
  camera,
  microphone,
  location,
}

enum PermissionState {
  granted,
  denied,
  restricted,
  notRequested,
  notAvailable,
}

@immutable
class PermissionItemModel {
  final PermissionType type;
  final String displayName;
  final String usageDescription;
  final PermissionState status;
  final bool isRequiredForDiscipline;

  const PermissionItemModel({
    required this.type,
    required this.displayName,
    required this.usageDescription,
    required this.status,
    this.isRequiredForDiscipline = true,
  });

  bool get isGranted => status == PermissionState.granted;
}

typedef AppPermissionType = PermissionType;
typedef PermissionAuthorizationStatus = PermissionState;

class AppPermission extends PermissionItemModel {
  final String name;
  final String description;

  const AppPermission({
    required PermissionType type,
    required this.name,
    required this.description,
    required PermissionState status,
    bool isRequiredForDiscipline = true,
  }) : super(
          type: type,
          displayName: name,
          usageDescription: description,
          status: status,
          isRequiredForDiscipline: isRequiredForDiscipline,
        );
}
