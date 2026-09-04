// Habitat Profile Page Widget Tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/core/theme/habitat_theme.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/profile/application/profile_controller.dart';
import 'package:habitat_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:habitat_mobile/features/profile/domain/services/privacy_service.dart';
import 'package:habitat_mobile/features/profile/domain/services/profile_service.dart';
import 'package:habitat_mobile/features/profile/domain/services/security_service.dart';
import 'package:habitat_mobile/features/profile/domain/services/settings_service.dart';
import 'package:habitat_mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:habitat_mobile/features/profile/presentation/widgets/profile_header.dart';
import 'package:habitat_mobile/features/profile/presentation/widgets/settings_section.dart';

void main() {
  late LocalDatabase db;
  late ProfileRepository repo;
  late ProfileService profileService;
  late SettingsService settingsService;
  late PrivacyService privacyService;
  late SecurityService securityService;
  late ProfileController controller;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    repo = ProfileRepository(db);
    profileService = ProfileService(repo);
    settingsService = SettingsService(repo);
    privacyService = PrivacyService(repo);
    securityService = SecurityService(repo);
    controller = ProfileController(
      profileService: profileService,
      settingsService: settingsService,
      privacyService: privacyService,
      securityService: securityService,
      database: db,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      theme: HabitatTheme.darkTheme,
      home: ProfilePage(controller: controller),
    );
  }

  group('ProfilePage Widget Tests', () {
    testWidgets('renders profile hub with header and all settings sections',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('PROFILE & SETTINGS'), findsOneWidget);
      expect(find.byType(ProfileHeader), findsOneWidget);
      expect(find.byType(SettingsSection), findsNWidgets(5));
      expect(find.text('PERSONAL'), findsOneWidget);
      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('SECURITY & PRIVACY'), findsOneWidget);
      expect(find.text('DATA CONTROLS'), findsOneWidget);
      expect(find.text('SUPPORT'), findsOneWidget);
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('General Preferences'), findsOneWidget);
    });
  });
}
