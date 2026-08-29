// Routines DTOs and Validation Schemas
export interface CreateRoutineDto {
  name: string;
  description?: string;
  category: 'MORNING' | 'EVENING' | 'EXERCISE' | 'STUDY' | 'WORK' | 'HEALTH' | 'CUSTOM';
  scheduleRule: {
    type: 'DAILY' | 'WEEKDAYS' | 'WEEKENDS' | 'CUSTOM';
    startTime: string;
    endTime?: string;
    daysOfWeek?: string[];
    timezone?: string;
  };
  tasks: Array<{
    taskTemplateId: string;
    name: string;
    difficulty: number;
    durationMinutes: number;
    proofType: string;
    order: number;
    isRequired?: boolean;
  }>;
}

export interface UpdateRoutineDto {
  name?: string;
  description?: string;
  scheduleRule?: any;
  tasks?: any[];
}
