// Habitat Profile Service Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:habitat_mobile/features/profile/domain/services/profile_service.dart';

void main() {
  late LocalDatabase db;
  late ProfileService profileService;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    profileService = ProfileService(ProfileRepository(db));
  });

  group('ProfileService Unit Tests', () {
    test('getProfile() returns initial explorer profile', () {
      final profile = profileService.getProfile();
      expect(profile.displayName, isNotEmpty);
      expect(profile.disciplineLevel, equals('Explorer'));
    });

    test('updateProfile() updates display name and bio cleanly', () {
      profileService.updateProfile(
        displayName: 'Alex Rivers',
        bio: 'Focused on daily morning pushups and deep work.',
      );

      final updated = profileService.getProfile();
      expect(updated.displayName, equals('Alex Rivers'));
      expect(updated.bio, contains('morning pushups'));
    });

    test('updateProfile() throws ArgumentError on empty display name', () {
      expect(
        () => profileService.updateProfile(displayName: '', bio: 'Some bio'),
        throwsArgumentError,
      );
    });
  });
}
