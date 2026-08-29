// Routine Instance Domain Entity
export interface RoutineInstanceEntity {
  id: string;
  userId: string;
  routineId: string;
  version: number;
  scheduledDate: string;
  status: 'PENDING' | 'IN_PROGRESS' | 'COMPLETED' | 'MISSED';
  totalTasks: number;
  completedTasks: number;
  createdAt: Date;
  updatedAt: Date;
}
