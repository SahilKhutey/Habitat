// Schedule Rule, Task Dependency & Rest Day Domain Entities

export type ScheduleType = 'ONCE' | 'DAILY' | 'WEEKLY' | 'WEEKDAYS' | 'WEEKENDS' | 'CUSTOM';

export interface ScheduleRuleEntity {
  id: string;
  userId: string;
  routineId?: string;
  taskTemplateId?: string;
  scheduleType: ScheduleType;
  timeOfDay?: string; // e.g. "07:00"
  scheduleWindowStart?: string; // e.g. "06:45"
  scheduleWindowEnd?: string; // e.g. "07:30"
  daysOfWeek?: number[]; // [1, 2, 3, 4, 5] (Monday=1 .. Sunday=7)
  startDate?: string;
  endDate?: string;
  timezone: string;
  enabled: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export type DependencyType = 'HARD' | 'SOFT';

export interface TaskDependencyEntity {
  id: string;
  routineId?: string;
  prerequisiteId: string;
  dependentId: string;
  dependencyType: DependencyType;
  createdAt: Date;
}

export interface RestDayEntity {
  id: string;
  userId: string;
  date: string; // "YYYY-MM-DD"
  reason?: string;
  createdAt: Date;
}
