// Behavior Pattern Detection & Confidence Scoring Engine
import { DatabaseService } from '../../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { BehaviorPatternEntity, PatternClassification } from '../domain/behavior-pattern.entity';

export class PatternEngine {
  /**
   * Analyzes user behavioral events and discovers recurring habits & friction patterns
   */
  public static discoverPatterns(userId: string): BehaviorPatternEntity[] {
    const db = DatabaseService.getDb();
    const patterns: BehaviorPatternEntity[] = [];
    const now = new Date();

    // 1. Morning vs Evening Completion Pattern
    const missions = db.prepare(`
      SELECT 
        scheduled_at,
        status
      FROM missions
      WHERE user_id = ?
    `).all(userId) as any[];

    const sampleSize = missions.length;
    if (sampleSize < 5) {
      return [
        {
          id: uuidv4(),
          userId,
          patternType: 'INSUFFICIENT_DATA',
          confidence: 0.0,
          sampleSize,
          periodDays: 30,
          evidence: ['Need at least 5 completed or scheduled missions to compute reliable behavioral patterns.'],
          classification: 'INSUFFICIENT_DATA',
          createdAt: now
        }
      ];
    }

    let morningTotal = 0;
    let morningCompleted = 0;
    let eveningTotal = 0;
    let eveningCompleted = 0;

    for (const m of missions) {
      const hour = new Date(m.scheduled_at).getUTCHours();
      const isCompleted = m.status === 'COMPLETED';

      if (hour >= 5 && hour < 11) {
        morningTotal++;
        if (isCompleted) morningCompleted++;
      } else if (hour >= 19 || hour < 2) {
        eveningTotal++;
        if (isCompleted) eveningCompleted++;
      }
    }

    const morningRate = morningTotal > 0 ? morningCompleted / morningTotal : 0;
    const eveningRate = eveningTotal > 0 ? eveningCompleted / eveningTotal : 0;

    if (morningTotal >= 3 && morningRate >= 0.8) {
      const confidence = Math.min(0.95, 0.70 + (morningTotal / 50) * 0.25);
      const pattern: BehaviorPatternEntity = {
        id: uuidv4(),
        userId,
        patternType: 'MORNING_STRENGTH',
        confidence: Number(confidence.toFixed(2)),
        sampleSize: morningTotal,
        periodDays: 30,
        evidence: [
          `Completed ${morningCompleted} of ${morningTotal} morning missions (${Math.round(morningRate * 100)}%).`,
          'Morning execution velocity demonstrates high discipline momentum.'
        ],
        classification: confidence >= 0.8 ? 'OBSERVED' : 'LIKELY',
        createdAt: now
      };
      patterns.push(pattern);
      this.persistPattern(pattern);
    }

    if (eveningTotal >= 3 && eveningRate < 0.6) {
      const confidence = Math.min(0.92, 0.65 + (eveningTotal / 50) * 0.25);
      const pattern: BehaviorPatternEntity = {
        id: uuidv4(),
        userId,
        patternType: 'EVENING_FRICTION',
        confidence: Number(confidence.toFixed(2)),
        sampleSize: eveningTotal,
        periodDays: 30,
        evidence: [
          `Evening mission completion rate drops to ${Math.round(eveningRate * 100)}% (${eveningCompleted}/${eveningTotal}).`,
          'Late tasks exhibit friction due to accumulated cognitive fatigue.'
        ],
        classification: 'OBSERVED',
        createdAt: now
      };
      patterns.push(pattern);
      this.persistPattern(pattern);
    }

    return patterns;
  }

  private static persistPattern(pattern: BehaviorPatternEntity) {
    const db = DatabaseService.getDb();
    db.prepare(`
      INSERT OR REPLACE INTO behavior_patterns (
        id, user_id, pattern_type, confidence, sample_size, period_days, evidence, classification, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      pattern.id,
      pattern.userId,
      pattern.patternType,
      pattern.confidence,
      pattern.sampleSize,
      pattern.periodDays,
      JSON.stringify(pattern.evidence),
      pattern.classification,
      pattern.createdAt.toISOString()
    );
  }
}
