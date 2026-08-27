// Offline Sync Queue & Reconciliation Controller
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { SchedulingService } from '../scheduling/scheduling.controller';
import { SyncService } from './sync.service';

export const syncController = Router();

// GET /api/v1/sync/alarms - Reconciles client-side notification schedules with authoritative backend state
syncController.get('/alarms', (req: Request, res: Response) => {
  const db = DatabaseService.getDb();
  const defaultUser = db.prepare('SELECT id FROM users LIMIT 1').get() as any;
  const userId = (req.query.userId as string) || defaultUser?.id || 'default-user';

  const syncData = SchedulingService.getSyncAlarms(userId);
  res.json({ success: true, ...syncData });
});

// GET /api/v1/sync/status - Returns sync status, pending server changes, and mesh status
syncController.get('/status', (req: Request, res: Response) => {
  const db = DatabaseService.getDb();
  const defaultUser = db.prepare('SELECT id FROM users LIMIT 1').get() as any;
  const userId = (req.query.userId as string) || defaultUser?.id || 'default-user';

  const activeMission = db.prepare("SELECT id, status, updated_at FROM missions WHERE user_id = ? AND status IN ('ACTIVE', 'IN_PROGRESS', 'VERIFYING', 'RETRY') ORDER BY created_at DESC LIMIT 1").get(userId) as any;
  const devices = db.prepare('SELECT id, device_name, is_online, last_ping_at FROM mesh_devices WHERE user_id = ?').all(userId) as any[];

  res.json({
    success: true,
    serverTime: new Date().toISOString(),
    userId,
    activeMission: activeMission || null,
    connectedDevices: devices.length,
    devices
  });
});

// POST /api/v1/sync/batch - Bulk ingest offline-completed missions, toggled alarms, and preferences
syncController.post('/batch', async (req: Request, res: Response) => {
  const db = DatabaseService.getDb();
  const defaultUser = db.prepare('SELECT id FROM users LIMIT 1').get() as any;
  const userId = (req.body.userId as string) || defaultUser?.id || 'default-user';

  const { events } = req.body;
  if (!Array.isArray(events)) {
    res.status(400).json({ success: false, error: 'events array required' });
    return;
  }

  const batchResult = await SyncService.processBatchSync(userId, events);
  res.json({ success: true, data: batchResult });
});
