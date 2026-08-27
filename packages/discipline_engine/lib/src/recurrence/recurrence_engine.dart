// Pure Dart Recurrence Calculation Engine
class RecurrenceEngine {
  /// Calculates the exact next DateTime occurrence for an alarm
  /// [timeOfDay]: "HH:mm" format (e.g., "07:00", "22:30")
  /// [repeatDays]: List of ISO weekdays (1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun). Empty list means one-shot.
  /// [now]: Reference time (defaults to DateTime.now())
  static DateTime calculateNextOccurrence({
    required String timeOfDay,
    List<int> repeatDays = const [],
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final parts = timeOfDay.split(':');
    final targetHour = int.parse(parts[0]);
    final targetMinute = int.parse(parts[1]);

    // 1. One-Shot Alarm (Empty repeatDays)
    if (repeatDays.isEmpty) {
      final todayCandidate = DateTime(
        reference.year,
        reference.month,
        reference.day,
        targetHour,
        targetMinute,
      );

      if (todayCandidate.isAfter(reference)) {
        return todayCandidate;
      } else {
        return todayCandidate.add(const Duration(days: 1));
      }
    }

    // 2. Repeating Alarm across specific ISO weekdays (1 = Monday ... 7 = Sunday)
    // Check if today matches and time is still ahead
    if (repeatDays.contains(reference.weekday)) {
      final todayCandidate = DateTime(
        reference.year,
        reference.month,
        reference.day,
        targetHour,
        targetMinute,
      );

      if (todayCandidate.isAfter(reference)) {
        return todayCandidate;
      }
    }

    // Search future days (1 to 7 days ahead)
    for (int offset = 1; offset <= 7; offset++) {
      final futureDate = reference.add(Duration(days: offset));
      if (repeatDays.contains(futureDate.weekday)) {
        return DateTime(
          futureDate.year,
          futureDate.month,
          futureDate.day,
          targetHour,
          targetMinute,
        );
      }
    }

    // Fallback tomorrow
    return reference.add(const Duration(days: 1));
  }

  /// Formats repeat days into a human-readable string
  static String formatRepeatDays(List<int> days) {
    if (days.isEmpty) return 'Once';
    if (days.length == 7) return 'Every day';
    if (days.length == 5 && [1, 2, 3, 4, 5].every(days.contains)) return 'Weekdays';
    if (days.length == 2 && [6, 7].every(days.contains)) return 'Weekends';

    const dayLabels = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
    final sorted = List<int>.from(days)..sort();
    return sorted.map((d) => dayLabels[d] ?? '').join(', ');
  }
}
