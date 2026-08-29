// Habitat Security Application Controller
import 'package:flutter/foundation.dart';
import '../../../database/local_database.dart';
import '../domain/models/security_settings.dart';
import '../domain/services/security_service.dart';

class SecurityController extends ChangeNotifier {
  final SecurityService _securityService;
  final LocalDatabase _database;

  late SecuritySettingsModel security;

  SecurityController({
    required SecurityService securityService,
    required LocalDatabase database,
  })  : _securityService = securityService,
        _database = database {
    security = _securityService.getSecuritySettings();
    _database.changes.addListener(_onDataChanged);
  }

  void toggleAppLock(bool enabled) {
    _securityService.updateSecuritySettings(security.copyWith(appLockEnabled: enabled));
  }

  void toggleBiometrics(bool enabled) {
    _securityService.updateSecuritySettings(security.copyWith(biometricEnabled: enabled));
  }

  void setPin(String pin) {
    _securityService.setPin(pin);
  }

  bool verifyPin(String pin) {
    return _securityService.verifyPin(pin);
  }

  void _onDataChanged() {
    security = _securityService.getSecuritySettings();
    notifyListeners();
  }

  @override
  void dispose() {
    _database.changes.removeListener(_onDataChanged);
    super.dispose();
  }
}
