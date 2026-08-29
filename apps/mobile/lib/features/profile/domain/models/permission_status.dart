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
