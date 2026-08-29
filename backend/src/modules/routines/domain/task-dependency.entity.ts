// Task Dependency Domain Entity
export interface TaskDependencyEntity {
  id: string;
  routineId: string;
  prerequisiteTaskId: string;
  dependentTaskId: string;
  dependencyType: 'HARD' | 'SOFT';
}
