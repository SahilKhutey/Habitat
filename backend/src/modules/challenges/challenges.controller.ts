// Discipline Challenges, Tournaments & Guild Arena Controller & Service
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';

export class ChallengesService {
  public static getAllChallenges() {
    const db = DatabaseService.getDb();
    const rows = db.prepare('SELECT * FROM challenges WHERE is_active = 1 ORDER BY created_at DESC').all() as any[];

    return rows.map((c) => {
      const participantCount = db.prepare('SELECT COUNT(*) as count FROM challenge_participants WHERE challenge_id = ?').get(c.id) as any;
      return {
        id: c.id,
        title: c.title,
        description: c.description,
        durationDays: c.duration_days,
        rewardXp: c.reward_xp,
        trophyName: c.trophy_name,
        taskIds: JSON.parse(c.task_ids || '[]'),
        startDate: c.start_date,
        endDate: c.end_date,
        participantsCount: participantCount?.count ?? 0,
        createdAt: c.created_at
      };
    });
  }

  public static getChallengeById(challengeId: string, userId?: string) {
    const db = DatabaseService.getDb();
    const challenge = db.prepare('SELECT * FROM challenges WHERE id = ?').get(challengeId) as any;
    if (!challenge) return null;

    let userParticipation = null;
    if (userId) {
      userParticipation = db.prepare('SELECT * FROM challenge_participants WHERE challenge_id = ? AND user_id = ?').get(challengeId, userId) as any;
    }

    return {
      id: challenge.id,
      title: challenge.title,
      description: challenge.description,
      durationDays: challenge.duration_days,
      rewardXp: challenge.reward_xp,
      trophyName: challenge.trophy_name,
      taskIds: JSON.parse(challenge.task_ids || '[]'),
      startDate: challenge.start_date,
      endDate: challenge.end_date,
      userParticipation: userParticipation ? {
        daysCompleted: userParticipation.days_completed,
        averageResistanceSec: userParticipation.average_resistance_sec,
        isCompleted: Boolean(userParticipation.is_completed),
        joinedAt: userParticipation.joined_at
      } : null
    };
  }

  public static createChallenge(params: {
    title: string;
    description: string;
    durationDays: number;
    rewardXp: number;
    trophyName: string;
    taskIds: string[];
  }) {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO challenges (id, title, description, duration_days, reward_xp, trophy_name, task_ids, start_date, end_date, is_active, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, '2026-12-31', 1, ?)
    `).run(
      id,
      params.title.trim(),
      params.description.trim(),
      params.durationDays,
      params.rewardXp,
      params.trophyName.trim(),
      JSON.stringify(params.taskIds),
      now.substring(0, 10),
      now
    );

    return this.getChallengeById(id);
  }

  public static joinChallenge(challengeId: string, userId: string) {
    const db = DatabaseService.getDb();
    const existing = db.prepare('SELECT * FROM challenge_participants WHERE challenge_id = ? AND user_id = ?').get(challengeId, userId) as any;
    if (existing) {
      return existing;
    }

    const id = uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO challenge_participants (id, challenge_id, user_id, days_completed, average_resistance_sec, is_completed, joined_at)
      VALUES (?, ?, ?, 0, 120, 0, ?)
    `).run(id, challengeId, userId, now);

