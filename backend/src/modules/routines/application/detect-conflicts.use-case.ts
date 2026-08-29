// Detect Conflicts Application Use Case
import { ConflictEngine, ScheduledTaskSlot, ScheduleConflict } from '../engine/conflict-engine';

export class DetectConflictsUseCase {
  public static execute(slots: ScheduledTaskSlot[]): ScheduleConflict[] {
    return ConflictEngine.detectConflicts(slots);
  }
}
