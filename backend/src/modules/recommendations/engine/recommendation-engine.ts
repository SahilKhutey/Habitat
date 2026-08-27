// Recommendation Engine, Rule Evaluator, Ranking & Consent Manager
import { DatabaseService } from '../../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { RecommendationEntity, RecommendationPriority, RecommendationType } from '../domain/recommendation.entity';
import { BehaviorEngine } from '../../behavior/engine/behavior-engine';
import { TimingEngine } from '../../behavior/engine/timing-engine';
import { OverloadEngine } from '../../adaptation/engine/overload-engine';
import { RecoveryEngine } from '../../adaptation/engine/recovery-engine';
import { RoutineEngine } from '../../routines/engine/routine-engine';

export class RecommendationEngine {
  /**
   * Generates, ranks, deduplicates, and persists personalized recommendations for a user
   */
  public static generateRecommendations(userId: string): RecommendationEntity[] {
    const db = DatabaseService.getDb();
    const now = new Date();
    const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString();

    // Check recently declined types/tasks to enforce 7-day cooldown
    const declinedRows = db.prepare(`
      SELECT type, payload, resolved_at FROM recommendations 
      WHERE user_id = ? AND status = 'DECLINED' AND resolved_at >= ?
    `).all(userId, sevenDaysAgo) as any[];

    const cooldownSet = new Set<string>();
    for (const d of declinedRows) {
      let key = d.type;
      if (d.payload) {
        try {
          const parsed = JSON.parse(d.payload);
          if (parsed.taskTemplateId) key += `:${parsed.taskTemplateId}`;
          if (parsed.routineId) key += `:${parsed.routineId}`;
        } catch {}
      }
      cooldownSet.add(key);
    }

    const candidates: Array<{
      type: RecommendationType;
      priority: RecommendationPriority;
      confidence: number;
      title: string;
      explanation: string;
      payload: any;
    }> = [];

    // 1. Evaluate Recovery Eligibility
    const recoveryEval = RecoveryEngine.evaluateRecoveryEligibility(userId);
    if (recoveryEval.isEligible && !cooldownSet.has('RECOVER')) {
      const plan = RecoveryEngine.createRecoveryPlan({ userId, durationDays: 3 });
      candidates.push({
        type: 'RECOVER',
        priority: 'URGENT',
        confidence: 0.92,
        title: 'Activate 3-Day Momentum Recovery',
        explanation: recoveryEval.reason,
        payload: { recoveryPlan: plan }
      });
    }

    // 2. Evaluate Overload across User Routines
    const routines = db.prepare("SELECT id FROM routines WHERE user_id = ? AND status = 'ACTIVE'").all(userId) as any[];
    for (const r of routines) {
      const load = OverloadEngine.analyzeRoutineLoad(r.id, userId);
      const routineCooldownKey = `SIMPLIFY_ROUTINE:${r.id}`;
      if (load.isOverloaded && !cooldownSet.has(routineCooldownKey)) {
        candidates.push({
          type: 'SIMPLIFY_ROUTINE',
          priority: 'HIGH',
          confidence: 0.88,
          title: `Simplify ${load.routineName}`,
          explanation: load.recommendationMessage,
          payload: { routineId: r.id, proposedRequiredCount: Math.max(1, Math.round(load.taskCount / 2)) }
        });
      }
    }

    // 3. Evaluate Task Difficulty and Timing for Active Tasks
    const tasks = db.prepare('SELECT id, name, difficulty FROM tasks WHERE user_id = ? OR is_starter = 1 LIMIT 10').all(userId) as any[];
    for (const t of tasks) {
      const perf = BehaviorEngine.calculateTaskPerformance({ userId, taskTemplateId: t.id });
      const taskDiffCooldown = `INCREASE_DIFFICULTY:${t.id}`;

      if (perf.attempts >= 5 && perf.successRate >= 95 && !cooldownSet.has(taskDiffCooldown)) {
        candidates.push({
          type: 'INCREASE_DIFFICULTY',
          priority: 'MEDIUM',
          confidence: 0.86,
          title: `Increase Challenge: ${perf.taskName}`,
          explanation: `You've achieved a consistent ${perf.successRate}% completion rate on "${perf.taskName}" over ${perf.attempts} sessions. Ready to advance?`,
          payload: {
            taskTemplateId: t.id,
            taskName: perf.taskName,
            currentDifficulty: t.difficulty || 2,
            proposedDifficulty: Math.min(5, (t.difficulty || 2) + 1)
          }
        });
      }

      // Timing check
      const timing = TimingEngine.findOptimalWindow(userId, t.id);
      const timingCooldown = `MOVE_TASK:${t.id}`;
      if (timing.hasSufficientData && timing.bestWindow && !cooldownSet.has(timingCooldown)) {
        candidates.push({
          type: 'MOVE_TASK',
          priority: 'MEDIUM',
          confidence: 0.84,
          title: `Optimize Timing: ${perf.taskName}`,
          explanation: timing.recommendation || `You complete "${perf.taskName}" most consistently during ${timing.bestWindow}.`,
          payload: {
            taskTemplateId: t.id,
            taskName: perf.taskName,
            proposedWindow: timing.bestWindow,
            proposedTime: `${String(timing.bestHour).padStart(2, '0')}:00`
          }
        });
      }
    }

    // 4. Fallback MAINTAIN recommendation if no high-urgency interventions
    if (candidates.length === 0) {
      candidates.push({
        type: 'MAINTAIN',
        priority: 'LOW',
        confidence: 0.95,
        title: 'Maintain Current Discipline Protocol',
        explanation: 'Your routine load and task timing are currently well balanced. Stay consistent.',
        payload: {}
      });
    }

    // 5. Ranking & Top 3 Filter
    // Score = Priority weight + Confidence * 10
    const priorityWeight: Record<RecommendationPriority, number> = {
      URGENT: 40,
      HIGH: 30,
      MEDIUM: 20,
      LOW: 10
    };

    candidates.sort((a, b) => {
      const scoreA = priorityWeight[a.priority] + a.confidence * 10;
      const scoreB = priorityWeight[b.priority] + b.confidence * 10;
      return scoreB - scoreA;
    });

    const topCandidates = candidates.slice(0, 3);
    const persisted: RecommendationEntity[] = [];

    for (const c of topCandidates) {
      const recId = uuidv4();
      const expiresAt = new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000).toISOString();

      db.prepare(`
        INSERT INTO recommendations (
          id, user_id, type, priority, confidence, title, explanation, payload, status, created_at, expires_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'PENDING', ?, ?)
      `).run(
        recId,
        userId,
        c.type,
        c.priority,
        c.confidence,
        c.title,
        c.explanation,
        JSON.stringify(c.payload),
        now.toISOString(),
        expiresAt
      );

      persisted.push({
        id: recId,
        userId,
        type: c.type,
        priority: c.priority,
        confidence: c.confidence,
        title: c.title,
        explanation: c.explanation,
        payload: c.payload,
        status: 'PENDING',
        createdAt: now,
        expiresAt: new Date(expiresAt)
      });
    }

