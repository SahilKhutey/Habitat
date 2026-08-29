// AI Discipline Coach Service
import { DatabaseService } from '../../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { ContextEngine } from '../engine/context-engine';
import { MockAIProvider } from '../ai/ai-provider';
import { SafetyFilter } from '../ai/safety-filter';
import { CoachMessageEntity, CoachSessionEntity } from '../domain/plan.entity';

export class CoachingService {
  private static provider = new MockAIProvider();

  /**
   * Starts a new coach session
   */
  public static startSession(userId: string): CoachSessionEntity {
    const db = DatabaseService.getDb();
    const sessionId = uuidv4();
    const now = new Date();

    db.prepare(`
      INSERT INTO coach_sessions (id, user_id, started_at, summary, created_at)
      VALUES (?, ?, ?, 'Discipline Session', ?)
    `).run(sessionId, userId, now.toISOString(), now.toISOString());

    return {
      id: sessionId,
      userId,
      startedAt: now,
      summary: 'Discipline Session',
      createdAt: now
    };
  }

  /**
   * Processes a user message to the Coach, gathers context, verifies safety, and returns AI response
   */
  public static async processMessage(params: {
    userId: string;
    sessionId?: string;
    message: string;
  }): Promise<{ userMessage: CoachMessageEntity; assistantMessage: CoachMessageEntity; action?: any }> {
    const db = DatabaseService.getDb();
    const now = new Date();
    const sessionId = params.sessionId || this.startSession(params.userId).id;

    // 1. Record User Message
    const userMsgId = uuidv4();
    db.prepare(`
      INSERT INTO coach_messages (id, session_id, user_id, role, content, created_at)
      VALUES (?, ?, ?, 'user', ?, ?)
    `).run(userMsgId, sessionId, params.userId, params.message, now.toISOString());

    const userMessage: CoachMessageEntity = {
      id: userMsgId,
      sessionId,
      userId: params.userId,
      role: 'user',
      content: params.message,
      createdAt: now
    };

    // 2. Assemble sanitized context
    const context = ContextEngine.assembleContext(params.userId);

    // 3. Generate structured AI response
    const aiResponse = await this.provider.generateResponse({
      userMessage: params.message,
      context
    });

    // 4. Validate any proposed action with SafetyFilter
    let action = aiResponse.action;
    if (action) {
      const safetyCheck = SafetyFilter.validateAction(action.type);
      if (!safetyCheck.isSafe) {
        action = undefined;
      }
    }

    // 5. Record Assistant Message
    const assistantMsgId = uuidv4();
    db.prepare(`
      INSERT INTO coach_messages (id, session_id, user_id, role, content, metadata, created_at)
      VALUES (?, ?, ?, 'assistant', ?, ?, ?)
    `).run(
      assistantMsgId,
      sessionId,
      params.userId,
      aiResponse.message,
      action ? JSON.stringify(action) : null,
      new Date().toISOString()
    );

    const assistantMessage: CoachMessageEntity = {
      id: assistantMsgId,
      sessionId,
      userId: params.userId,
      role: 'assistant',
      content: aiResponse.message,
      metadata: action,
      createdAt: new Date()
    };

    return {
      userMessage,
      assistantMessage,
      action
    };
  }

  /**
   * Retrieves message history for a session
   */
  public static getSessionHistory(sessionId: string): CoachMessageEntity[] {
    const db = DatabaseService.getDb();
    const rows = db.prepare(`
      SELECT * FROM coach_messages
      WHERE session_id = ?
      ORDER BY created_at ASC
    `).all(sessionId) as any[];

    return rows.map((r) => ({
      id: r.id,
      sessionId: r.session_id,
      userId: r.user_id,
      role: r.role,
      content: r.content,
      metadata: r.metadata ? JSON.parse(r.metadata) : undefined,
      createdAt: new Date(r.created_at)
    }));
  }
}
