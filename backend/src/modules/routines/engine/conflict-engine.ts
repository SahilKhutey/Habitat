// Schedule Conflict Detection & Severity Classifier

export interface ScheduledTaskSlot {
  id: string;
  name: string;
  startTime: Date;
  endTime: Date;
  routineId?: string;
  isMandatory?: boolean;
}

export type ConflictSeverity = 'LOW' | 'MEDIUM' | 'HIGH';

export interface ScheduleConflict {
  conflict: boolean;
  type: 'OVERLAP' | 'RESOURCE_COLLISION';
  severity: ConflictSeverity;
  overlapMinutes: number;
  taskA: { id: string; name: string; start: string; end: string };
  taskB: { id: string; name: string; start: string; end: string };
  resolutionOptions: string[];
}

export class ConflictEngine {
  /**
   * Evaluates pairwise slots for overlapping time windows
   */
  public static detectConflicts(slots: ScheduledTaskSlot[]): ScheduleConflict[] {
    const conflicts: ScheduleConflict[] = [];

    // Sort by startTime
    const sorted = [...slots].sort((a, b) => a.startTime.getTime() - b.startTime.getTime());

    for (let i = 0; i < sorted.length; i++) {
      for (let j = i + 1; j < sorted.length; j++) {
        const slotA = sorted[i];
        const slotB = sorted[j];

        // Check if B starts before A ends
        if (slotB.startTime < slotA.endTime) {
          const overlapMs = Math.min(slotA.endTime.getTime(), slotB.endTime.getTime()) - slotB.startTime.getTime();
          const overlapMinutes = Math.max(1, Math.round(overlapMs / (60 * 1000)));

          let severity: ConflictSeverity = 'LOW';
          if (overlapMinutes > 15 || (slotA.isMandatory && slotB.isMandatory)) {
            severity = 'HIGH';
          } else if (overlapMinutes > 5) {
            severity = 'MEDIUM';
          }

          conflicts.push({
            conflict: true,
            type: 'OVERLAP',
            severity,
            overlapMinutes,
            taskA: {
              id: slotA.id,
              name: slotA.name,
              start: slotA.startTime.toISOString(),
              end: slotA.endTime.toISOString()
            },
            taskB: {
              id: slotB.id,
              name: slotB.name,
              start: slotB.startTime.toISOString(),
              end: slotB.endTime.toISOString()
            },
            resolutionOptions: ['Move Task', 'Adjust Window', 'Keep Both', 'Cancel One']
          });
        }
      }
    }

    return conflicts;
  }
}
