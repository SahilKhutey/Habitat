// Canonical Mission State Machine Engine in Pure Dart
import '../models/mission.dart';
import '../models/alarm.dart';

class InvalidStateTransitionException implements Exception {
  final MissionStatus from;
  final MissionStatus to;
  final String message;

  InvalidStateTransitionException(this.from, this.to, [this.message = '']);

  @override
  String toString() => 'InvalidStateTransitionException: $from -> $to. $message';
}

class EscalationLevel {
  final int sirenVolume;
  final String urgencyLevel; // 'LOW', 'MEDIUM', 'HIGH', 'MAX'
  final bool flashHaptics;
  final bool notifyAccountabilityPartner;

  const EscalationLevel({
    required this.sirenVolume,
    required this.urgencyLevel,
    required this.flashHaptics,
    required this.notifyAccountabilityPartner,
  });
}

class MissionStateMachine {
  static const Map<MissionStatus, List<MissionStatus>> _validTransitions = {
    MissionStatus.scheduled: [MissionStatus.triggered],
    MissionStatus.triggered: [MissionStatus.active, MissionStatus.retrying, MissionStatus.failed],
    MissionStatus.active: [MissionStatus.proofSubmitted, MissionStatus.retrying, MissionStatus.failed],
    MissionStatus.proofSubmitted: [MissionStatus.verifying, MissionStatus.active, MissionStatus.failed],
    MissionStatus.verifying: [MissionStatus.completed, MissionStatus.active, MissionStatus.retrying, MissionStatus.failed],
    MissionStatus.retrying: [MissionStatus.triggered, MissionStatus.active, MissionStatus.failed],
    MissionStatus.completed: [], // Terminal State
    MissionStatus.failed: [],    // Terminal State
  };

  static bool canTransition(MissionStatus from, MissionStatus to) {
    final allowed = _validTransitions[from];
    return allowed != null && allowed.contains(to);
  }

  static MissionStatus transition({
    required MissionStatus currentStatus,
    required MissionStatus nextStatus,
    DisciplineMode disciplineMode = DisciplineMode.discipline,
    int attemptCount = 1,
    bool hasValidProof = false,
  }) {
    if (!canTransition(currentStatus, nextStatus)) {
      throw InvalidStateTransitionException(
        currentStatus,
        nextStatus,
        'Transition not permitted by state machine protocol.',
      );
    }

    if (nextStatus == MissionStatus.completed && !hasValidProof) {
      throw InvalidStateTransitionException(
        currentStatus,
        nextStatus,
        'Cannot complete mission without verified proof.',
      );
    }

    if (nextStatus == MissionStatus.failed && disciplineMode == DisciplineMode.hardcore && attemptCount < 3) {
      throw InvalidStateTransitionException(
        currentStatus,
        nextStatus,
        'Hardcore mode prohibits failure before 3 escalated attempts.',
      );
    }

    return nextStatus;
  }

  static EscalationLevel calculateEscalation(int attemptIndex, DisciplineMode mode) {
    switch (attemptIndex) {
      case 1:
        return EscalationLevel(
          sirenVolume: mode == DisciplineMode.gentle ? 50 : 70,
          urgencyLevel: 'LOW',
          flashHaptics: false,
          notifyAccountabilityPartner: false,
        );
      case 2: // +5 minutes
        return EscalationLevel(
          sirenVolume: mode == DisciplineMode.gentle ? 70 : 85,
          urgencyLevel: 'MEDIUM',
          flashHaptics: true,
          notifyAccountabilityPartner: false,
        );
      case 3: // +10 minutes
        return const EscalationLevel(
          sirenVolume: 100,
          urgencyLevel: 'HIGH',
          flashHaptics: true,
          notifyAccountabilityPartner: false,
        );
      default: // +15 minutes and beyond
        return EscalationLevel(
          sirenVolume: 100,
          urgencyLevel: 'MAX',
          flashHaptics: true,
          notifyAccountabilityPartner: mode == DisciplineMode.hardcore,
        );
    }
  }
}
