// Discipline Squads & Collective Accountability Service & Controller
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';

export class SquadsService {
  public static createSquad(params: { userId: string; name: string }) {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();
    // 6-character alphanumeric invite code
    const inviteCode = Math.random().toString(36).substring(2, 8).toUpperCase();

    db.prepare(`
      INSERT INTO squads (id, name, invite_code, collective_streak, created_by, created_at)
      VALUES (?, ?, ?, 1, ?, ?)
    `).run(id, params.name.trim(), inviteCode, params.userId, now);

    // Add Creator as Captain
    db.prepare(`
      INSERT INTO squad_members (id, squad_id, user_id, role, joined_at)
      VALUES (?, ?, ?, 'CAPTAIN', ?)
    `).run(uuidv4(), id, params.userId, now);

    // Log Event
    this.logEvent(id, params.userId, 'SQUAD_CREATED', `Discipline squad "${params.name.trim()}" established.`);

    return this.getSquadOverview(id);
  }

  public static joinSquad(params: { userId: string; inviteCode: string }) {
    const db = DatabaseService.getDb();
    const squad = db.prepare('SELECT * FROM squads WHERE invite_code = ?').get(params.inviteCode.trim().toUpperCase()) as any;
    if (!squad) {
      throw new Error('Invalid squad invite code.');
    }

    const existing = db.prepare('SELECT * FROM squad_members WHERE squad_id = ? AND user_id = ?').get(squad.id, params.userId) as any;
    if (existing) {
      return this.getSquadOverview(squad.id);
    }

    const now = new Date().toISOString();
    db.prepare(`
      INSERT INTO squad_members (id, squad_id, user_id, role, joined_at)
      VALUES (?, ?, ?, 'MEMBER', ?)
    `).run(uuidv4(), squad.id, params.userId, now);

    const user = db.prepare('SELECT display_name FROM users WHERE id = ?').get(params.userId) as any;
    this.logEvent(squad.id, params.userId, 'MEMBER_JOINED', `${user?.display_name || 'A new warrior'} enlisted in the squad.`);

    return this.getSquadOverview(squad.id);
  }

  public static getSquadOverview(squadId: string) {
    const db = DatabaseService.getDb();
    const squad = db.prepare('SELECT * FROM squads WHERE id = ?').get(squadId) as any;
    if (!squad) return null;

    const members = db.prepare(`
      SELECT sm.role, sm.joined_at, u.id as user_id, u.display_name, u.discipline_score, s.current_streak, s.grace_tokens
      FROM squad_members sm
      JOIN users u ON sm.user_id = u.id
      LEFT JOIN streaks s ON u.id = s.user_id
      WHERE sm.squad_id = ?
    `).all(squadId) as any[];

    // Check today's mission status for each member
    const todayStr = new Date().toISOString().substring(0, 10);
    let completedCount = 0;

    const memberStatuses = members.map((m) => {
      const todayMission = db.prepare(`
        SELECT status, resistance_seconds, completed_at FROM missions 
        WHERE user_id = ? AND scheduled_at LIKE ?
        ORDER BY scheduled_at DESC LIMIT 1
      `).get(m.user_id, `${todayStr}%`) as any;

      const isCompleted = todayMission?.status === 'COMPLETED';
      if (isCompleted) completedCount++;

      return {
        userId: m.user_id,
        displayName: m.display_name,
        role: m.role,
        disciplineScore: m.discipline_score,
        currentStreak: m.current_streak ?? 0,
        todayStatus: isCompleted ? 'COMPLETED' : (todayMission ? todayMission.status : 'PENDING'),
        resistanceSeconds: todayMission?.resistance_seconds ?? null
      };
    });

    return {
      id: squad.id,
      name: squad.name,
      inviteCode: squad.invite_code,
      collectiveStreak: squad.collective_streak,
      memberCount: members.length,
      todayCompletionRate: members.length > 0 ? Math.round((completedCount / members.length) * 100) : 0,
      members: memberStatuses,
      createdAt: squad.created_at
    };
  }

