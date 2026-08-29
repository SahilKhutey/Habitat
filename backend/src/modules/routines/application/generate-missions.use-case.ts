// Generate Missions Application Use Case
import { SchedulingEngine } from '../engine/scheduling-engine';

export class GenerateMissionsUseCase {
  public static execute(userId: string, startDate?: Date, endDate?: Date, timezone?: string) {
    const start = startDate || new Date();
    const end = endDate || new Date(start.getTime() + 7 * 24 * 60 * 60 * 1000);

    return SchedulingEngine.generateMissions({
      userId,
      startDate: start,
      endDate: end,
      timezone: timezone || 'UTC'
    });
  }
}
