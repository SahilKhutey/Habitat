// WebSocket Notification Gateway for Real-Time Sirens & Mission Sync
import { WebSocketServer, WebSocket } from 'ws';
import { Server } from 'http';

export class NotificationGateway {
  private static wss: WebSocketServer | null = null;
  private static clients: Map<string, Set<WebSocket>> = new Map();

  public static initialize(server: Server): void {
    this.wss = new WebSocketServer({ server, path: '/ws' });

    this.wss.on('connection', (ws: any) => {
      ws.isAlive = true;

      ws.on('message', (data: string) => {
        try {
          const msg = JSON.parse(data.toString());
          if (msg.type === 'REGISTER' && msg.userId) {
            ws.userId = msg.userId;
            if (!this.clients.has(msg.userId)) {
              this.clients.set(msg.userId, new Set());
            }
            this.clients.get(msg.userId)!.add(ws);
          }
        } catch (e) {}
      });

      ws.on('close', () => {
        if (ws.userId && this.clients.has(ws.userId)) {
          this.clients.get(ws.userId)!.delete(ws);
        }
      });
    });

    console.log('[WS] NotificationGateway running on /ws');
  }

  public static sendToUser(userId: string, eventType: string, payload: any): void {
    const userSockets = this.clients.get(userId);
    if (!userSockets || userSockets.size === 0) return;

    const message = JSON.stringify({
      type: eventType,
      payload,
      timestamp: new Date().toISOString()
    });

    userSockets.forEach((ws) => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(message);
      }
    });
  }
}
