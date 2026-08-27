// Metrics, Resistance Trends & Analytics Routes
import { Router, Request, Response } from 'express';
import { UserRepository } from '../../db/repositories/userRepository';
import { MissionRepository } from '../../db/repositories/missionRepository';
import { TaskRepository } from '../../db/repositories/taskRepository';
import { ProofRepository } from '../../db/repositories/proofRepository';
import { MetricsEngine } from '../../domain/metricsEngine';

export const metricsRouter = Router();

// GET /api/metrics/overview - Comprehensive dashboard analytics
metricsRouter.get('/overview', (req: Request, res: Response) => {
  const defaultUser = UserRepository.getFirstUser();
  const userId = (req.query.userId as string) || defaultUser?.id;

  if (!userId) {
    res.status(400).json({ success: false, error: 'User not found' });
    return;
  }

  const user = UserRepository.getById(userId);
  if (!user) {
    res.status(404).json({ success: false, error: 'User not found' });
    return;
  }

  const completedMissions = MissionRepository.getCompletedHistory(userId, 30);
  
  // Calculate average resistance
  let totalResistanceSec = 0;
  completedMissions.forEach((m) => {
    totalResistanceSec += m.resistanceSeconds || 0;
  });

  const avgResistanceMinutes = completedMissions.length > 0 
    ? parseFloat((totalResistanceSec / completedMissions.length / 60).toFixed(2)) 
    : 0;

  const autonomyScore = MetricsEngine.calculateAutonomyScore(avgRecentResistanceMinutes(completedMissions));

  // Build 7-day timeline
  const timeline7d = build7DayTimeline(completedMissions);

  res.json({
    success: true,
    user: {
      id: user.id,
      displayName: user.displayName,
      email: user.email,
      disciplineScore: user.disciplineScore,
      currentStreak: user.currentStreak,
      longestStreak: user.longestStreak,
      totalXp: user.totalXp,
      graceTokens: user.graceTokens,
      autonomyLevel: user.autonomyLevel
    },
    analytics: {
      averageResistanceMinutes: avgResistanceMinutes,
      autonomyScore,
      totalCompletedMissions: completedMissions.length,
      timeline7d
    }
  });
});

// GET /api/metrics/audit-logs - Audit trail of missions with tasks & proofs
metricsRouter.get('/audit-logs', (req: Request, res: Response) => {
  const defaultUser = UserRepository.getFirstUser();
  const userId = (req.query.userId as string) || defaultUser?.id;

  if (!userId) {
    res.status(400).json({ success: false, error: 'User not found' });
    return;
  }

  const completed = MissionRepository.getCompletedHistory(userId, 20);
  const enrichedLogs = completed.map((mission) => {
    const task = TaskRepository.getById(mission.taskId);
    const proofs = ProofRepository.getByMissionId(mission.id);
    return {
      mission,
      task,
      proofs,
      resistanceMinutes: mission.resistanceSeconds ? parseFloat((mission.resistanceSeconds / 60).toFixed(2)) : 0
    };
  });

  res.json({ success: true, count: enrichedLogs.length, logs: enrichedLogs });
});

function avgRecentResistanceMinutes(missions: any[]): number {
  if (missions.length === 0) return 10;
  const recent = missions.slice(0, 14);
  const sumSec = recent.reduce((acc, m) => acc + (m.resistanceSeconds || 0), 0);
  return sumSec / recent.length / 60;
}

function build7DayTimeline(completed: any[]) {
  const days = [];
  const now = new Date();

  for (let i = 6; i >= 0; i--) {
    const d = new Date(now);
    d.setDate(d.getDate() - i);
    const dateStr = d.toISOString().substring(0, 10);
    const dayName = d.toLocaleDateString('en-US', { weekday: 'short' });

    const matchingMissions = completed.filter((m) => m.completedAt?.startsWith(dateStr));
    const count = matchingMissions.length;
    const avgSec = count > 0 
      ? matchingMissions.reduce((a, m) => a + (m.resistanceSeconds || 0), 0) / count 
      : null;

    days.push({
      date: dateStr,
      day: dayName,
      completedMissionsCount: count,
      avgResistanceMinutes: avgSec ? parseFloat((avgSec / 60).toFixed(2)) : null,
      passed: count > 0
    });
  }

  return days;
}
