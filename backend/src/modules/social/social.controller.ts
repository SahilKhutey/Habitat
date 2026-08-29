// Social Connections, Privacy Guard & Moderation Controller
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';

export const socialController = Router();

export class SocialService {
  /**
   * Sends a friend request or establishes a relationship
   */
  public static addRelationship(userId: string, targetUserId: string, type: 'FRIEND' | 'BLOCKED' | 'PENDING') {
    if (userId === targetUserId) {
      throw new Error('INVALID_TARGET: Cannot establish relationship with yourself');
    }

    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT OR REPLACE INTO social_relationships (id, user_id, target_user_id, relationship_type, created_at)
      VALUES (?, ?, ?, ?, ?)
    `).run(id, userId, targetUserId, type, now);

    return { success: true, userId, targetUserId, type };
  }

  /**
   * Blocks a user, preventing all interactions
   */
  public static blockUser(userId: string, targetUserId: string) {
    return this.addRelationship(userId, targetUserId, 'BLOCKED');
  }

  /**
   * Reports offensive or inappropriate content to the moderation queue
   */
  public static reportContent(params: {
    reporterId: string;
    targetId: string;
    targetType: string;
    reason: string;
  }) {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO content_reports (id, reporter_id, target_id, target_type, reason, status, created_at)
      VALUES (?, ?, ?, ?, ?, 'PENDING', ?)
    `).run(id, params.reporterId, params.targetId, params.targetType, params.reason, now);

    return { reportId: id, status: 'PENDING' };
  }

  /**
   * Retrieves active friends for a user, filtering out blocked contacts
   */
  public static getFriends(userId: string) {
    const db = DatabaseService.getDb();
    const rows = db.prepare(`
      SELECT sr.*, u.display_name, u.email
      FROM social_relationships sr
      LEFT JOIN users u ON sr.target_user_id = u.id
      WHERE sr.user_id = ? AND sr.relationship_type = 'FRIEND'
    `).all(userId) as any[];

    return rows.map((r) => ({
      relationshipId: r.id,
      targetUserId: r.target_user_id,
      displayName: r.display_name || 'Disciplined Peer',
      createdAt: r.created_at
    }));
  }
}

// POST /api/v1/social/friends/request
socialController.post('/friends/request', (req: Request, res: Response) => {
  try {
    const userId = req.body?.userId || 'default-user';
    const targetUserId = req.body?.targetUserId;
    if (!targetUserId) return res.status(400).json({ success: false, error: 'TARGET_USER_REQUIRED' });

    const result = SocialService.addRelationship(userId, targetUserId, 'PENDING');
    res.status(201).json({ success: true, data: result });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/social/block
socialController.post('/block', (req: Request, res: Response) => {
  try {
    const userId = req.body?.userId || 'default-user';
    const targetUserId = req.body?.targetUserId;
    if (!targetUserId) return res.status(400).json({ success: false, error: 'TARGET_USER_REQUIRED' });

    const result = SocialService.blockUser(userId, targetUserId);
    res.json({ success: true, data: result });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/social/report
socialController.post('/report', (req: Request, res: Response) => {
  try {
    const reporterId = req.body?.reporterId || 'default-user';
    const targetId = req.body?.targetId;
    const targetType = req.body?.targetType || 'CHALLENGE';
    const reason = req.body?.reason || 'Inappropriate content';

    if (!targetId) return res.status(400).json({ success: false, error: 'TARGET_ID_REQUIRED' });

    const result = SocialService.reportContent({ reporterId, targetId, targetType, reason });
    res.status(201).json({ success: true, data: result });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// GET /api/v1/social/friends
socialController.get('/friends', (req: Request, res: Response) => {
  const userId = (req.query?.userId as string) || 'default-user';
  const friends = SocialService.getFriends(userId);
  res.json({ success: true, count: friends.length, data: friends });
});
