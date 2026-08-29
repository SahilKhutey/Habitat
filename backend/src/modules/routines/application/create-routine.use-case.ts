// Create Routine Application Use Case
import { RoutineEngine } from '../engine/routine-engine';
import { RoutineType } from '../domain/routine.entity';

export interface CreateRoutineCommand {
  userId: string;
  name: string;
  description?: string;
  type: RoutineType;
  minimumRequiredTasks?: number;
  tasks?: {
    taskTemplateId: string;
    sequence: number;
    offsetMinutes?: number;
    required?: boolean;
  }[];
}

export class CreateRoutineUseCase {
  public static execute(command: CreateRoutineCommand) {
    return RoutineEngine.createRoutine(command);
  }
}
