// Multi-Device Wakeup Mesh & Synchronized Telemetry Controller
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../../db/connection';
import { v4 as uuidv4 } from 'uuid';

export class MeshService {
  public static registerDevice(params: {
    userId: string;
    deviceName: string;
    deviceType: string; // 'PHONE' | 'TABLET' | 'WATCH' | 'DESKTOP_WEB'
    pushToken?: string;
  }) {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO mesh_devices (id, user_id, device_name, device_type, push_token, last_ping_at, is_online, created_at)
      VALUES (?, ?, ?, ?, ?, ?, 1, ?)
    `).run(id, params.userId, params.deviceName.trim(), params.deviceType, params.pushToken || null, now, now);

    return db.prepare('SELECT * FROM mesh_devices WHERE id = ?').get(id) as any;
  }

  public static getMeshDevices(userId: string) {
    const db = DatabaseService.getDb();
    const rows = db.prepare('SELECT * FROM mesh_devices WHERE user_id = ? ORDER BY created_at ASC').all(userId) as any[];

    return rows.map((r) => ({
      id: r.id,
      userId: r.user_id,
      deviceName: r.device_name,
      deviceType: r.device_type,
      pushToken: r.push_token,
      lastPingAt: r.last_ping_at,
      isOnline: Boolean(r.is_online),
      createdAt: r.created_at
    }));
  }

  public static heartbeat(deviceId: string) {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();
    db.prepare('UPDATE mesh_devices SET last_ping_at = ?, is_online = 1 WHERE id = ?').run(now, deviceId);
    return { success: true, lastPingAt: now };
  }

  public static broadcastSirenTrigger(params: { userId: string; missionId: string; volumeDecibels: number }) {
    const db = DatabaseService.getDb();
    const devices = this.getMeshDevices(params.userId);
    const id = uuidv4();
    const now = new Date().toISOString();

    const payload = JSON.stringify({
      missionId: params.missionId,
      volumeDecibels: params.volumeDecibels,
      targetDeviceCount: devices.length,
      syncedAt: now
    });

    db.prepare(`
      INSERT INTO mesh_events (id, user_id, event_type, payload, dispatched_at)
      VALUES (?, ?, 'TRIGGER_SIREN', ?, ?)
    `).run(id, params.userId, payload, now);

    return {
      eventId: id,
      eventType: 'TRIGGER_SIREN',
      meshSyncedDevices: devices.map((d) => d.deviceName),
      volumeDecibels: params.volumeDecibels,
      dispatchedAt: now
    };
  }

  public static broadcastDisarm(params: { userId: string; missionId: string; verifiedByDevice: string }) {
    const db = DatabaseService.getDb();
    const devices = this.getMeshDevices(params.userId);
    const id = uuidv4();
    const now = new Date().toISOString();

    const payload = JSON.stringify({
      missionId: params.missionId,
      verifiedByDevice: params.verifiedByDevice,
      silencedDevicesCount: devices.length,
      disarmedAt: now
    });

    db.prepare(`
      INSERT INTO mesh_events (id, user_id, event_type, payload, dispatched_at)
      VALUES (?, ?, 'DISARM_MESH', ?, ?)
    `).run(id, params.userId, payload, now);

    return {
      eventId: id,
      eventType: 'DISARM_MESH',
      verifiedByDevice: params.verifiedByDevice,
      silencedDevices: devices.map((d) => d.deviceName),
      disarmedAt: now
    };
  }

  public static dispatchMeshEvent(userId: string, eventType: string, payload: any) {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO mesh_events (id, user_id, event_type, payload, dispatched_at)
      VALUES (?, ?, ?, ?, ?)
    `).run(id, userId, eventType, JSON.stringify(payload || {}), now);

    return { id, eventType, dispatchedAt: now };
  }

  public static getEvents(userId: string, limit: number = 20) {
    const db = DatabaseService.getDb();
    const rows = db.prepare('SELECT * FROM mesh_events WHERE user_id = ? ORDER BY dispatched_at DESC LIMIT ?').all(userId, limit) as any[];

    return rows.map((r) => ({
      id: r.id,
      userId: r.user_id,
      eventType: r.event_type,
      payload: JSON.parse(r.payload || '{}'),
      dispatchedAt: r.dispatched_at
    }));
  }
}

export const meshController = Router();

// GET /api/v1/mesh/devices
meshController.get('/devices', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const devices = MeshService.getMeshDevices(userId);
  res.json({ success: true, count: devices.length, data: devices });
});

// POST /api/v1/mesh/devices/register
meshController.post('/devices/register', (req: Request, res: Response) => {
  try {
    const { userId, deviceName, deviceType, pushToken } = req.body;
    if (!deviceName || !deviceType) {
      res.status(400).json({ success: false, error: 'deviceName and deviceType are required' });
      return;
    }

    const device = MeshService.registerDevice({
      userId: userId || 'default-user',
      deviceName,
      deviceType,
      pushToken
    });

    res.status(201).json({ success: true, data: device });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/mesh/devices/heartbeat
meshController.post('/devices/heartbeat', (req: Request, res: Response) => {
  try {
    const { deviceId } = req.body;
    const result = MeshService.heartbeat(deviceId);
    res.json({ success: true, data: result });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/mesh/broadcast/trigger
meshController.post('/broadcast/trigger', (req: Request, res: Response) => {
  try {
    const { userId, missionId, volumeDecibels } = req.body;
    const result = MeshService.broadcastSirenTrigger({
      userId: userId || 'default-user',
      missionId: missionId || 'mesh-mission-xyz',
      volumeDecibels: volumeDecibels || 85
    });

    res.json({ success: true, data: result });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// POST /api/v1/mesh/broadcast/disarm
meshController.post('/broadcast/disarm', (req: Request, res: Response) => {
  try {
    const { userId, missionId, verifiedByDevice } = req.body;
    const result = MeshService.broadcastDisarm({
      userId: userId || 'default-user',
      missionId: missionId || 'mesh-mission-xyz',
      verifiedByDevice: verifiedByDevice || 'iPhone 16 Pro'
    });

    res.json({ success: true, data: result });
  } catch (e: any) {
    res.status(400).json({ success: false, error: e.message });
  }
});

// GET /api/v1/mesh/events
meshController.get('/events', (req: Request, res: Response) => {
  const userId = (req.query.userId as string) || 'default-user';
  const events = MeshService.getEvents(userId);
  res.json({ success: true, count: events.length, data: events });
});
