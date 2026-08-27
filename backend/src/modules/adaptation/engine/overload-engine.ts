// Routine Overload Detection & Load Score Engine
import { DatabaseService } from '../../../db/connection';

export type LoadLevel = 'LIGHT' | 'MODERATE' | 'HIGH' | 'VERY_HIGH';

export interface RoutineLoadAnalysis {
  routineId: string;
  routineName: string;
  taskCount: number;
  estimatedMinutes: number;
  averageDifficulty: number;
  loadScore: number; // 0 - 100
  loadLevel: LoadLevel;
  completionRate: number;
  isOverloaded: boolean;
  simplificationSuggested: boolean;
  recommendationMessage: string;
}

export class OverloadEngine {
  /**
   * Analyzes routine load and flags overload risks
   */
  public static analyzeRoutineLoad(routineId: string, userId: string): RoutineLoadAnalysis {
    const db = DatabaseService.getDb();
    const routine = db.prepare('SELECT * FROM routines WHERE id = ?').get(routineId) as any;
    const routineName = routine?.name || routine?.title || 'Daily Routine';

    // Get routine tasks
    const rTasks = db.prepare('SELECT * FROM routine_tasks WHERE routine_id = ?').all(routineId) as any[];

    const taskCount = rTasks.length;
    let totalSec = 0;
    let totalDiff = 0;

    for (const rt of rTasks) {
      const task = db.prepare('SELECT difficulty, estimated_duration_sec FROM tasks WHERE id = ? OR template_id = ? LIMIT 1').get(
        rt.task_template_id,
        rt.task_template_id
      ) as any;
      totalSec += Number(task?.estimated_duration_sec) || 120;
      totalDiff += Number(task?.difficulty) || 2;
    }

    const estimatedMinutes = Math.max(1, Math.round(totalSec / 60));
    const averageDifficulty = taskCount > 0 ? Number((totalDiff / taskCount).toFixed(1)) : 2;

    // Completion rate in last 14 days
    const missionStats = db.prepare(`
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN status = 'COMPLETED' THEN 1 ELSE 0 END) as completed
      FROM missions
      WHERE user_id = ? AND source = 'ROUTINE'
    `).get(userId) as any;

    const totalMissions = Number(missionStats?.total) || 0;
    const completedMissions = Number(missionStats?.completed) || 0;
    const completionRate = totalMissions > 0 ? Math.round((completedMissions / totalMissions) * 100) : 100;

    // Load Score Calculation (0 - 100)
    // taskCount * 5 + estimatedMinutes / 2 + averageDifficulty * 5
    const rawScore = Number(taskCount * 5 + Math.round(estimatedMinutes / 2) + Math.round(averageDifficulty * 5)) || 25;
    const loadScore = Math.min(100, Math.max(0, rawScore));

    let loadLevel: LoadLevel = 'MODERATE';
    if (loadScore <= 30) loadLevel = 'LIGHT';
    else if (loadScore <= 60) loadLevel = 'MODERATE';
    else if (loadScore <= 80) loadLevel = 'HIGH';
    else loadLevel = 'VERY_HIGH';

    const isOverloaded = (loadLevel === 'HIGH' || loadLevel === 'VERY_HIGH') && completionRate < 60;
    const simplificationSuggested = isOverloaded || taskCount >= 8;

    let recommendationMessage = 'Routine load is well balanced.';
    if (isOverloaded) {
      recommendationMessage = `Your routine has become heavy (${taskCount} tasks, ${estimatedMinutes} min) and completion has dropped to ${completionRate}%. Consider converting secondary tasks to optional.`;
    } else if (loadLevel === 'HIGH') {
      recommendationMessage = `Routine effort is high (${estimatedMinutes} min). Maintain high consistency or simplify during demanding weeks.`;
    }

    return {
      routineId,
      routineName,
      taskCount,
      estimatedMinutes,
      averageDifficulty,
      loadScore,
      loadLevel,
      completionRate,
      isOverloaded,
      simplificationSuggested,
      recommendationMessage
    };
  }
}
