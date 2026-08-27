// Timezone-Aware Schedule Calculator
export class ScheduleCalculator {
  private static dayMap: Record<string, number> = {
    MONDAY: 1,
    TUESDAY: 2,
    WEDNESDAY: 3,
    THURSDAY: 4,
    FRIDAY: 5,
    SATURDAY: 6,
    SUNDAY: 7
  };

  /**
   * Computes next occurrence date string (ISO) for a given schedule configuration
   */
  public static calculateNextOccurrence(params: {
    startTime: string; // "07:00" or "07:00:00"
    repeatType: 'ONCE' | 'DAILY' | 'WEEKLY' | 'CUSTOM';
    daysOfWeek?: string[]; // ['MONDAY', 'WEDNESDAY', 'FRIDAY']
    timezone?: string;
    from?: Date;
  }): { nextOccurrence: string; secondsUntil: number } {
    const baseDate = params.from || new Date();
    const parts = params.startTime.split(':').map((p) => parseInt(p, 10));
    const targetHour = parts[0] || 0;
    const targetMinute = parts[1] || 0;

    let candidate = new Date(baseDate.getTime());
    candidate.setHours(targetHour, targetMinute, 0, 0);

    if (params.repeatType === 'ONCE') {
      if (candidate.getTime() <= baseDate.getTime()) {
        candidate.setDate(candidate.getDate() + 1);
      }
    } else if (params.repeatType === 'DAILY') {
      if (candidate.getTime() <= baseDate.getTime()) {
        candidate.setDate(candidate.getDate() + 1);
      }
    } else {
      // WEEKLY or CUSTOM
      const targetDays = (params.daysOfWeek && params.daysOfWeek.length > 0)
        ? params.daysOfWeek.map((d) => this.dayMap[d.toUpperCase()] || 1)
        : [1, 2, 3, 4, 5]; // Default weekdays

      let found = false;
      for (let offset = 0; offset < 8; offset++) {
        const testDate = new Date(candidate.getTime() + offset * 24 * 60 * 60 * 1000);
        let isoDay = testDate.getDay();
        isoDay = isoDay === 0 ? 7 : isoDay;

        if (targetDays.includes(isoDay)) {
          if (testDate.getTime() > baseDate.getTime()) {
            candidate = testDate;
            found = true;
            break;
          }
        }
      }

      if (!found) {
        candidate.setDate(candidate.getDate() + 1);
      }
    }

    const secondsUntil = Math.max(0, Math.round((candidate.getTime() - baseDate.getTime()) / 1000));

    return {
      nextOccurrence: candidate.toISOString(),
      secondsUntil
    };
  }
}
