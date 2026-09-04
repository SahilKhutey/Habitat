// Habitat Security & App Lock Service
import '../models/security_settings.dart';
import '../repositories/profile_repository.dart';

class SecurityService {
  final ProfileRepository _repository;

  SecurityService(this._repository);

  SecuritySettingsModel getSecuritySettings() {
    return SecuritySettingsModel.fromMap(_repository.getSecuritySettings());
  }

  void updateSecuritySettings(SecuritySettingsModel settings) {
    _repository.setSecuritySettings(settings.toMap());
  }

  void setPin(String newPin) {
    if (newPin.length < 4) throw ArgumentError('PIN must be at least 4 digits');
    final current = getSecuritySettings();
    updateSecuritySettings(
        current.copyWith(pinCode: newPin, appLockEnabled: true));
  }

  bool verifyPin(String enteredPin) {
    final current = getSecuritySettings();
    return current.pinCode == enteredPin;
  }
}
