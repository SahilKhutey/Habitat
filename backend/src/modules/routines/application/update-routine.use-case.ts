// Update Routine Application Use Case (Version-Preserving)
import { RoutineEngine } from '../engine/routine-engine';
import { RoutineStatus } from '../domain/routine.entity';

export interface UpdateRoutineCommand {
  routineId: string;
  userId: string;
  name?: string;
  description?: string;
  status?: RoutineStatus;
  minimumRequiredTasks?: number;
  tasks?: {
    taskTemplateId: string;
    sequence: number;
    offsetMinutes?: number;
    required?: boolean;
  }[];
}

export class UpdateRoutineUseCase {
  public static execute(command: UpdateRoutineCommand) {
    return RoutineEngine.updateRoutine(command);
  }
}
