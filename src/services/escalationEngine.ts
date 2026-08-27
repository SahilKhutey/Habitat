// Escalation Engine for 5-Minute Retries & Urgency Ramping
import { MissionRepository } from '../db/repositories/missionRepository';
import { MissionStateMachine } from '../domain/stateMachine';
import { HabitatWsServer } from '../ws/wsServer';
import { Mission } from '../domain/types';

export class EscalationEngine {
  private static retryTimers: Map<string, NodeJS.Timeout> = new Map();

  /**
   * Schedules or resets the 5-minute escalation timer for an active mission
   */
  public static armEscalationTimer(mission: Mission, intervalMinutes: number = 5): void {
    // Clear existing timer if any
    this.cancelEscalationTimer(mission.id);

    const ms = intervalMinutes * 60 * 1000;

    const timer = setTimeout(async () => {
      await this.triggerEscalation(mission.id);
    }, ms);

    this.retryTimers.set(mission.id, timer);
  }

  /**
   * Cancels the escalation timer when a mission is successfully completed or dismissed
   */
  public static cancelEscalationTimer(missionId: string): void {
    const existing = this.retryTimers.get(missionId);
    if (existing) {
      clearTimeout(existing);
      this.retryTimers.delete(missionId);
    }
  }

  /**
   * Executes the escalation step: volume bump, attempt increment, and WS broadcast
   */
  public static async triggerEscalation(missionId: string): Promise<void> {
    const mission = MissionRepository.getById(missionId);
    if (!mission || mission.status === 'COMPLETED' || mission.status === 'FAILED') {
      this.cancelEscalationTimer(missionId);
      return;
    }

    const nextAttemptIndex = mission.attemptsCount + 1;
    const escalation = MissionStateMachine.calculateEscalation(nextAttemptIndex, mission.disciplineMode);

    // Update mission attempts
    MissionRepository.updateStatus(missionId, {
      attemptsCount: nextAttemptIndex,
      status: 'TRIGGERED' // Re-enter triggered siren state
    });

    // Record individual attempt log
    MissionRepository.addAttempt(missionId, nextAttemptIndex, escalation.sirenVolume);

    console.log(
      `[ESCALATION] Mission ${missionId} escalated to Attempt ${nextAttemptIndex} (Siren: ${escalation.sirenVolume}%, Urgency: ${escalation.urgencyLevel})`
    );

    // Dispatch WebSocket siren escalation event to client
    try {
      const ws = HabitatWsServer.getInstance();
      ws.sendToUser(mission.userId, 'MISSION_ESCALATED', {
        missionId,
        attemptIndex: nextAttemptIndex,
        sirenVolume: escalation.sirenVolume,
        urgencyLevel: escalation.urgencyLevel,
        flashHaptics: escalation.flashHaptics,
        notifyAccountabilityPartner: escalation.notifyAccountabilityPartner,
        message: `Mission incomplete after 5 minutes. Escalating urgency to Level ${nextAttemptIndex}.`
      });
    } catch (e) {
      // WS might not be connected if running offline/test
    }

    // Re-arm timer for next 5-min window
    this.armEscalationTimer({ ...mission, attemptsCount: nextAttemptIndex }, 5);
  }
}
