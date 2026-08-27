// Habitat Backend Entry Point (HTTP + WebSocket + Seeds)
import express from 'express';
import cors from 'cors';
import http from 'http';
import path from 'path';
import fs from 'fs';
import dotenv from 'dotenv';

import { DatabaseService } from './db/connection';
import { seedDatabase } from './db/seeds';
import { NotificationGateway } from './modules/notifications/notification.gateway';
import { appRouter } from './app.module';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Static uploads serving
const UPLOADS_DIR = path.resolve(process.cwd(), 'uploads');
if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}
app.use('/uploads', express.static(UPLOADS_DIR));

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    engine: 'Habitat Modular Backend Engine (v0.1)',
    timestamp: new Date().toISOString()
  });
});

// Mount /api/v1/
app.use('/api/v1', appRouter);

const server = http.createServer(app);

// Initialize WebSocket Gateway
NotificationGateway.initialize(server);

export function bootstrap() {
  DatabaseService.getDb();
  const { defaultUserId } = seedDatabase();
  console.log(`[DB] Database initialized & seeded. Default User ID: ${defaultUserId}`);

  server.listen(PORT, () => {
    console.log(`=======================================================`);
    console.log(`🚀 HABITAT BACKEND ENGINE (v0.1) ACTIVE`);
    console.log(`📡 REST API: http://localhost:${PORT}/api/v1`);
    console.log(`⚡ WebSocket: ws://localhost:${PORT}/ws`);
    console.log(`=======================================================`);
  });
}

if (process.env.NODE_ENV !== 'test') {
  bootstrap();
}

export { app, server };
