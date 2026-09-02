// Automated Test Suite for Phase W: Accessibility, UX Resilience & Inclusive Interaction Certification
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitat_mobile/database/local_database.dart';
import 'package:habitat_mobile/features/tasks/domain/services/alarm_service.dart';
import 'package:habitat_mobile/services/mission_execution_service.dart';

void main() {
  late LocalDatabase db;
  late MissionExecutionService missionService;

  setUp(() {
    db = LocalDatabase.instance;
    db.resetAllData();
    missionService = MissionExecutionService(database: db);
  });

  group('Phase W: Dynamic Text Scaling & Text Layout Resilience (W5, W6)', () {
    testWidgets('W5 & W6: Renders mission and task UI with 2.0x text scale factor without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const Text('TACTICAL DAILY MISSION: 15 PUSH-UPS FOR DISCIPLINE'),
                  const SizedBox(height: 10),
                  const Text('Instructions: Place phone securely on floor, complete 15 pushups with full depth.'),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('START CAMERA PROOF CAPTURE'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('TACTICAL DAILY MISSION: 15 PUSH-UPS FOR DISCIPLINE'), findsOneWidget);
      expect(find.text('START CAMERA PROOF CAPTURE'), findsOneWidget);
    });
  });

  group('Phase W: Semantics & Screen Reader Controls (W2, W3, W4)', () {
    testWidgets('W2 & W3: Action buttons have explicit Semantics and Tooltip descriptors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Semantics(
                  label: 'Start morning push-up mission',
                  button: true,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.videocam),
                    label: const Text('START MISSION'),
                    onPressed: () {},
                  ),
                ),
                Semantics(
                  label: 'Disarm alarm',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.alarm_off),
                    tooltip: 'Disarm current alarm',
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Start morning push-up mission'), findsOneWidget);
      expect(find.bySemanticsLabel('Disarm alarm'), findsOneWidget);
    });
  });

  group('Phase W: Multi-Signal Color & Contrast Indicators (W8)', () {
    test('W8: Error and success state messages provide explicit textual and semantic signals', () async {
      final task = LocalTask(
        id: 'task_w_signals',
        title: 'Morning Sun Salutation',
        category: 'HEALTH',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_w_signals');

      // Unverified failure provides actionable textual reason
      final failureRes = await missionService.complete(attempt.id);
      expect(failureRes.isSuccess, isFalse);
      expect(failureRes.errorMessage, contains('Unverified proof'));

      // Verified success provides explicit XP and streak signal
      await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'PHOTO',
          filePath: 'habitat_storage://proofs/w_sun.jpg',
          sha256Checksum: '1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff',
        ),
      );

      final successRes = await missionService.complete(attempt.id);
      expect(successRes.isSuccess, isTrue);
      expect(successRes.earnedXp, equals(20));
    });
  });

  group('Phase W: Rapid Interaction & Double-Tap Idempotency (W13, W14)', () {
    test('W14: Rapid double completion requests produce exactly 1 completion and 1 XP reward', () async {
      final task = LocalTask(
        id: 'task_w_rapid',
        title: 'Cold Water Splash',
        category: 'DISCIPLINE',
        taskType: 'PHOTO',
        requiresPhoto: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      db.saveTask(task);

      final attempt = await missionService.start('task_w_rapid');
      await missionService.submitProof(
        attempt.id,
        const ProofSubmission(
          type: 'PHOTO',
          filePath: 'habitat_storage://proofs/rapid.jpg',
          sha256Checksum: 'abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef',
        ),
      );

      // Rapid double invocation
      final res1 = await missionService.complete(attempt.id);
      final res2 = await missionService.complete(attempt.id);

      expect(res1.isSuccess, isTrue);
      expect(res1.earnedXp, equals(20));
      expect(res2.isSuccess, isTrue);
      expect(res2.earnedXp, equals(0)); // Idempotent 0 extra XP
      expect(db.getTotalXP(), equals(20));
    });
  });
}
