// Phase 1 System Health Controller
import { Router, Request, Response } from 'express';
import { DatabaseService } from '../db/connection';

export const systemHealthController = Router();

// GET /api/v1/health
systemHealthController.get('/', (req: Request, res: Response) => {
  let dbStatus = 'offline';
  try {
    const db = DatabaseService.getDb();
    const result = db.prepare('SELECT 1 as is_alive').get() as any;
    if (result && result.is_alive === 1) {
      dbStatus = 'online';
    }
  } catch (e) {
    dbStatus = 'error';
  }

  res.json({
    status: 'ok',
    service: 'discipline-api',
    version: '0.1.0',
    database: dbStatus,
    timestamp: new Date().toISOString()
  });
});
