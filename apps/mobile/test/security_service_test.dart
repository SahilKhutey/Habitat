// Habitat Security Service Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:habitat_mobile/features/profile/domain/services/security_service.dart';

void main() {
  late LocalDatabase db;
  late SecurityService securityService;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    securityService = SecurityService(ProfileRepository(db));
  });

  group('SecurityService Unit Tests', () {
    test('setPin() sets PIN and activates appLockEnabled', () {
      securityService.setPin('1234');

      final settings = securityService.getSecuritySettings();
      expect(settings.appLockEnabled, isTrue);
      expect(settings.hasPinSet, isTrue);
      expect(settings.pinCode, equals('1234'));
    });

    test('verifyPin() validates correct PIN and rejects incorrect PIN', () {
      securityService.setPin('5678');

      expect(securityService.verifyPin('5678'), isTrue);
      expect(securityService.verifyPin('0000'), isFalse);
    });

    test('setPin() throws on PIN shorter than 4 digits', () {
      expect(() => securityService.setPin('12'), throwsArgumentError);
    });
  });
}
