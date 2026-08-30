// Habitat Authoritative Security, Audit & IDOR Protection Layer (Phase 19)
import { v4 as uuidv4 } from 'uuid';

export type SessionState = 'ACTIVE' | 'REVOKED' | 'EXPIRED' | 'COMPROMISED';

export interface UserSession {
  id: string;
  userId: string;
  refreshToken: string;
  state: SessionState;
  createdAt: Date;
  expiresAt: Date;
  lastUsedAt: Date;
}

export interface SecurityAuditEvent {
  id: string;
  eventType: string;
  userId: string;
  resourceId?: string;
  requestId: string;
  reason?: string;
  metadata?: Record<string, any>;
  timestamp: Date;
}

export class SecurityService {
  private static sessions: Map<string, UserSession> = new Map();
  private static auditLogs: SecurityAuditEvent[] = [];
  private static rateLimitMap: Map<string, { count: number; windowStart: number }> = new Map();

  public static createSession(userId: string, refreshToken: string, expiryDays: number = 30): UserSession {
    const session: UserSession = {
      id: uuidv4(),
      userId,
      refreshToken,
      state: 'ACTIVE',
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + expiryDays * 24 * 60 * 60 * 1000),
      lastUsedAt: new Date(),
    };
    this.sessions.set(session.id, session);
    return session;
  }

  public static getSessionByToken(refreshToken: string): UserSession | null {
    for (const session of this.sessions.values()) {
      if (session.refreshToken === refreshToken) {
        if (session.state === 'ACTIVE' && session.expiresAt.getTime() < Date.now()) {
          session.state = 'EXPIRED';
        }
        return session;
      }
    }
    return null;
  }

  public static revokeSession(sessionId: string): boolean {
    const session = this.sessions.get(sessionId);
    if (session) {
      session.state = 'REVOKED';
      return true;
    }
    return false;
  }

  public static revokeAllUserSessions(userId: string): number {
    let count = 0;
    for (const session of this.sessions.values()) {
      if (session.userId === userId && session.state === 'ACTIVE') {
        session.state = 'REVOKED';
        count++;
      }
    }
    return count;
  }

  public static validateOwnership(userId: string, ownerId: string, resourceName: string = 'Resource'): void {
    if (userId !== ownerId) {
      throw new Error(`FORBIDDEN_IDOR_VIOLATION: User ${userId} is not authorized to access or modify ${resourceName} owned by ${ownerId}`);
    }
  }

  public static checkRateLimit(key: string, limit: number, windowSeconds: number = 60): { allowed: boolean; remaining: number } {
    const now = Date.now();
    const entry = this.rateLimitMap.get(key);
    if (!entry || now - entry.windowStart > windowSeconds * 1000) {
      this.rateLimitMap.set(key, { count: 1, windowStart: now });
      return { allowed: true, remaining: limit - 1 };
    }
    if (entry.count >= limit) {
      return { allowed: false, remaining: 0 };
    }
    entry.count++;
    return { allowed: true, remaining: limit - entry.count };
  }

  public static recordAuditLog(event: Omit<SecurityAuditEvent, 'id' | 'timestamp'>): SecurityAuditEvent {
    const auditEvent: SecurityAuditEvent = {
      id: uuidv4(),
      ...event,
      timestamp: new Date(),
    };
    this.auditLogs.push(auditEvent);
    return auditEvent;
  }

  public static getAuditLogs(userId?: string): SecurityAuditEvent[] {
    if (userId) {
      return this.auditLogs.filter(l => l.userId === userId);
    }
    return [...this.auditLogs];
  }

  public static sanitizePayload(data: Record<string, any>): Record<string, any> {
    const sanitized = { ...data };
    delete sanitized.password;
    delete sanitized.passwordHash;
    delete sanitized.token;
    delete sanitized.refreshToken;
    delete sanitized.gps;
    delete sanitized.location;
    return sanitized;
  }

  public static clearAllForTesting(): void {
    this.sessions.clear();
    this.auditLogs = [];
    this.rateLimitMap.clear();
  }
}
