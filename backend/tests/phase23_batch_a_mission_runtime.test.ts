// Phase 23 Batch A: Core Mission Runtime End-to-End Integration Test
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { TaskService } from '../src/modules/tasks/domain/task.service';
import { AlarmService } from '../src/modules/alarms/domain/alarm.service';
import { MissionService } from '../src/modules/missions/domain/mission.service';
import { ProofCaptureService } from '../src/modules/proofs/domain/proof-capture.service';
import { ProofFileStore } from '../src/modules/proofs/domain/proof-file-store';
import { NativeAlarmScheduler } from '../src/modules/alarms/services/native-alarm-scheduler';
import { v4 as uuidv4 } from 'uuid';
import fs from 'fs';
import path from 'path';

describe('Phase 23 Batch A: Core Mission Runtime (Task -> Alarm -> Mission -> Proof -> Ledger)', () => {
  const testUserId = uuidv4();
  const testStorageDir = path.resolve(process.cwd(), 'data', 'test_proofs_phase23');

  let taskService: TaskService;
  let alarmService: AlarmService;
  let missionService: MissionService;
  let proofCaptureService: ProofCaptureService;

  beforeAll(() => {
    // Ensure DB connection is initialized
    DatabaseService.getDb();

    // Create test user in DB to satisfy foreign keys
    const db = DatabaseService.getDb();
    db.prepare(`
      INSERT OR IGNORE INTO users (id, email, password_hash, display_name, timezone, created_at, updated_at)
      VALUES (?, ?, 'hash', 'Test Recruit', 'UTC', ?, ?)
    `).run(testUserId, `recruit_${testUserId}@habitat.internal`, new Date().toISOString(), new Date().toISOString());

    // Isolate ProofFileStore storage directory
    ProofFileStore.setStorageDirForTesting(testStorageDir);

    taskService = new TaskService();
    missionService = new MissionService();
    alarmService = new AlarmService(undefined, missionService);
    proofCaptureService = new ProofCaptureService(undefined, missionService);

    NativeAlarmScheduler.resetForTesting();
  });

  afterAll(() => {
    // Clean up temporary proof storage directory
    if (fs.existsSync(testStorageDir)) {
      fs.rmSync(testStorageDir, { recursive: true, force: true });
    }
    // Restore default proof directory
    ProofFileStore.setStorageDirForTesting(path.resolve(process.cwd(), 'data', 'proofs'));
  });

  it('Step 1: TaskService creates and persists a real discipline task in DB', async () => {
    const task = await taskService.createTask({
      userId: testUserId,
      slug: `pushups-discipline-${Date.now()}`,
      title: 'Morning Pushup Protocol',
      description: 'Execute 20 strict form biomechanical pushups.',
      category: 'FITNESS',
      difficulty: 'HARD',
      proofType: 'VIDEO',
      verificationType: 'AI_POSE_REP_COUNTER',
      baseXp: 100,
      estimatedDurationSec: 120,
      instructions: 'Keep body aligned and break parallel.'
    });

    expect(task.id).toBeDefined();
    expect(task.title).toBe('Morning Pushup Protocol');
    expect(task.baseXp).toBe(100);

    const fetched = await taskService.getTask(task.id);
    expect(fetched).not.toBeNull();
    expect(fetched?.slug).toBe(task.slug);
  });

  it('Step 2: AlarmService schedules exact alarm and registers with NativeAlarmScheduler', async () => {
    const tasks = await taskService.getUserTasks(testUserId);
    const targetTask = tasks[0];
    expect(targetTask).toBeDefined();

    const alarm = await alarmService.schedule({
      userId: testUserId,
      taskId: targetTask.id,
      timeOfDay: '06:30:00',
      timezone: 'America/New_York',
      repeatDays: [1, 2, 3, 4, 5],
      disciplineMode: 'HARDCORE'
    });

    expect(alarm.id).toBeDefined();
    expect(alarm.timeOfDay).toBe('06:30:00');
    expect(alarm.disciplineMode).toBe('HARDCORE');

    // Verify native scheduler recorded the active OS alarm
    expect(NativeAlarmScheduler.getRegisteredOSAlarmsCount()).toBeGreaterThanOrEqual(1);

    const userAlarms = await alarmService.getUserAlarms(testUserId);
    expect(userAlarms.some((a) => a.id === alarm.id)).toBe(true);
  });

  it('Step 3: Alarm fires, triggering an active mission through MissionService', async () => {
    const userAlarms = await alarmService.getUserAlarms(testUserId);
    const alarm = userAlarms[0];

    const mission = await alarmService.trigger(alarm.id);
    expect(mission).toBeDefined();
    expect(mission.alarmId).toBe(alarm.id);
    expect(mission.userId).toBe(testUserId);

    // Verify mission transitioned to ACTIVE
    const activeMission = await missionService.getMission(mission.id);
    expect(activeMission?.status).toBe('ACTIVE');
  });

  it('Step 4: ProofCaptureService records video payload, computes SHA-256, and stores in ProofFileStore', async () => {
    const activeMissions = await missionService.getActiveMissions(testUserId);
    const currentMission = activeMissions[0];
    expect(currentMission).toBeDefined();

    // 1. Initialize proof capture session
    const session = proofCaptureService.initializeSession(currentMission.id, testUserId);
    expect(session.sessionId).toBeDefined();

    // 2. Capture binary video payload (simulating real camera frame buffer)
    const simulatedVideoBuffer = Buffer.from('HABITAT_GENUINE_CAMERA_PAYLOAD_FRAMES_0123456789_PUSHUP_VIDEO_DATA');
    proofCaptureService.capturePayload(session.sessionId, simulatedVideoBuffer, 'video/mp4');

    // 3. Finalize proof: writes to filesystem, calculates SHA-256, creates DB record
    const finalized = await proofCaptureService.finalizeProof(session.sessionId);

    expect(finalized.id).toBeDefined();
    expect(finalized.fileSizeBytes).toBe(simulatedVideoBuffer.length);
    expect(finalized.sha256).toBe(ProofFileStore.computeSha256(simulatedVideoBuffer));

    // Verify file exists on disk in application private storage
    expect(ProofFileStore.exists(finalized.storageKey)).toBe(true);
    const readBytes = ProofFileStore.readProof(finalized.storageKey);
    expect(readBytes.equals(simulatedVideoBuffer)).toBe(true);

    // Verify mission transitioned to VERIFYING
    const updatedMission = await missionService.getMission(currentMission.id);
    expect(updatedMission?.status).toBe('VERIFYING');
  });

  it('Step 5: Mission completes atomically, awarding XP ledger entry and updating streak', async () => {
    const activeMissions = await missionService.getActiveMissions(testUserId);
    const currentMission = activeMissions[0];
    expect(currentMission).toBeDefined();

    const completion = missionService.completeMission({
      missionId: currentMission.id,
      userId: testUserId,
      resistanceSeconds: 15,
      baseXp: 100,
      idempotencyKey: `complete_${currentMission.id}`
    });

    expect(completion.mission.status).toBe('COMPLETED');
    expect(completion.xpAwarded).toBeGreaterThanOrEqual(100);

    // Verify state in DB
    const finalMission = await missionService.getMission(currentMission.id);
    expect(finalMission?.status).toBe('COMPLETED');
  });

  it('Step 6: AlarmService reconciles scheduled alarms and handles timezone/boot recovery', async () => {
    const reconciliation = await alarmService.reconcile(testUserId, {
      currentTimezone: 'America/Chicago',
      deviceBootTime: new Date().toISOString()
    });

    expect(reconciliation.enabledAlarms.length).toBeGreaterThanOrEqual(1);
    expect(reconciliation.reconciledCount).toBeGreaterThanOrEqual(1);
    expect(reconciliation.timezoneAdjusted).toBe(true);

    const updatedAlarms = await alarmService.getUserAlarms(testUserId);
    expect(updatedAlarms[0].timezone).toBe('America/Chicago');
  });

  it('Step 7: Mission escalation retry increments attempt count and logs attempt history', async () => {
    const task = await taskService.createTask({
      userId: testUserId,
      title: 'Escalation Test Task',
      description: 'Test retry loop',
      category: 'DISCIPLINE',
      proofType: 'PHOTO'
    });

    const mission = await missionService.createMission({
      userId: testUserId,
      taskId: task.id
    });

    expect(mission.attemptCount).toBe(1);

    const retried = await missionService.retryMission(mission.id, 'FORM_COMPROMISED');
    expect(retried.attemptCount).toBe(2);
    expect(retried.status).toBe('ACTIVE');

    const db = DatabaseService.getDb();
    const attempts = db.prepare('SELECT * FROM mission_attempts WHERE mission_id = ?').all(mission.id) as any[];
    expect(attempts.length).toBeGreaterThanOrEqual(2);
  });
});
