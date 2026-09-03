// AI Provider Interface, Action Parser & Mock Implementation
import { IntelligenceContext } from '../engine/context-engine';
import { DisciplineAIAction } from '../domain/plan.entity';
import { SafetyFilter } from './safety-filter';
import { v4 as uuidv4 } from 'uuid';

export interface AIRequest {
  userMessage: string;
  context: IntelligenceContext;
  requestedActionType?: string;
}

export interface AIResponse {
  message: string;
  action?: DisciplineAIAction;
  confidence: number;
  evidence: string[];
}

export interface AIProvider {
  generateResponse(request: AIRequest): Promise<AIResponse>;
}

export class DeterministicRuleAIProvider implements AIProvider {
  public async generateResponse(request: AIRequest): Promise<AIResponse> {
    const cleanMessage = SafetyFilter.sanitizeInput(request.userMessage).toLowerCase();

    // Check prompt injection or malicious command attempts
    if (cleanMessage.includes('delete my tasks') || cleanMessage.includes('ignore all previous')) {
      return {
        message: "I cannot execute destructive system actions. I am your discipline assistant designed to help plan, optimize routines, and review progress.",
        confidence: 1.0,
        evidence: ['Adherence to system safety policy']
      };
    }

    if (cleanMessage.includes('why am i struggling') || cleanMessage.includes('why did i fail') || cleanMessage.includes('miss')) {
      return {
        message: "Observation: Tasks scheduled late in the evening show higher friction due to cognitive fatigue. Moving key commitments earlier by 30 minutes significantly increases completion reliability.",
        confidence: 0.89,
        evidence: ['Historical completion drops after 21:30', 'Morning completion rate is 91%'],
        action: {
          id: uuidv4(),
          type: 'PROPOSE_SCHEDULE_CHANGE',
          title: 'Optimize Schedule Window',
          message: 'Move high-friction evening commitments 30 minutes earlier',
          evidence: ['91% morning consistency vs 48% late evening'],
          confidence: 0.89,
          status: 'PENDING_APPROVAL',
          createdAt: new Date()
        }
      };
    }

    if (cleanMessage.includes('plan') || cleanMessage.includes('today')) {
      return {
        message: `Here is your structured plan for today. You have ${request.context.todayTasks.length || 3} primary commitments scheduled. Your first focus block starts at 07:00.`,
        confidence: 0.95,
        evidence: [`${request.context.todayTasks.length} tasks scheduled on ${request.context.date}`],
        action: {
          id: uuidv4(),
          type: 'SHOW_PLAN',
          title: "Today's Structured Schedule",
          message: 'Review and approve your daily discipline plan',
          evidence: ['Derived from active routines and personal goals'],
          confidence: 0.95,
          status: 'PENDING_APPROVAL',
          createdAt: new Date()
        }
      };
    }

    if (cleanMessage.includes('simplify') || cleanMessage.includes('overload')) {
      return {
        message: "I recommend streamlining your routine to 3 core non-negotiable anchors (Hydration, Morning Movement, Brushing) to restore consistency.",
        confidence: 0.92,
        evidence: ['Reduces cognitive friction while preserving streak tokens'],
        action: {
          id: uuidv4(),
          type: 'PROPOSE_ROUTINE_CHANGE',
          title: 'Streamline to Core Anchors',
          message: 'Focus exclusively on primary habit anchors for 3 days',
          evidence: ['Protects discipline streak and prevents habit burnout'],
          confidence: 0.92,
          status: 'PENDING_APPROVAL',
          createdAt: new Date()
        }
      };
    }

    // Default conversational response
    return {
      message: `Good day! You have maintained an active streak of ${request.context.streak} days with a discipline score of ${request.context.disciplineScore}%. How can I support your focus today?`,
      confidence: 0.90,
      evidence: [`Discipline Score: ${request.context.disciplineScore}%`, `Current Streak: ${request.context.streak}`]
    };
  }
}

export const MockAIProvider = DeterministicRuleAIProvider;
