// Pattern Intelligence Service
import { PatternEngine } from '../engine/pattern-engine';
import { BehaviorPatternEntity } from '../domain/behavior-pattern.entity';

export class PatternService {
  public static getUserPatterns(userId: string): BehaviorPatternEntity[] {
    return PatternEngine.discoverPatterns(userId);
  }
}
