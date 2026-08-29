// Response Validator & Action Parser
import { SafetyFilter } from './safety-filter';
import { DisciplineAIAction } from '../domain/plan.entity';

export class ResponseValidator {
  public static validateResponse(response: any): boolean {
    if (!response || typeof response.message !== 'string') {
      return false;
    }
    if (response.action) {
      const check = SafetyFilter.validateAction(response.action.type);
      return check.isSafe;
    }
    return true;
  }
}

export class ActionParser {
  public static parseAction(rawAction: any): DisciplineAIAction | null {
    if (!rawAction || !rawAction.type) return null;
    const check = SafetyFilter.validateAction(rawAction.type);
    if (!check.isSafe) return null;

    return {
      id: rawAction.id || '',
      type: rawAction.type,
      title: rawAction.title || 'Discipline Proposal',
      message: rawAction.message || '',
      evidence: rawAction.evidence || [],
      confidence: rawAction.confidence || 0.85,
      payload: rawAction.payload,
      status: 'PENDING_APPROVAL',
      createdAt: new Date()
    };
  }
}
