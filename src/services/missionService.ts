// Mission Lifecycle & Workflow Orchestrator
import { MissionRepository } from '../db/repositories/missionRepository';
import { AlarmRepository } from '../db/repositories/alarmRepository';
import { TaskRepository } from '../db/repositories/taskRepository';
import { UserRepository } from '../db/repositories/userRepository';
import { MissionStateMachine } from '../domain/stateMachine';
import { MetricsEngine } from '../domain/metricsEngine';
import { VerificationService, SubmitProofDTO } from './verificationService';
import { EscalationEngine } from './escalationEngine';
import { HabitatWsServer } from '../ws/wsServer';
import { Mission, ProofAsset } from '../domain/types';

export class MissionService {
  /**
   * Triggers a mission from a scheduled alarm or immediate manual invocation
   */
  public static async triggerMission(params: {
    userId: string;
    alarmId?: string;
    taskId: string;
    disciplineMode?: 'GENTLE' | 'DISCIPLINE' | 'HARDCORE';
    scheduledFor?: string;
  }): Promise<Mission> {
    const now = new Date().toISOString();
    const task = TaskRepository.getById(params.taskId);
    if (!task) {
      throw new Error(`Task ${params.taskId} not found.`);
    }

    const mode = params.disciplineMode || 'DISCIPLINE';

    // 1. Create or retrieve active mission instance
    const mission = MissionRepository.create({
      userId: params.userId,
      alarmId: params.alarmId ?? null,
      taskId: params.taskId,
      scheduledFor: params.scheduledFor ?? now,
      triggeredAt: now,
      completedAt: null,
      status: 'TRIGGERED',
      attemptsCount: 1,
      resistanceSeconds: null,
      xpAwarded: 0,
      disciplineMode: mode
    });

    // 2. Log initial attempt
    const escalation = MissionStateMachine.calculateEscalation(1, mode);
    MissionRepository.addAttempt(mission.id, 1, escalation.sirenVolume);

    // 3. Arm 5-minute escalation timer
    EscalationEngine.armEscalationTimer(mission, 5);

    // 4. Dispatch WebSocket wake-up event to mobile/web
    try {
      const ws = HabitatWsServer.getInstance();
      ws.sendToUser(params.userId, 'MISSION_TRIGGERED', {
        mission,
        taskTitle: task.title,
        taskCategory: task.category,
        proofType: task.proofType,
        instructions: task.instructions,
        sirenVolume: escalation.sirenVolume,
        urgencyLevel: escalation.urgencyLevel,
        attemptIndex: 1
      });
    } catch (e) {
      // WS fallback
    }

    return mission;
  }

  /**
   * User acknowledges alarm and enters camera capture mode
   */
  public static startMission(missionId: string): Mission {
    const mission = MissionRepository.getById(missionId);
    if (!mission) {
      throw new Error(`Mission ${missionId} not found.`);
    }

    const nextStatus = MissionStateMachine.transition(
      {
        missionId,
        currentStatus: mission.status,
        disciplineMode: mission.disciplineMode,
        attemptsCount: mission.attemptsCount
      },
      'IN_PROGRESS'
    );

    const updated = MissionRepository.updateStatus(missionId, { status: nextStatus });
    if (!updated) throw new Error('Failed to update mission status.');

    try {
      const ws = HabitatWsServer.getInstance();
      ws.sendToUser(mission.userId, 'MISSION_IN_PROGRESS', { missionId, status: 'IN_PROGRESS' });
    } catch (e) {}

    return updated;
  }

  /**
   * Submits proof, executes anti-cheat validation, calculates resistance & updates gamification stats
   */
  public static async submitAndVerifyProof(
    missionId: string,
    proofDto: SubmitProofDTO
  ): Promise<{
    mission: Mission;
    proof: ProofAsset;
    isValid: boolean;
    rejectionReason?: string;
    xpResult?: any;
  }> {
    const mission = MissionRepository.getById(missionId);
    if (!mission) {
      throw new Error(`Mission ${missionId} not found.`);
    }

    const task = TaskRepository.getById(mission.taskId);
    if (!task) {
      throw new Error(`Task ${mission.taskId} not found.`);
    }

    // 1. Verify Proof via VerificationService
    const { proof, result } = await VerificationService.verifyProof(mission.taskId, proofDto);

    if (!result.isValid) {
      return {
        mission,
        proof,
        isValid: false,
        rejectionReason: result.rejectionReason
      };
    }

    // 2. Proof is valid -> Calculate Completion Metrics
    const completedAt = new Date().toISOString();
    const startTime = mission.triggeredAt || mission.scheduledFor;
    const resistanceSeconds = MetricsEngine.calculateResistanceSeconds(startTime, completedAt);

    // Compute XP with speed multiplier
    const xpResult = MetricsEngine.calculateXp({
      baseXp: task.baseXp,
      resistanceSeconds,
      attemptsCount: mission.attemptsCount,
      disciplineMode: mission.disciplineMode
    });

    // 3. Update Mission Entity to COMPLETED
    const completedMission = MissionRepository.updateStatus(missionId, {
      status: 'COMPLETED',
      completedAt,
      resistanceSeconds,
      xpAwarded: xpResult.totalXp
    });

    // 4. Cancel Escalation Timer & Resolve Attempts
    EscalationEngine.cancelEscalationTimer(missionId);

    // 5. Update User Discipline Score, XP, and Streak
    const user = UserRepository.getById(mission.userId);
    if (user) {
      const updatedScore = MetricsEngine.calculateUpdatedDisciplineScore(
        user.disciplineScore,
        true,
        xpResult.resistanceMinutes,
        mission.disciplineMode
      );

      const streakResult = MetricsEngine.evaluateStreak(
        user.currentStreak,
        user.graceTokens,
        true
      );

      const newTotalXp = user.totalXp + xpResult.totalXp;
      const newLongest = Math.max(user.longestStreak, streakResult.newStreak);

      UserRepository.updateStats(user.id, {
        disciplineScore: updatedScore,
        currentStreak: streakResult.newStreak,
        longestStreak: newLongest,
        totalXp: newTotalXp,
        graceTokens: streakResult.newGraceTokens
      });

      // 6. Broadcast Completion Event via WebSocket
      try {
        const ws = HabitatWsServer.getInstance();
        ws.sendToUser(user.id, 'MISSION_COMPLETED', {
          missionId,
          resistanceSeconds,
          resistanceMinutes: xpResult.resistanceMinutes,
          xpAwarded: xpResult.totalXp,
          currentStreak: streakResult.newStreak,
          disciplineScore: updatedScore,
          firstAlarmBonus: xpResult.firstAlarmBonus
        });
      } catch (e) {}
    }

    return {
      mission: completedMission!,
      proof,
      isValid: true,
      xpResult
    };
  }
}
