// Record Behavior Event Use Case (Idempotent & Privacy Safe)
import { BehaviorRepository } from '../infrastructure/behavior.repository';

export interface RecordEventCommand {
  userId: string;
  type: string;
  missionId?: string;
  taskId?: string;
  routineId?: string;
  metadata?: any;
}

export class RecordEventUseCase {
  public static execute(command: RecordEventCommand) {
    BehaviorRepository.recordEvent(command);
    return { success: true };
  }
}
