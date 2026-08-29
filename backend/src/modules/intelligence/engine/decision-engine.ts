// Decision & Intelligence Engines
import { ContextEngine, IntelligenceContext } from './context-engine';
import { PatternEngine } from './pattern-engine';

export class DecisionEngine {
  public static evaluateDecision(userId: string, context: IntelligenceContext) {
    if (context.streak >= 7 && context.disciplineScore >= 80) {
      return {
        action: 'MAINTAIN_CADENCE',
        message: 'Your current discipline schedule is balanced and consistent.'
      };
    }
    return {
      action: 'SUGGEST_MOMENTUM_ANCHOR',
      message: 'Focus on 1 core habit anchor to rebuild consistent follow-through.'
    };
  }
}

export class IntelligenceEngine {
  public static synthesizeOverview(userId: string) {
    const context = ContextEngine.assembleContext(userId);
    const patterns = PatternEngine.discoverPatterns(userId);
    const decision = DecisionEngine.evaluateDecision(userId, context);

    return {
      userId,
      context,
      patterns,
      decision
    };
  }
}
