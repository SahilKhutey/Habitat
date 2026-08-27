// Recurrence Engine & Day Matching Evaluator
import { ScheduleRuleEntity } from '../domain/schedule-rule.entity';

export class RecurrenceEngine {
  /**
   * Checks if a schedule rule occurs on a given date in the target timezone
   */
  public static occursOn(rule: ScheduleRuleEntity, date: Date): boolean {
    if (!rule.enabled) return false;

    // Resolve date in rule's timezone (format "YYYY-MM-DD")
    const dateStr = new Intl.DateTimeFormat('en-CA', {
      timeZone: rule.timezone || 'UTC',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit'
    }).format(date);

    if (rule.startDate && dateStr < rule.startDate.substring(0, 10)) return false;
    if (rule.endDate && dateStr > rule.endDate.substring(0, 10)) return false;

    // Get day of week in timezone: 1 = Monday .. 7 = Sunday
    const weekdayStr = new Intl.DateTimeFormat('en-US', {
      timeZone: rule.timezone || 'UTC',
      weekday: 'short'
    }).format(date);

    const dayMap: Record<string, number> = {
      Mon: 1,
      Tue: 2,
      Wed: 3,
      Thu: 4,
      Fri: 5,
      Sat: 6,
      Sun: 7
    };
    const dayOfWeek = dayMap[weekdayStr] || 1;

    switch (rule.scheduleType) {
      case 'ONCE':
        return rule.startDate ? rule.startDate.substring(0, 10) === dateStr : true;

      case 'DAILY':
        return true;

      case 'WEEKDAYS':
        return dayOfWeek >= 1 && dayOfWeek <= 5;

      case 'WEEKENDS':
        return dayOfWeek === 6 || dayOfWeek === 7;

      case 'WEEKLY':
      case 'CUSTOM':
        if (rule.daysOfWeek && rule.daysOfWeek.length > 0) {
          return rule.daysOfWeek.includes(dayOfWeek);
        }
        return true;

      default:
        return true;
    }
  }

  /**
   * Computes the next occurrence timestamp after a given date
   */
  public static nextOccurrence(rule: ScheduleRuleEntity, after: Date): Date | null {
    if (!rule.enabled) return null;

    let current = new Date(after.getTime() + 60 * 1000); // Start 1 min after
    const maxHorizonDays = 60;

    for (let i = 0; i < maxHorizonDays; i++) {
      if (this.occursOn(rule, current)) {
        // Construct date at timeOfDay
        const dateStr = new Intl.DateTimeFormat('en-CA', {
          timeZone: rule.timezone || 'UTC',
          year: 'numeric',
          month: '2-digit',
          day: '2-digit'
        }).format(current);

        const timeStr = rule.timeOfDay || '07:00';
        const [hh, mm] = timeStr.split(':').map((n) => parseInt(n, 10));

        // Create Date object matching target timezone hour & minute
        const candidate = new Date(`${dateStr}T${String(hh).padStart(2, '0')}:${String(mm).padStart(2, '0')}:00.000Z`);
        if (candidate > after) {
          return candidate;
        }
      }
      current = new Date(current.getTime() + 24 * 60 * 60 * 1000);
    }

    return null;
  }
}
