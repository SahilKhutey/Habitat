// Behavior Engine, Event Ingestion & Multi-Signal Performance Calculator
import { DatabaseService } from '../../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { BehaviorEventEntity } from '../domain/behavior-event.entity';
import { DifficultyClassification, TaskPerformanceEntity } from '../domain/task-performance.entity';

export interface BehaviorScoreBreakdown {
  score: number; // 0 - 100
  completionScore: number;
  consistencyScore: number;
  timelinessScore: number;
  proofReliabilityScore: number;
  scheduleStabilityScore: number;
}

export class BehaviorEngine {
  /**
   * Records a behavioral event with strict idempotency
   */
  public static recordEvent(event: {
    userId: string;
    type: string;
    missionId?: string;
    taskId?: string;
    routineId?: string;
    timestamp?: Date;
    metadata?: Record<string, any>;
    idempotencyKey?: string;
  }): { recorded: boolean; isDuplicate: boolean; eventId: string } {
    const db = DatabaseService.getDb();
    const eventId = uuidv4();
    const ts = (event.timestamp || new Date()).toISOString();
    const now = new Date().toISOString();
    const key = event.idempotencyKey || `${event.userId}:${event.type}:${event.missionId || ''}:${ts}`;

    // Check duplicate
    const existing = db.prepare('SELECT id FROM behavior_events WHERE idempotency_key = ?').get(key) as any;
    if (existing) {
      return { recorded: false, isDuplicate: true, eventId: existing.id };
    }

    db.prepare(`
      INSERT INTO behavior_events (id, user_id, type, mission_id, task_id, routine_id, timestamp, metadata, idempotency_key, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      eventId,
      event.userId,
      event.type,
      event.missionId || null,
      event.taskId || null,
      event.routineId || null,
      ts,
      event.metadata ? JSON.stringify(event.metadata) : null,
      key,
      now
    );

    return { recorded: true, isDuplicate: false, eventId };
  }

  /**
   * Calculates comprehensive multi-signal performance for a task
   */
  public static calculateTaskPerformance(params: {
    userId: string;
    taskTemplateId: string;
    startDate?: Date;
    endDate?: Date;
  }): TaskPerformanceEntity {
    const db = DatabaseService.getDb();
    const start = params.startDate || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const end = params.endDate || new Date();

    const taskRow = db.prepare('SELECT name, difficulty FROM tasks WHERE id = ? OR template_id = ?').get(
      params.taskTemplateId,
      params.taskTemplateId
    ) as any;
    const taskName = taskRow?.name || 'Discipline Task';

    const rows = db.prepare(`
      SELECT 
        COUNT(*) as attempts,
        SUM(CASE WHEN status = 'COMPLETED' THEN 1 ELSE 0 END) as completions,
        SUM(CASE WHEN status = 'MISSED' OR status = 'CANCELLED' THEN 1 ELSE 0 END) as misses,
        AVG(CASE WHEN resistance_seconds IS NOT NULL THEN resistance_seconds ELSE 0 END) as avg_delay
      FROM missions
      WHERE user_id = ? AND task_id = ? AND scheduled_at >= ? AND scheduled_at <= ?
    `).get(
      params.userId,
      params.taskTemplateId,
      start.toISOString(),
      end.toISOString()
    ) as any;

    const attempts = rows?.attempts || 0;
    const completions = rows?.completions || 0;
    const misses = rows?.misses || 0;
    const avgDelay = Math.round(rows?.avg_delay || 0);

    const successRate = attempts > 0 ? Number(((completions / attempts) * 100).toFixed(1)) : 100.0;

    // Difficulty score from 0.0 (very easy) to 1.0 (extremely hard)
    let difficultyScore = 0.5;
    let difficultyLevel: DifficultyClassification = 'BALANCED';

    if (attempts >= 5) {
      if (successRate >= 95 && avgDelay < 60) {
        difficultyScore = 0.2;
        difficultyLevel = 'TOO_EASY';
      } else if (successRate >= 85) {
        difficultyScore = 0.35;
        difficultyLevel = 'EASY';
      } else if (successRate >= 65) {
        difficultyScore = 0.55;
        difficultyLevel = 'BALANCED';
      } else if (successRate >= 40) {
        difficultyScore = 0.75;
        difficultyLevel = 'CHALLENGING';
      } else {
        difficultyScore = 0.95;
        difficultyLevel = 'TOO_HARD';
      }
    } else if (attempts === 0) {
      difficultyLevel = 'UNKNOWN';
    }

    return {
      id: uuidv4(),
      userId: params.userId,
      taskTemplateId: params.taskTemplateId,
      taskName,
      periodStart: start,
      periodEnd: end,
      attempts,
      completions,
      misses,
      averageDelaySec: avgDelay,
      averageDurationSec: 60,
      successRate,
      difficultyScore,
      difficultyLevel,
      createdAt: new Date(),
      updatedAt: new Date()
    };
  }

  /**
   * Computes configurable Behavior Score across all signals
   */
  public static calculateBehaviorScore(params: {
    completionRate: number; // 0 - 100
    consistencyRate: number; // 0 - 100
    avgDelaySeconds: number;
    proofRejectionRate?: number; // 0 - 100
    rescheduleCount?: number;
  }): BehaviorScoreBreakdown {
    const timelinessScore = Math.max(0, 100 - Math.round(params.avgDelaySeconds / 6)); // 10 min delay = 0
    const proofReliabilityScore = Math.max(0, 100 - (params.proofRejectionRate || 0));
    const scheduleStabilityScore = Math.max(0, 100 - (params.rescheduleCount || 0) * 10);

    const score = Math.round(
      0.40 * params.completionRate +
      0.25 * params.consistencyRate +
      0.15 * timelinessScore +
      0.10 * proofReliabilityScore +
      0.10 * scheduleStabilityScore
    );

    return {
      score: Math.min(100, Math.max(0, score)),
      completionScore: Math.round(params.completionRate),
      consistencyScore: Math.round(params.consistencyRate),
      timelinessScore,
      proofReliabilityScore,
      scheduleStabilityScore
    };
  }
}
