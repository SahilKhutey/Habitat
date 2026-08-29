// Failure Analysis & Non-Punitive Recovery Engine
import { DatabaseService } from '../../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { DisciplineAIAction } from '../domain/plan.entity';

export type FrictionType =
  | 'TIME_CONFLICT'
  | 'TASK_TOO_LONG'
  | 'TOO_FREQUENT'
  | 'LOW_MOTIVATION'
  | 'UNCLEAR_INSTRUCTION'
  | 'PROOF_FRICTION'
  | 'NOT_RELEVANT'
  | 'SCHEDULING_PROBLEM'
  | 'UNKNOWN';

export interface FailureInsight {
  taskId: string;
  taskTitle: string;
  missCount: number;
  totalAttempts: number;
  frictionType: FrictionType;
  explanation: string;
  recoveryAction?: DisciplineAIAction;
}

export class FailureAnalysisEngine {
  /**
   * Analyzes missed tasks and formulates an explainable friction diagnostic and 1 recovery proposal
   */
  public static analyzeTaskFailure(userId: string, taskId: string): FailureInsight {
    const db = DatabaseService.getDb();
    const task = db.prepare('SELECT * FROM tasks WHERE id = ?').get(taskId) as any;
    const taskTitle = task ? task.name || task.title : 'Discipline Mission';

    const missions = db.prepare(`
      SELECT * FROM missions
      WHERE user_id = ? AND task_id = ?
      ORDER BY scheduled_at DESC
      LIMIT 10
    `).all(userId, taskId) as any[];

    let missCount = 0;
    for (const m of missions) {
      if (m.status === 'MISSED' || m.status === 'FAILED') {
        missCount++;
      }
    }

    const totalAttempts = missions.length || 1;
    let frictionType: FrictionType = 'SCHEDULING_PROBLEM';
    let explanation = `This task has encountered friction (${missCount} misses in recent attempts). Often, timing adjustments or duration simplification help build execution momentum.`;

    if (missCount >= 3) {
      frictionType = 'TIME_CONFLICT';
      explanation = `You missed this task ${missCount} of recent attempts. Data indicates this window often overlaps with competing daily demands.`;
    }

    const recoveryAction: DisciplineAIAction = {
      id: uuidv4(),
      type: 'PROPOSE_RECOVERY',
      title: `Momentum Recovery: 5-Min ${taskTitle}`,
      message: `Complete a streamlined 5-minute session today at 18:00 to keep your momentum active.`,
      evidence: [`Encountered ${missCount} missed occurrences at original schedule`],
      confidence: 0.88,
      payload: {
        originalTaskId: taskId,
        recoveryTime: '18:00',
        recoveryDurationMinutes: 5
      },
      status: 'PENDING_APPROVAL',
      createdAt: new Date()
    };

    return {
      taskId,
      taskTitle,
      missCount,
      totalAttempts,
      frictionType,
      explanation,
      recoveryAction
    };
  }
}
