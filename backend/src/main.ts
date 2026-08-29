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

// Serve Interactive Habitat Web Dashboard at / and /dashboard
app.get(['/', '/dashboard'], (req, res) => {
  res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Habitat — Build the life you want to live.</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Poppins:wght@600;700;800;900&display=swap" rel="stylesheet">
  <style>
    :root {
      --forest: #0F2E1F;
      --bg: #081C13;
      --surface: #10291E;
      --surface-elevated: #163525;
      --border: #1E4230;
      --green: #1E5B38;
      --growth: #4CAF50;
      --sage: #A8D08D;
      --cream: #F7F7F2;
      --text-muted: #6E8577;
      --text-secondary: #B7C6BC;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background-color: var(--bg);
      color: var(--cream);
      font-family: 'Inter', sans-serif;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
    }
    header {
      background: var(--surface);
      border-bottom: 1px solid var(--border);
      padding: 16px 24px;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }
    .logo-container {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .logo-badge {
      background: var(--green);
      border: 1px solid var(--growth);
      color: var(--cream);
      font-family: 'Poppins', sans-serif;
      font-weight: 900;
      font-size: 18px;
      width: 36px;
      height: 36px;
      border-radius: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .brand-title {
      font-family: 'Poppins', sans-serif;
      font-weight: 800;
      font-size: 20px;
      letter-spacing: 1.5px;
      color: #fff;
    }
    .tagline {
      font-size: 12px;
      color: var(--sage);
      margin-left: 8px;
    }
    .status-badge {
      background: rgba(76, 175, 80, 0.15);
      border: 1px solid var(--growth);
      color: var(--growth);
      padding: 6px 14px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .status-dot {
      width: 8px;
      height: 8px;
      background: var(--growth);
      border-radius: 50%;
      box-shadow: 0 0 8px var(--growth);
    }
    main {
      max-width: 1100px;
      width: 100%;
      margin: 0 auto;
      padding: 32px 20px;
      display: grid;
      grid-template-columns: 1fr 340px;
      gap: 24px;
      flex: 1;
    }
    @media (max-width: 850px) {
      main { grid-template-columns: 1fr; }
    }
    .card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 20px;
      padding: 24px;
      margin-bottom: 24px;
    }
    .hud-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
      margin-bottom: 24px;
    }
    .hud-item {
      background: var(--surface-elevated);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 16px;
    }
    .hud-label {
      font-family: 'Poppins', sans-serif;
      font-size: 11px;
      font-weight: 700;
      color: var(--sage);
      letter-spacing: 1px;
      text-transform: uppercase;
      margin-bottom: 6px;
    }
    .hud-value {
      font-family: 'Poppins', sans-serif;
      font-size: 26px;
      font-weight: 800;
      color: #fff;
    }
    h2 {
      font-family: 'Poppins', sans-serif;
      font-size: 18px;
      font-weight: 700;
      margin-bottom: 16px;
      color: #fff;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .task-row {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 14px 16px;
      background: var(--surface-elevated);
      border: 1px solid var(--border);
      border-radius: 14px;
      margin-bottom: 10px;
      transition: all 0.2s ease;
    }
    .task-row:hover {
      border-color: var(--growth);
      transform: translateY(-1px);
    }
    .task-info h4 {
      font-family: 'Poppins', sans-serif;
      font-size: 14px;
      font-weight: 600;
      color: #fff;
    }
    .task-info p {
      font-size: 12px;
      color: var(--text-secondary);
      margin-top: 2px;
    }
    .btn {
      background: var(--growth);
      color: var(--forest);
      font-family: 'Poppins', sans-serif;
      font-weight: 700;
      font-size: 13px;
      padding: 8px 16px;
      border: none;
      border-radius: 10px;
      cursor: pointer;
      transition: all 0.2s ease;
      text-decoration: none;
      display: inline-flex;
      align-items: center;
      gap: 6px;
    }
    .btn:hover {
      background: var(--sage);
      transform: scale(1.02);
    }
    .btn-secondary {
      background: var(--green);
      color: #fff;
    }
    .motto-banner {
      text-align: center;
      padding: 12px;
      background: var(--forest);
      border: 1px solid var(--border);
      border-radius: 30px;
      font-family: 'Poppins', sans-serif;
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 1.5px;
      color: var(--sage);
      margin-top: 24px;
    }
    footer {
      text-align: center;
      padding: 20px;
      font-size: 12px;
      color: var(--text-muted);
      border-top: 1px solid var(--border);
      background: var(--surface);
    }
  </style>
</head>
<body>
  <header>
    <div class="logo-container">
      <div class="logo-badge">H</div>
      <div>
        <span class="brand-title">HABITAT</span>
        <span class="tagline">Build the life you want to live.</span>
      </div>
    </div>
    <div class="status-badge">
      <div class="status-dot"></div>
      <span>System Active • Local-First Engine</span>
    </div>
  </header>

  <main>
    <section>
      <div class="hud-grid">
        <div class="hud-item">
          <div class="hud-label">🔥 Consistency</div>
          <div class="hud-value" id="streak-val">7 Days</div>
        </div>
        <div class="hud-item">
          <div class="hud-label">🌱 Growth Points</div>
          <div class="hud-value" id="xp-val">280 XP</div>
        </div>
      </div>

      <div class="card">
        <h2>📋 Today's Action Queue</h2>
        <div id="tasks-list">
          <div class="task-row">
            <div class="task-info">
              <h4>08:00 • Morning Movement</h4>
              <p>15 Push-ups • Video proof required</p>
            </div>
            <button class="btn" onclick="triggerAction('Morning Movement')">Start Action</button>
          </div>
          <div class="task-row">
            <div class="task-info">
              <h4>09:30 • Brush & Capture</h4>
              <p>Habit reinforcement • Photo proof</p>
            </div>
            <button class="btn" onclick="triggerAction('Brush & Capture')">Start Action</button>
          </div>
          <div class="task-row">
            <div class="task-info">
              <h4>18:00 • Step Outside</h4>
              <p>5-Minute sunlight walk • Photo proof</p>
            </div>
            <button class="btn btn-secondary" onclick="triggerAction('Step Outside')">Upcoming</button>
          </div>
        </div>
      </div>

      <div class="motto-banner">
        🌿 YOUR HABITAT. YOUR ACTIONS. YOUR GROWTH.
      </div>
    </section>

    <aside>
      <div class="card">
        <h2>⚡ Live System Status</h2>
        <p style="font-size: 13px; color: var(--text-secondary); line-height: 1.6; margin-bottom: 16px;">
          Habitat Engine v1.0.0 is running with native SQLite persistence, 5-minute non-lethal escalation, and zero-cloud independence.
        </p>
        <div style="font-size: 12px; color: var(--sage); margin-bottom: 16px;">
          ✓ REST API: <code>/api/v1/</code><br>
          ✓ WebSocket: <code>/ws</code><br>
          ✓ Health Check: <code>/health</code>
        </div>
        <button class="btn" style="width: 100%; justify-content: center;" onclick="testHealth()">Check Health Endpoint</button>
      </div>

      <div class="card">
        <h2>🌱 Habitat Growth Stage</h2>
        <div style="text-align: center; padding: 12px 0;">
          <div style="font-size: 40px; margin-bottom: 8px;">🌱</div>
          <div style="font-family: 'Poppins'; font-weight: 700; color: #fff;">Stage: Sprout</div>
          <div style="font-size: 12px; color: var(--text-secondary); margin-top: 4px;">4 actions until Plant stage</div>
        </div>
      </div>
    </aside>
  </main>

  <footer>
    Habitat v1.0.0 • Build the life you want to live.
  </footer>

  <script>
    function triggerAction(name) {
      alert('Action initiated: ' + name + '\\nProof capture verified locally. +20 Growth Points awarded!');
      const xpEl = document.getElementById('xp-val');
      const currentXp = parseInt(xpEl.innerText) || 280;
      xpEl.innerText = (currentXp + 20) + ' XP';
    }

    async function testHealth() {
      try {
        const res = await fetch('/health');
        const data = await res.json();
        alert('Health Check OK: ' + JSON.stringify(data, null, 2));
      } catch (err) {
        alert('Error: ' + err.message);
      }
    }
  </script>
</body>
</html>`);
});

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
