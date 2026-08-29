// Recommendation & Recovery Services
import { DatabaseService } from '../../../db/connection';
import { v4 as uuidv4 } from 'uuid';
import { FailureAnalysisEngine } from '../engine/failure-analysis';

export class RecommendationService {
  public static getRecommendations(userId: string) {
    const db = DatabaseService.getDb();
    return db.prepare("SELECT * FROM recommendations WHERE user_id = ? AND status = 'PENDING'").all(userId);
  }

  public static acceptRecommendation(id: string, userId: string) {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();
    db.prepare("UPDATE recommendations SET status = 'ACCEPTED', resolved_at = ? WHERE id = ? AND user_id = ?").run(now, id, userId);
    return { id, status: 'ACCEPTED' };
  }

  public static rejectRecommendation(id: string, userId: string) {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();
    db.prepare("UPDATE recommendations SET status = 'DECLINED', resolved_at = ? WHERE id = ? AND user_id = ?").run(now, id, userId);
    return { id, status: 'DECLINED' };
  }
}

export class RecoveryService {
  public static generateRecoveryPlan(userId: string, taskId: string) {
    return FailureAnalysisEngine.analyzeTaskFailure(userId, taskId);
  }
}
