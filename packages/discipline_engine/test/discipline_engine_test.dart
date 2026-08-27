// Pure Dart Unit Tests for Discipline Engine & Recurrence Engine
import 'package:test/test.dart';
import '../lib/discipline_engine.dart';

void main() {
  group('MissionStateMachine (Dart Core)', () {
    test('transitions through valid lifecycle: scheduled -> triggered -> active -> proofSubmitted -> verifying -> completed', () {
      var status = MissionStatus.scheduled;

      status = MissionStateMachine.transition(
        currentStatus: status,
        nextStatus: MissionStatus.triggered,
      );
      expect(status, equals(MissionStatus.triggered));

      status = MissionStateMachine.transition(
        currentStatus: status,
        nextStatus: MissionStatus.active,
      );
      expect(status, equals(MissionStatus.active));

      status = MissionStateMachine.transition(
        currentStatus: status,
        nextStatus: MissionStatus.proofSubmitted,
      );
      expect(status, equals(MissionStatus.proofSubmitted));

      status = MissionStateMachine.transition(
        currentStatus: status,
        nextStatus: MissionStatus.verifying,
      );
      expect(status, equals(MissionStatus.verifying));

      status = MissionStateMachine.transition(
        currentStatus: status,
        nextStatus: MissionStatus.completed,
        hasValidProof: true,
      );
      expect(status, equals(MissionStatus.completed));
    });

    test('throws InvalidStateTransitionException on invalid skip', () {
      expect(
        () => MissionStateMachine.transition(
          currentStatus: MissionStatus.scheduled,
          nextStatus: MissionStatus.completed,
        ),
        throwsA(isA<InvalidStateTransitionException>()),
      );
    });

    test('calculates correct siren escalation per attempt', () {
      final a1 = MissionStateMachine.calculateEscalation(1, DisciplineMode.discipline);
      expect(a1.sirenVolume, equals(70));
      expect(a1.urgencyLevel, equals('LOW'));

      final a2 = MissionStateMachine.calculateEscalation(2, DisciplineMode.discipline);
      expect(a2.sirenVolume, equals(85));
      expect(a2.flashHaptics, isTrue);

      final a3 = MissionStateMachine.calculateEscalation(3, DisciplineMode.discipline);
      expect(a3.sirenVolume, equals(100));

      final a4 = MissionStateMachine.calculateEscalation(4, DisciplineMode.hardcore);
      expect(a4.notifyAccountabilityPartner, isTrue);
    });
  });

  group('MetricsEngine (Dart Core)', () {
    test('calculates resistance seconds accurately', () {
      final start = DateTime.parse('2026-08-27T07:00:00Z');
      final end = DateTime.parse('2026-08-27T07:02:30Z');
      final seconds = MetricsEngine.calculateResistanceSeconds(startTime: start, completionTime: end);
      expect(seconds, equals(150));
    });

    test('awards 1.5x speed bonus for instant first-attempt completion', () {
      final reward = MetricsEngine.calculateXp(
        baseXp: 50,
        resistanceSeconds: 90, // 1.5 min
        attemptCount: 1,
        disciplineMode: DisciplineMode.discipline,
      );

      expect(reward.isFirstAlarmBonus, isTrue);
      expect(reward.speedMultiplier, equals(1.5));
      expect(reward.totalXp, equals(75));
    });

    test('protects streak with grace tokens', () {
      final result = MetricsEngine.evaluateStreak(
        currentStreak: 12,
        graceTokens: 1,
        missionSuccess: false,
      );

      expect(result.newStreak, equals(12));
      expect(result.newGraceTokens, equals(0));
      expect(result.usedGraceToken, isTrue);
      expect(result.streakBroken, isFalse);
    });
  });

  group('RecurrenceEngine (Dart Core)', () {
    test('calculates next occurrence today if time is in the future', () {
      // Reference: Thursday 2026-08-27 06:30 AM (Thursday = weekday 4)
      final ref = DateTime(2026, 8, 27, 6, 30);
      final next = RecurrenceEngine.calculateNextOccurrence(
        timeOfDay: '07:00',
        repeatDays: [4], // Thursday
        now: ref,
      );

      expect(next.year, equals(2026));
      expect(next.month, equals(8));
      expect(next.day, equals(27));
      expect(next.hour, equals(7));
      expect(next.minute, equals(0));
    });

    test('calculates next occurrence for next week if time today has passed', () {
      // Reference: Thursday 2026-08-27 08:00 AM (Past 07:00)
      final ref = DateTime(2026, 8, 27, 8, 0);
      final next = RecurrenceEngine.calculateNextOccurrence(
        timeOfDay: '07:00',
        repeatDays: [4], // Thursday only
        now: ref,
      );

      // Next occurrence must be next Thursday: 2026-09-03
      expect(next.year, equals(2026));
      expect(next.month, equals(9));
      expect(next.day, equals(3));
      expect(next.hour, equals(7));
    });

    test('formats repeat days correctly', () {
      expect(RecurrenceEngine.formatRepeatDays([]), equals('Once'));
      expect(RecurrenceEngine.formatRepeatDays([1, 2, 3, 4, 5, 6, 7]), equals('Every day'));
      expect(RecurrenceEngine.formatRepeatDays([1, 2, 3, 4, 5]), equals('Weekdays'));
      expect(RecurrenceEngine.formatRepeatDays([6, 7]), equals('Weekends'));
      expect(RecurrenceEngine.formatRepeatDays([1, 3, 5]), equals('Mon, Wed, Fri'));
    });
  });

  group('AntiCheatValidator (Dart Core)', () {
    test('rejects dark scenes below threshold', () {
      final task = Task(
        id: '1',
        slug: 'make-bed',
        title: 'Make Bed',
        description: 'Smooth sheets',
        category: TaskCategory.morning,
        proofType: ProofType.photo,
        instructions: ['Smooth sheets'],
        validationRules: {'minLuminance': 30},
        createdAt: DateTime.now(),
      );

      final result = AntiCheatValidator.validateProof(
        capturedAt: DateTime.now(),
        deviceTelemetry: {'ambientLux': 10},
        task: task,
      );

      expect(result.isValid, isFalse);
      expect(result.rejectionReason, contains('too dark'));
    });
  });
}
