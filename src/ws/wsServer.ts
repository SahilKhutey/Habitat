// WebSocket Server Daemon for Habitat Real-Time Events
import { WebSocketServer, WebSocket } from 'ws';
import { Server } from 'http';
import { WsMessage, WsEventType } from './events';

interface AuthenticatedSocket extends WebSocket {
  userId?: string;
  isAlive?: boolean;
}

export class HabitatWsServer {
  private static instance: HabitatWsServer | null = null;
  private wss: WebSocketServer | null = null;
  private clients: Map<string, Set<AuthenticatedSocket>> = new Map();

  public static initialize(server: Server): HabitatWsServer {
    if (!this.instance) {
      this.instance = new HabitatWsServer(server);
    }
    return this.instance;
  }

  public static getInstance(): HabitatWsServer {
    if (!this.instance) {
      throw new Error('HabitatWsServer not initialized. Call initialize(server) first.');
    }
    return this.instance;
  }

  private constructor(server: Server) {
    this.wss = new WebSocketServer({ server, path: '/ws' });

    this.wss.on('connection', (ws: AuthenticatedSocket) => {
      ws.isAlive = true;

      ws.on('pong', () => {
        ws.isAlive = true;
      });

      ws.on('message', (data: string) => {
        try {
          const message: WsMessage = JSON.parse(data.toString());
          this.handleClientMessage(ws, message);
        } catch (e) {
          console.error('[WS] Failed to parse message:', e);
        }
      });

      ws.on('close', () => {
        if (ws.userId) {
          const userSockets = this.clients.get(ws.userId);
          if (userSockets) {
            userSockets.delete(ws);
            if (userSockets.size === 0) {
              this.clients.delete(ws.userId);
            }
          }
        }
      });
    });

    // Heartbeat ping loop every 30 seconds
    setInterval(() => {
      if (!this.wss) return;
      this.wss.clients.forEach((ws: WebSocket) => {
        const authWs = ws as AuthenticatedSocket;
        if (!authWs.isAlive) {
          return authWs.terminate();
        }
        authWs.isAlive = false;
        authWs.ping();
      });
    }, 30000);

    console.log('[WS] Habitat WebSocket Daemon active on /ws');
  }

  private handleClientMessage(ws: AuthenticatedSocket, msg: WsMessage): void {
    if (msg.type === 'CLIENT_REGISTER') {
      const userId = msg.payload?.userId;
      if (userId) {
        ws.userId = userId;
        if (!this.clients.has(userId)) {
          this.clients.set(userId, new Set());
        }
        this.clients.get(userId)!.add(ws);
        this.send(ws, {
          type: 'STATE_SYNC',
          payload: { registered: true, userId, timestamp: new Date().toISOString() },
          timestamp: new Date().toISOString()
        });
      }
    }
  }

  public sendToUser<T>(userId: string, type: WsEventType, payload: T): void {
    const userSockets = this.clients.get(userId);
    if (!userSockets || userSockets.size === 0) {
      return;
    }

    const message: WsMessage<T> = {
      type,
      payload,
      timestamp: new Date().toISOString()
    };

    const serialized = JSON.stringify(message);
    userSockets.forEach((ws) => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(serialized);
      }
    });
  }

  public broadcastAll<T>(type: WsEventType, payload: T): void {
    if (!this.wss) return;
    const message: WsMessage<T> = {
      type,
      payload,
      timestamp: new Date().toISOString()
    };
    const serialized = JSON.stringify(message);
    this.wss.clients.forEach((ws) => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(serialized);
      }
    });
  }

  private send<T>(ws: WebSocket, message: WsMessage<T>): void {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify(message));
    }
  }
}
