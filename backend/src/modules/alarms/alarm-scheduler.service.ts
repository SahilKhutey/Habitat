// Timezone-Aware Alarm Scheduler & Volume Escalation Engine

export class AlarmSchedulerService {
  /**
   * Computes the exact ISO 8601 string for the next occurrence of an alarm.
   * repeatDays: [1, 2, 3, 4, 5] where 1 = Monday, 7 = Sunday (ISO week days)
   */
  public static calculateNextOccurrence(params: {
    timeOfDay: string; // e.g. "07:00" or "07:00:00"
    repeatDays?: number[];
    timezone?: string;
    from?: Date;
  }): { nextOccurrence: string; secondsUntil: number } {
    const baseDate = params.from || new Date();
    const parts = params.timeOfDay.split(':').map((p) => parseInt(p, 10));
    const targetHours = parts[0] || 0;
    const targetMinutes = parts[1] || 0;
    const targetSeconds = parts[2] || 0;

    const repeatDays = (params.repeatDays && params.repeatDays.length > 0)
      ? params.repeatDays
      : []; // empty means single shot

    let candidate = new Date(baseDate.getTime());
    candidate.setHours(targetHours, targetMinutes, targetSeconds, 0);

    if (repeatDays.length === 0) {
      // One-off alarm: if today's time has already passed, schedule for tomorrow
      if (candidate.getTime() <= baseDate.getTime()) {
        candidate.setDate(candidate.getDate() + 1);
      }
    } else {
      // Recurring alarm: find the next day matching repeatDays
      for (let i = 0; i < 8; i++) {
        const testDate = new Date(candidate.getTime() + i * 24 * 60 * 60 * 1000);
        let isoDay = testDate.getDay();
        isoDay = isoDay === 0 ? 7 : isoDay; // Convert 0 (Sun) to 7 (Sun)

        if (repeatDays.includes(isoDay)) {
          if (testDate.getTime() > baseDate.getTime()) {
            candidate = testDate;
            break;
          }
        }
      }
    }

    const secondsUntil = Math.max(0, Math.round((candidate.getTime() - baseDate.getTime()) / 1000));

    return {
      nextOccurrence: candidate.toISOString(),
      secondsUntil
    };
  }

  /**
   * Determines escalating siren volume levels for repeated attempts
   */
  public static getEscalationVolume(attemptIndex: number, mode: string = 'DISCIPLINE'): number {
    if (mode === 'GENTLE') {
      return Math.min(80, 60 + attemptIndex * 10);
    }
    if (mode === 'HARDCORE') {
      // Rapid escalation to max 100dB
      switch (attemptIndex) {
        case 1: return 75;
        case 2: return 90;
        default: return 100;
      }
    }
    // Standard Discipline Mode
    switch (attemptIndex) {
      case 1: return 70;
      case 2: return 85;
      default: return 95;
    }
  }
}
