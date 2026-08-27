// Accountability Partner Service & Controller
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';

export class AccountabilityService {
  public static getPartners(userId: string) {
    const db = DatabaseService.getDb();
    const rows = db.prepare('SELECT * FROM accountability_partners WHERE user_id = ? AND is_active = 1').all(userId) as any[];
    return rows.map((r) => ({
      id: r.id,
      userId: r.user_id,
      name: r.name,
      phone: r.phone,
      email: r.email,
      escalationThreshold: r.escalation_threshold,
      createdAt: r.created_at
    }));
  }

  public static addPartner(params: {
    userId: string;
    name: string;
    phone?: string;
    email?: string;
    escalationThreshold?: number;
  }) {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO accountability_partners (id, user_id, name, phone, email, escalation_threshold, is_active, created_at)
      VALUES (?, ?, ?, ?, ?, ?, 1, ?)
    `).run(
      id,
      params.userId,
      params.name.trim(),
      params.phone || null,
      params.email || null,
      params.escalationThreshold || 3,
      now
    );

    return db.prepare('SELECT * FROM accountability_partners WHERE id = ?').get(id) as any;
  }

  public static deletePartner(id: string, userId: string) {
    const db = DatabaseService.getDb();
    db.prepare('DELETE FROM accountability_partners WHERE id = ? AND user_id = ?').run(id, userId);
    return true;
  }

  public static dispatchEscalationAlert(params: {
    userId: string;
    missionId: string;
    taskTitle: string;
    attemptCount: number;
  }) {
    const db = DatabaseService.getDb();
    const partners = this.getPartners(params.userId);
    const user = db.prepare('SELECT display_name FROM users WHERE id = ?').get(params.userId) as any;
    const userName = user?.display_name || 'Discipline User';
    const now = new Date().toISOString();

    const dispatchedLogs = [];

    for (const partner of partners) {
      if (params.attemptCount >= partner.escalationThreshold) {
        const message = `🚨 HABITAT ALERT: ${userName} has failed attempt #${params.attemptCount} for mission "${params.taskTitle}". Siren is escalating. Contact them immediately to enforce wakeup discipline.`;
        const logId = uuidv4();

        db.prepare(`
          INSERT INTO accountability_logs (id, user_id, mission_id, partner_id, message, dispatched_at)
          VALUES (?, ?, ?, ?, ?, ?)
        `).run(logId, params.userId, params.missionId, partner.id, message, now);

        dispatchedLogs.push({
          partnerName: partner.name,
          phone: partner.phone,
          email: partner.email,
          message,
          dispatchedAt: now,
          status: 'DISPATCHED_MOCK_SMS'
        });
      }
    }

    return dispatchedLogs;
  }
}

export const accountabilityController = Router();

// GET /api/v1/accountability
accountabilityController.get('/', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const partners = AccountabilityService.getPartners(userId);
  res.json({ success: true, count: partners.length, data: partners });
});

// POST /api/v1/accountability
accountabilityController.post('/', (req: Request, res: Response) => {
  try {
    const { userId, name, phone, email, escalationThreshold } = req.body;
    if (!name) {
      res.status(400).json({ success: false, error: 'Partner name is required' });
      return;
    }

    const partner = AccountabilityService.addPartner({
      userId: userId || 'default-user',
      name,
      phone,
      email,
      escalationThreshold
    });

    res.status(201).json({ success: true, data: partner });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// DELETE /api/v1/accountability/:id
accountabilityController.delete('/:id', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const success = AccountabilityService.deletePartner(String(req.params.id), userId);
  res.json({ success });
});

// POST /api/v1/accountability/alert
accountabilityController.post('/alert', (req: Request, res: Response) => {
  try {
    const { userId, missionId, taskTitle, attemptCount } = req.body;
    const dispatched = AccountabilityService.dispatchEscalationAlert({
      userId: userId || 'default-user',
      missionId: missionId || 'manual-mission',
      taskTitle: taskTitle || 'Wakeup Routine',
      attemptCount: attemptCount || 3
    });

    res.json({ success: true, count: dispatched.length, data: dispatched });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});