  public static getUserSquads(userId: string) {
    const db = DatabaseService.getDb();
    const rows = db.prepare(`
      SELECT s.id 
      FROM squad_members sm
      JOIN squads s ON sm.squad_id = s.id
      WHERE sm.user_id = ?
    `).all(userId) as any[];

    return rows.map((r) => this.getSquadOverview(r.id));
  }

  public static getSquadFeed(squadId: string, limit: number = 20) {
    const db = DatabaseService.getDb();
    const rows = db.prepare(`
      SELECT se.id, se.event_type, se.description, se.created_at, u.display_name, u.id as user_id
      FROM squad_events se
      JOIN users u ON se.user_id = u.id
      WHERE se.squad_id = ?
      ORDER BY se.created_at DESC
      LIMIT ?
    `).all(squadId, limit) as any[];

    return rows.map((r) => ({
      id: r.id,
      userId: r.user_id,
      userName: r.display_name,
      eventType: r.event_type,
      description: r.description,
      createdAt: r.created_at
    }));
  }

  public static nudgeMember(params: { squadId: string; senderUserId: string; targetUserId: string }) {
    const db = DatabaseService.getDb();
    const sender = db.prepare('SELECT display_name FROM users WHERE id = ?').get(params.senderUserId) as any;
    const target = db.prepare('SELECT display_name FROM users WHERE id = ?').get(params.targetUserId) as any;

    const message = `⚡ ${sender?.display_name || 'A squad member'} sent an urgent Wakeup Nudge to ${target?.display_name || 'a member'}! Protect the collective streak!`;
    this.logEvent(params.squadId, params.senderUserId, 'NUDGE_SENT', message);

    return {
      success: true,
      message,
      targetUserId: params.targetUserId,
      dispatchedAt: new Date().toISOString()
    };
  }

  private static logEvent(squadId: string, userId: string, eventType: string, description: string) {
    const db = DatabaseService.getDb();
    db.prepare(`
      INSERT INTO squad_events (id, squad_id, user_id, event_type, description, created_at)
      VALUES (?, ?, ?, ?, ?, ?)
    `).run(uuidv4(), squadId, userId, eventType, description, new Date().toISOString());
  }
}

export const squadsController = Router();

// POST /api/v1/squads - Create squad
squadsController.post('/', (req: Request, res: Response) => {
  try {
    const { userId, name } = req.body;
    if (!name) {
      res.status(400).json({ success: false, error: 'Squad name is required' });
      return;
    }

    const squad = SquadsService.createSquad({
      userId: userId || 'default-user',
      name
    });

    res.status(201).json({ success: true, data: squad });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/squads/join - Join squad via invite code
squadsController.post('/join', (req: Request, res: Response) => {
  try {
    const { userId, inviteCode } = req.body;
    if (!inviteCode) {
      res.status(400).json({ success: false, error: 'inviteCode is required' });
      return;
    }

    const squad = SquadsService.joinSquad({
      userId: userId || 'default-user',
      inviteCode
    });

    res.json({ success: true, data: squad });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// GET /api/v1/squads/user - User's squads
squadsController.get('/user', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const squads = SquadsService.getUserSquads(userId);
  res.json({ success: true, count: squads.length, data: squads });
});

// GET /api/v1/squads/:id - Squad overview
squadsController.get('/:id', (req: Request, res: Response) => {
  const squad = SquadsService.getSquadOverview(String(req.params.id));
  if (!squad) {
    res.status(404).json({ success: false, error: 'Squad not found' });
    return;
  }
  res.json({ success: true, data: squad });
});

// GET /api/v1/squads/:id/feed - Live event feed
squadsController.get('/:id/feed', (req: Request, res: Response) => {
  const feed = SquadsService.getSquadFeed(String(req.params.id));
  res.json({ success: true, count: feed.length, data: feed });
});

// POST /api/v1/squads/:id/nudge - Send wake-up nudge
squadsController.post('/:id/nudge', (req: Request, res: Response) => {
  try {
    const { senderUserId, targetUserId } = req.body;
    if (!targetUserId) {
      res.status(400).json({ success: false, error: 'targetUserId is required' });
      return;
    }

    const result = SquadsService.nudgeMember({
      squadId: String(req.params.id),
      senderUserId: senderUserId || 'default-user',
      targetUserId
    });

    res.json({ success: true, data: result });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});
