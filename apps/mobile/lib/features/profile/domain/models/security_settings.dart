// Habitat Security Settings Domain Model
import 'package:flutter/foundation.dart';

@immutable
class SecuritySettingsModel {
  final bool appLockEnabled;
  final bool biometricEnabled;
  final String? pinCode;

  const SecuritySettingsModel({
    this.appLockEnabled = false,
    this.biometricEnabled = false,
    this.pinCode,
  });

  bool get hasPinSet => pinCode != null && pinCode!.isNotEmpty;

  SecuritySettingsModel copyWith({
    bool? appLockEnabled,
    bool? biometricEnabled,
    String? pinCode,
  }) =>
      SecuritySettingsModel(
        appLockEnabled: appLockEnabled ?? this.appLockEnabled,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        pinCode: pinCode ?? this.pinCode,
      );

  Map<String, dynamic> toMap() => {
        'appLock': appLockEnabled,
        'biometric': biometricEnabled,
        'pin': pinCode,
      };

  factory SecuritySettingsModel.fromMap(Map<String, dynamic> map) => SecuritySettingsModel(
        appLockEnabled: map['appLock'] ?? false,
        biometricEnabled: map['biometric'] ?? false,
        pinCode: map['pin'],
      );
}
