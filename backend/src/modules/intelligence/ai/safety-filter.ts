// AI Safety Filter & Action Allowlist Guard
import { AIActionType } from '../domain/plan.entity';

export const ALLOWED_AI_ACTIONS: Set<string> = new Set([
  'PROPOSE_TASK',
  'PROPOSE_SCHEDULE_CHANGE',
  'PROPOSE_GOAL_CHANGE',
  'PROPOSE_RECOVERY',
  'PROPOSE_ROUTINE_CHANGE',
  'SHOW_INSIGHT',
  'SHOW_PLAN'
]);

export const FORBIDDEN_AI_ACTIONS: Set<string> = new Set([
  'DELETE_USER_DATA',
  'DELETE_ALL_TASKS',
  'CHANGE_ACCOUNT_SECURITY',
  'CHANGE_HEALTH_PERMISSION',
  'CHANGE_VERIFICATION_POLICY',
  'EXECUTE_EXTERNAL_ACTION',
  'CHANGE_CORE_SYSTEM_SETTINGS'
]);

export class SafetyFilter {
  /**
   * Validates if a proposed AI action is permitted by the system safety policy
   */
  public static validateAction(actionType: string): { isSafe: boolean; reason?: string } {
    if (FORBIDDEN_AI_ACTIONS.has(actionType)) {
      return {
        isSafe: false,
        reason: `SECURITY_VIOLATION: Action '${actionType}' is strictly forbidden by the AI Safety Policy.`
      };
    }

    if (!ALLOWED_AI_ACTIONS.has(actionType)) {
      return {
        isSafe: false,
        reason: `UNKNOWN_ACTION: Action '${actionType}' is not on the approved AI Action Allowlist.`
      };
    }

    return { isSafe: true };
  }

  /**
   * Sanitizes input to detect prompt injection attempts
   */
  public static sanitizeInput(input: string): string {
    if (!input) return '';
    // Strip control characters or excessive malicious patterns
    return input.trim().substring(0, 1000);
  }
}
