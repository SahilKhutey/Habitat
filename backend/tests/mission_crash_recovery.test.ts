// Unit & Integration Tests: Durable Mission State Machine & Process Crash Recovery
import { describe, it, expect, beforeEach } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { MissionRepository } from '../src/repositories/mission.repository';

describe('Mission State Machine & Process Crash Recovery', () => {
  const userId = 'user-crash-1';
  const taskId = 'task-crash-1';

  beforeEach(() => {
    DatabaseService.resetDbForTesting();
    const db = DatabaseService.getDb();

    db.prepare(`
      INSERT INTO users (id, email, password_hash, display_name, created_at, updated_at)
      VALUES (?, 'crash@habitat.com', 'h', 'Crash Tester', datetime('now'), datetime('now'))
    `).run(userId);

    db.prepare(`
      INSERT INTO tasks (id, slug, title, description, instructions, category, proof_type, validation_rules, created_at)
      VALUES (?, 'crash-task', 'Bed Making', 'Make Bed', 'Flat', 'MORNING', 'PHOTO', '{}', datetime('now'))
    `).run(taskId);
  });

  it('progresses through durable lifecycle states', () => {
    const mission = MissionRepository.create({
      userId,
      taskId,
      disciplineMode: 'DISCIPLINE'
    });

    expect(mission.status).toBe('TRIGGERED');

    // 1. Transition to ACTIVE
    const active = MissionRepository.transitionStatus(mission.id, 'ACTIVE');
    expect(active.status).toBe('ACTIVE');

    // 2. Transition to PROOF_PENDING
    const proofPending = MissionRepository.transitionStatus(mission.id, 'PROOF_PENDING');
    expect(proofPending.status).toBe('PROOF_PENDING');

    // 3. Transition to VERIFYING
    const verifying = MissionRepository.transitionStatus(mission.id, 'VERIFYING');
    expect(verifying.status).toBe('VERIFYING');

    // 4. Transition to COMPLETED
    const completed = MissionRepository.transitionStatus(mission.id, 'COMPLETED');
    expect(completed.status).toBe('COMPLETED');
  });

  it('reconstructs active mission states following simulated process crash', () => {
    // Mission 1: In ACTIVE state
    const m1 = MissionRepository.create({ userId, taskId });
    MissionRepository.transitionStatus(m1.id, 'ACTIVE');

    // Mission 2: In PROOF_PENDING state
    const m2 = MissionRepository.create({ userId, taskId });
    MissionRepository.transitionStatus(m2.id, 'PROOF_PENDING');

    // Mission 3: Already COMPLETED
    const m3 = MissionRepository.create({ userId, taskId });
    MissionRepository.transitionStatus(m3.id, 'COMPLETED');

    // --- SIMULATED PROCESS RESTART ---
    // Application boots up and queries pending missions to restore active UI / foreground state
    const pendingMissions = MissionRepository.findPendingMissions(userId);

    expect(pendingMissions.length).toBe(2);
    const pendingIds = pendingMissions.map((m) => m.id);
    expect(pendingIds).toContain(m1.id);
    expect(pendingIds).toContain(m2.id);
    expect(pendingIds).not.toContain(m3.id); // Completed mission is not pending
  });
});
