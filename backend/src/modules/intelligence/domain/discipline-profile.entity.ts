// Personal Discipline Profile Domain Entity

export type CoachingStyle = 'DIRECT' | 'ENCOURAGING' | 'CHALLENGE' | 'PROGRESS' | 'MINIMAL';
export type PlanningAutonomy = 'MANUAL' | 'ASSISTED' | 'SMART';

export interface DisciplineProfileEntity {
  id: string;
  userId: string;
  preferredWake: string; // "06:30"
  preferredSleep: string; // "22:30"
  consistency: number; // 0-100
  completionRate: number; // 0-100
  preferredDays: string[]; // ["MONDAY", "TUESDAY", ...]
  preferredTimes: {
    peakFocusWindow: string; // "07:00-09:00"
    exerciseWindow: string; // "07:00"
  };
  strengths: string[];
  frictionPoints: string[];
  coachingStyle: CoachingStyle;
  planningAutonomy: PlanningAutonomy;
  version: number;
  createdAt: Date;
  updatedAt: Date;
}
