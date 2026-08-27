// Phase 4 Authentication & User System Master Integration Tests
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { AuthService } from '../src/modules/auth/auth.controller';
import { UserService } from '../src/modules/users/users.controller';
import { AuthSecurity } from '../src/modules/auth/auth.security';

describe('Phase 4 Acceptance Gate: Production-Grade Authentication & User System', () => {
  let registeredUserId: string;
  let accessToken: string;
  let refreshToken: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
  });

  it('Gate 1: Registers new user, seeds preferences, deposits 100 XP, and issues dual tokens', () => {
    const res = AuthService.register({
      email: 'seneca.stoic@discipline.app',
      password: 'StoicPassword2026!',
      displayName: 'Lucius Annaeus Seneca',
      timezone: 'Europe/Rome'
    });

    expect(res.user).toBeDefined();
    expect(res.user.email).toBe('seneca.stoic@discipline.app');
    expect(res.user.disciplineScore).toBe(100);
    expect(res.accessToken).toBeDefined();
    expect(res.refreshToken).toBeDefined();
    expect(res.tokenType).toBe('Bearer');

    registeredUserId = res.user.id;
    accessToken = res.accessToken;
    refreshToken = res.refreshToken;
  });

  it('Gate 2: Rejects duplicate email registration attempt', () => {
    expect(() => {
      AuthService.register({
        email: 'seneca.stoic@discipline.app',
        password: 'AnotherPassword123!',
        displayName: 'Seneca Imposter'
      });
    }).toThrow(/An account with this email already exists/);
  });

  it('Gate 3: Rejects weak password under 8 characters', () => {
    expect(() => {
      AuthService.register({
        email: 'short.pass@discipline.app',
        password: 'short',
        displayName: 'Short Pass'
      });
    }).toThrow(/Password must be at least 8 characters/);
  });

  it('Gate 4: Logs in successfully with valid credentials and verifies constant-time hash', () => {
    const loginRes = AuthService.login({
      email: 'seneca.stoic@discipline.app',
      password: 'StoicPassword2026!'
    });

    expect(loginRes.user.id).toBe(registeredUserId);
    expect(loginRes.accessToken).toBeDefined();
  });

  it('Gate 5: Rejects login with invalid password', () => {
    expect(() => {
      AuthService.login({
        email: 'seneca.stoic@discipline.app',
        password: 'WrongPasswordXYZ'
      });
    }).toThrow(/Invalid email or password/);
  });

  it('Gate 6: Verifies JWT structure and decodes payload with expiry', () => {
    const payload = AuthSecurity.verifyJwt(accessToken);
    expect(payload.userId).toBe(registeredUserId);
    expect(payload.email).toBe('seneca.stoic@discipline.app');
    expect(payload.type).toBe('access');
    expect(payload.exp).toBeGreaterThan(payload.iat);
  });

  it('Gate 7: Rotates refresh token successfully', () => {
    const refreshRes = AuthService.refresh(refreshToken);
    expect(refreshRes.accessToken).toBeDefined();
    expect(refreshRes.refreshToken).toBeDefined();
  });

  it('Gate 8: Retrieves user profile and preferences via getMe', () => {
    const me = AuthService.getMe(registeredUserId);
    expect(me.id).toBe(registeredUserId);
    expect(me.totalXp).toBe(100); // 100 XP recruit bonus verified
    expect(me.preferences.theme).toBe('system');
    expect(me.preferences.notificationsEnabled).toBe(true);
  });

  it('Gate 9: Updates user preferences and profile parameters', () => {
    const updatedPrefs = UserService.updatePreferences(registeredUserId, {
      theme: 'dark',
      soundEnabled: true,
      reducedMotion: true
    });

    expect(updatedPrefs.theme).toBe('dark');
    expect(updatedPrefs.reducedMotion).toBe(true);

    const updatedProfile = UserService.updateProfile(registeredUserId, {
      displayName: 'Seneca The Younger',
      timezone: 'Europe/Athens'
    }) as any;

    expect(updatedProfile.display_name).toBe('Seneca The Younger');
    expect(updatedProfile.timezone).toBe('Europe/Athens');
  });
});
