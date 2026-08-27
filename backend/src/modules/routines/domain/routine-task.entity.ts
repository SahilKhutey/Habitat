// Routine Task & Item Domain Entity

export interface RoutineTaskEntity {
  id: string;
  routineId: string;
  taskTemplateId: string;
  sequence: number;
  offsetMinutes: number;
  required: boolean;
  name?: string;
  proofType?: string;
  difficulty?: number;
  baseXp?: number;
  createdAt: Date;
}
