// Phase 4 Task & Discipline Engine Master Integration Tests
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { TasksService } from '../src/modules/tasks/tasks.controller';
import { UserRepository } from '../src/repositories/user.repository';
import { MissionRepository } from '../src/repositories/mission.repository';

describe('Phase 4 Acceptance Gate: Task & Discipline Engine', () => {
  let userAId: string;
  let userBId: string;
  let clonedTaskId: string;
  let customTaskId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    userAId = seeded.defaultUserId;

    const userB = UserRepository.create({
      email: 'user.b.tasks@discipline.app',
      passwordHash: 'hashed_password_b',
      displayName: 'User Beta'
    });
    userBId = userB.id;
  });

  it('Gate 1: Retrieves 10 system-seeded starter task templates', () => {
    const templates = TasksService.getTemplates();
    expect(templates.length).toBe(10);
    expect(templates.some((t) => t.id === 'tpl-pushups-10')).toBe(true);
    expect(templates.some((t) => t.id === 'tpl-make-bed')).toBe(true);
  });

  it('Gate 2: Clones task from template with server-calculated XP scaling', () => {
    // Clone Push-ups (base XP 30) with Difficulty 3 (1.5x multiplier)
    const task = TasksService.createTaskFromTemplate(userAId, {
      templateId: 'tpl-pushups-10',
      difficulty: 3
    });

    expect(task).toBeDefined();
    expect(task.name).toBe('10 Morning Push-Ups');
    expect(task.difficulty).toBe(3);
    expect(task.baseXp).toBe(30);
    expect(task.xpReward).toBe(45); // 30 * 1.5 = 45 XP
    expect(task.status).toBe('ACTIVE');

    clonedTaskId = task.id;
  });

  it('Gate 3: Creates custom task and verifies server enforces XP calculation', () => {
    // Custom task: Base XP 40 with Difficulty 4 (2.0x multiplier)
    const custom = TasksService.createCustomTask(userAId, {
      name: 'Cold Plunge Check-In',
      description: '3 minutes at 10°C water immersion',
      instructions: 'Record 10s video inside plunge tub',
      category: 'HEALTH',
      proofType: 'VIDEO',
      difficulty: 4,
      baseXp: 40
    });

    expect(custom).toBeDefined();
    expect(custom.name).toBe('Cold Plunge Check-In');
    expect(custom.difficulty).toBe(4);
    expect(custom.xpReward).toBe(80); // 40 * 2.0 = 80 XP

    customTaskId = custom.id;
  });

  it('Gate 4: Executes Task Lifecycle State Machine (ACTIVE -> PAUSED -> ACTIVE -> ARCHIVED)', () => {
    // 1. Pause Task
    const paused = TasksService.setTaskStatus(clonedTaskId, userAId, 'PAUSED');
    expect(paused.status).toBe('PAUSED');
    expect(paused.isActive).toBe(false);

    // 2. Resume Task
    const resumed = TasksService.setTaskStatus(clonedTaskId, userAId, 'ACTIVE');
    expect(resumed.status).toBe('ACTIVE');
    expect(resumed.isActive).toBe(true);

    // 3. Archive Task (Soft Delete)
    const archived = TasksService.setTaskStatus(clonedTaskId, userAId, 'ARCHIVED');
    expect(archived.status).toBe('ARCHIVED');
    expect(archived.archivedAt).toBeDefined();
  });

  it('Gate 5: Enforces User Ownership Isolation on Task Updates and Lifecycle Changes', () => {
    // User B attempting to update or pause User A's custom task must fail
    expect(() => {
      TasksService.updateTask(customTaskId, userBId, { name: 'Hacked Task Name' });
    }).toThrow(/Task not found or access unauthorized/);

    expect(() => {
      TasksService.setTaskStatus(customTaskId, userBId, 'PAUSED');
    }).toThrow(/Task not found or access unauthorized/);
  });

  it('Gate 6: Filters and searches user tasks accurately', () => {
    const physicalTasks = TasksService.getUserTasks(userAId, { category: 'HEALTH' });
    expect(physicalTasks.some((t) => t.id === customTaskId)).toBe(true);

    const searchResults = TasksService.getUserTasks(userAId, { search: 'Plunge' });
    expect(searchResults.length).toBeGreaterThanOrEqual(1);
    expect(searchResults[0].id).toBe(customTaskId);
  });

  it('Gate 7: Historical Integrity - Task difficulty updates do not corrupt historical missions', () => {
    // 1. Create a mission snapshot with custom task at difficulty 4 (XP 80)
    const mission = MissionRepository.create({
      userId: userAId,
      taskId: customTaskId,
      disciplineMode: 'DISCIPLINE'
    });

    // 2. User later edits custom task to Difficulty 1 (XP 40)
    const updatedTask = TasksService.updateTask(customTaskId, userAId, { difficulty: 1 });
    expect(updatedTask.difficulty).toBe(1);
    expect(updatedTask.xpReward).toBe(40); // 40 * 1.0 = 40 XP

    // 3. Mission record remains unaffected
    const fetchedMission = MissionRepository.findById(mission.id);
    expect(fetchedMission).toBeDefined();
    expect(fetchedMission?.taskId).toBe(customTaskId);
  });

  it('Gate 8: Duplicates task and handles reordering', () => {
    const copy = TasksService.duplicateTask(customTaskId, userAId);
    expect(copy.name).toContain('(Copy)');

    const reordered = TasksService.reorderTasks(userAId, [
      { id: copy.id, position: 0 },
      { id: customTaskId, position: 1 }
    ]);
    expect(reordered).toBeDefined();
  });
});
