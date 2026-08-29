// Delete (Logical Archival) Routine Use Case
import { RoutineEngine } from '../engine/routine-engine';

export class DeleteRoutineUseCase {
  public static execute(routineId: string, userId: string) {
    return RoutineEngine.updateRoutine({
      routineId,
      userId,
      status: 'ARCHIVED'
    });
  }
}