    return db.prepare('SELECT * FROM challenge_participants WHERE id = ?').get(id) as any;
  }

  public static recordChallengeDay(params: { challengeId: string; userId: string; resistanceSeconds: number }) {
    const db = DatabaseService.getDb();
    const participant = db.prepare('SELECT * FROM challenge_participants WHERE challenge_id = ? AND user_id = ?').get(params.challengeId, params.userId) as any;
    if (!participant) {
      throw new Error('User not enrolled in challenge.');
    }

    const challenge = db.prepare('SELECT * FROM challenges WHERE id = ?').get(params.challengeId) as any;
    const newDays = participant.days_completed + 1;
    const newAvgResistance = Math.round((participant.average_resistance_sec + params.resistanceSeconds) / 2);
    const isCompleted = newDays >= challenge.duration_days ? 1 : 0;

    db.prepare(`
      UPDATE challenge_participants
      SET days_completed = ?, average_resistance_sec = ?, is_completed = ?
      WHERE id = ?
    `).run(newDays, newAvgResistance, isCompleted, participant.id);

    // If completed -> Award Challenge XP and log to ledger
    if (isCompleted && !participant.is_completed) {
      db.prepare(`
        INSERT INTO xp_transactions (id, user_id, amount, reason, created_at)
        VALUES (?, ?, ?, 'CHALLENGE_COMPLETED_TROPHY', ?)
      `).run(uuidv4(), params.userId, challenge.reward_xp, new Date().toISOString());
    }

    return {
      daysCompleted: newDays,
      totalDays: challenge.duration_days,
      isCompleted: Boolean(isCompleted),
      rewardXp: isCompleted ? challenge.reward_xp : 0
    };
  }

  public static getLeaderboard(challengeId: string) {
    const db = DatabaseService.getDb();
    const rows = db.prepare(`
      SELECT cp.days_completed, cp.average_resistance_sec, cp.is_completed, cp.joined_at, u.id as user_id, u.display_name, u.discipline_score
      FROM challenge_participants cp
      JOIN users u ON cp.user_id = u.id
      WHERE cp.challenge_id = ?
      ORDER BY cp.days_completed DESC, cp.average_resistance_sec ASC
      LIMIT 50
    `).all(challengeId) as any[];

    return rows.map((r, index) => ({
      rank: index + 1,
      userId: r.user_id,
      displayName: r.display_name,
      disciplineScore: r.discipline_score,
      daysCompleted: r.days_completed,
      averageResistanceMinutes: parseFloat((r.average_resistance_sec / 60).toFixed(1)),
      isCompleted: Boolean(r.is_completed)
    }));
  }
}

export const challengesController = Router();

// GET /api/v1/challenges - Browse active challenges
challengesController.get('/', (req: Request, res: Response) => {
  const challenges = ChallengesService.getAllChallenges();
  res.json({ success: true, count: challenges.length, data: challenges });
});

// POST /api/v1/challenges - Create new challenge
challengesController.post('/', (req: Request, res: Response) => {
  try {
    const { title, description, durationDays, rewardXp, trophyName, taskIds } = req.body;
    if (!title || !durationDays || !taskIds) {
      res.status(400).json({ success: false, error: 'title, durationDays, and taskIds are required' });
      return;
    }

    const created = ChallengesService.createChallenge({
      title,
      description: description || '',
      durationDays: parseInt(durationDays, 10),
      rewardXp: parseInt(rewardXp || '500', 10),
      trophyName: trophyName || 'Discipline Trophy',
      taskIds
    });

    res.status(201).json({ success: true, data: created });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// GET /api/v1/challenges/:id - Get challenge details
challengesController.get('/:id', (req: Request, res: Response) => {
  const userId = req.query.userId as string | undefined;
  const challenge = ChallengesService.getChallengeById(String(req.params.id), userId);
  if (!challenge) {
    res.status(404).json({ success: false, error: 'Challenge not found' });
    return;
  }
  res.json({ success: true, data: challenge });
});

// POST /api/v1/challenges/:id/join - Join challenge
challengesController.post('/:id/join', (req: Request, res: Response) => {
  try {
    const userId = (req.body.userId as string) || 'default-user';
    const participant = ChallengesService.joinChallenge(String(req.params.id), userId);
    res.json({ success: true, data: participant });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/challenges/:id/record-day - Record challenge daily sprint progress
challengesController.post('/:id/record-day', (req: Request, res: Response) => {
  try {
    const userId = (req.body.userId as string) || 'default-user';
    const resistanceSeconds = parseInt(req.body.resistanceSeconds || '90', 10);
    const result = ChallengesService.recordChallengeDay({
      challengeId: String(req.params.id),
      userId,
      resistanceSeconds
    });
    res.json({ success: true, data: result });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// GET /api/v1/challenges/:id/leaderboard - Leaderboard
challengesController.get('/:id/leaderboard', (req: Request, res: Response) => {
  const leaderboard = ChallengesService.getLeaderboard(String(req.params.id));
  res.json({ success: true, count: leaderboard.length, data: leaderboard });
});
