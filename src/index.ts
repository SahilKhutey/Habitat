// Habitat Server Bootstrap: Express HTTP + WebSocket Daemon + Alarm Scheduler
import express from 'express';
import cors from 'cors';
import http from 'http';
import path from 'path';
import fs from 'fs';
import dotenv from 'dotenv';

import { DatabaseService } from './db/connection';
import { seedDatabase } from './db/seeds';
import { HabitatWsServer } from './ws/wsServer';
import { AlarmScheduler } from './services/alarmScheduler';

import { taskRouter } from './api/routes/taskRoutes';
import { alarmRouter } from './api/routes/alarmRoutes';
import { missionRouter } from './api/routes/missionRoutes';
import { proofRouter } from './api/routes/proofRoutes';
import { metricsRouter } from './api/routes/metricsRoutes';
import { errorHandler } from './api/middleware/errorHandler';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 4000;

// Enable CORS and JSON body parser
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static uploads
const UPLOADS_DIR = path.resolve(process.cwd(), 'uploads');
if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}
app.use('/uploads', express.static(UPLOADS_DIR));

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'Habitat Discipline & Mission Engine',
    timestamp: new Date().toISOString()
  });
});

// Mount API Routers
app.use('/api/tasks', taskRouter);
app.use('/api/alarms', alarmRouter);
app.use('/api/missions', missionRouter);
app.use('/api/missions', proofRouter); // POST /api/missions/:id/proof
app.use('/api/metrics', metricsRouter);

// Global Error Handler
app.use(errorHandler);

// Create HTTP Server
const server = http.createServer(app);

// Initialize WebSocket Daemon
HabitatWsServer.initialize(server);

// Start Server, Seed Database & Arm Scheduler
function bootstrap() {
  // 1. Initialize SQLite Database & Starter Seeds
  DatabaseService.getDb();
  const { defaultUserId } = seedDatabase();
  console.log(`[DB] Database initialized & seeded. Default User ID: ${defaultUserId}`);

  // 2. Start Alarm Scheduler Daemon (check every 15 seconds)
  AlarmScheduler.start(15000);

  // 3. Listen on Port
  server.listen(PORT, () => {
    console.log(`=======================================================`);
    console.log(`🚀 HABITAT ENGINE: SYSTEM & API LAYER ACTIVE`);
    console.log(`📡 HTTP Server: http://localhost:${PORT}`);
    console.log(`⚡ WebSocket Server: ws://localhost:${PORT}/ws`);
    console.log(`📋 API Docs/Endpoints:`);
    console.log(`   • GET  /api/tasks          - 10 Starter & Custom Missions`);
    console.log(`   • GET  /api/alarms         - Scheduled Mission Commitments`);
    console.log(`   • GET  /api/missions/active - Live Lock-Screen Mission`);
    console.log(`   • POST /api/missions/:id/proof - Real-Time Proof Ingestion`);
    console.log(`   • GET  /api/metrics/overview - Resistance & Discipline Score`);
    console.log(`=======================================================`);
  });
}

// Only start when executed directly (allows importing app/server in tests)
if (process.env.NODE_ENV !== 'test') {
  bootstrap();
}

export { app, server };