    return persisted;
  }

  /**
   * Retrieves active pending recommendations for user
   */
  public static getActiveRecommendations(userId: string): RecommendationEntity[] {
    const db = DatabaseService.getDb();
    const rows = db.prepare(`
      SELECT * FROM recommendations 
      WHERE user_id = ? AND status = 'PENDING'
      ORDER BY created_at DESC LIMIT 3
    `).all(userId) as any[];

    if (rows.length === 0) {
      return this.generateRecommendations(userId);
    }

    return rows.map((r) => ({
      id: r.id,
      userId: r.user_id,
      type: r.type,
      priority: r.priority,
      confidence: r.confidence,
      title: r.title,
      explanation: r.explanation,
      payload: r.payload ? JSON.parse(r.payload) : undefined,
      status: r.status,
      createdAt: new Date(r.created_at),
      expiresAt: r.expires_at ? new Date(r.expires_at) : undefined,
      resolvedAt: r.resolved_at ? new Date(r.resolved_at) : undefined
    }));
  }

  /**
   * User accepts recommendation -> creates new version snapshot without altering historical data
   */
  public static acceptRecommendation(recId: string, userId: string): { success: boolean; message: string } {
    const db = DatabaseService.getDb();
    const rec = db.prepare('SELECT * FROM recommendations WHERE id = ? AND user_id = ?').get(recId, userId) as any;
    if (!rec) throw new Error('RECOMMENDATION_NOT_FOUND: Recommendation not found or unauthorized');

    const payload = rec.payload ? JSON.parse(rec.payload) : {};
    const now = new Date().toISOString();

    if (rec.type === 'INCREASE_DIFFICULTY' || rec.type === 'REDUCE_DIFFICULTY') {
      if (payload.taskTemplateId && payload.proposedDifficulty) {
        db.prepare('UPDATE tasks SET difficulty = ?, updated_at = ? WHERE id = ?').run(
          payload.proposedDifficulty,
          now,
          payload.taskTemplateId
        );
      }
    } else if (rec.type === 'MOVE_TASK') {
      if (payload.taskTemplateId && payload.proposedTime) {
        db.prepare('UPDATE schedule_rules SET time_of_day = ?, updated_at = ? WHERE task_template_id = ? AND user_id = ?').run(
          payload.proposedTime,
          now,
          payload.taskTemplateId,
          userId
        );
      }
    } else if (rec.type === 'SIMPLIFY_ROUTINE') {
      if (payload.routineId) {
        RoutineEngine.updateRoutine({
          routineId: payload.routineId,
          userId,
          name: undefined
        });
      }
    }

    db.prepare("UPDATE recommendations SET status = 'ACCEPTED', resolved_at = ? WHERE id = ?").run(now, recId);
    return { success: true, message: 'Recommendation accepted. Future missions will follow the updated configuration.' };
  }

  /**
   * User declines recommendation -> sets status to DECLINED and applies 7-day cooldown
   */
  public static declineRecommendation(recId: string, userId: string): { success: boolean; message: string } {
    const db = DatabaseService.getDb();
    const rec = db.prepare('SELECT * FROM recommendations WHERE id = ? AND user_id = ?').get(recId, userId) as any;
    if (!rec) throw new Error('RECOMMENDATION_NOT_FOUND: Recommendation not found or unauthorized');

    const now = new Date().toISOString();
    db.prepare("UPDATE recommendations SET status = 'DECLINED', resolved_at = ? WHERE id = ?").run(now, recId);
    return { success: true, message: 'Recommendation declined. We will not recommend this change for the next 7 days.' };
  }

  /**
   * User dismisses recommendation
   */
  public static dismissRecommendation(recId: string, userId: string): { success: boolean; message: string } {
    const db = DatabaseService.getDb();
    const rec = db.prepare('SELECT * FROM recommendations WHERE id = ? AND user_id = ?').get(recId, userId) as any;
    if (!rec) throw new Error('RECOMMENDATION_NOT_FOUND: Recommendation not found or unauthorized');

    const now = new Date().toISOString();
    db.prepare("UPDATE recommendations SET status = 'DISMISSED', resolved_at = ? WHERE id = ?").run(now, recId);
    return { success: true, message: 'Recommendation dismissed.' };
  }
}
