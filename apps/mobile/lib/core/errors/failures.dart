// Habitat Sealed Failure & Error Architecture
import 'package:flutter/foundation.dart';

@immutable
sealed class HabitatFailure {
  final String message;
  final String? code;

  const HabitatFailure(this.message, {this.code});

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

class StorageFailure extends HabitatFailure {
  const StorageFailure(super.message, {super.code});
}

class PermissionFailure extends HabitatFailure {
  final String permissionType;
  const PermissionFailure(super.message,
      {required this.permissionType, super.code});
}

class ValidationFailure extends HabitatFailure {
  final String field;
  const ValidationFailure(super.message, {required this.field, super.code});
}

class PlatformFailure extends HabitatFailure {
  const PlatformFailure(super.message, {super.code});
}

class ExecutionFailure extends HabitatFailure {
  final String taskId;
  const ExecutionFailure(super.message, {required this.taskId, super.code});
}
