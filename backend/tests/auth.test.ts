// Integration Tests for Phase 03: Authentication & Identity Management
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { AuthService } from '../src/modules/auth/auth.service';

describe('Phase 03: Authentication & Identity Management', () => {
  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    seedDatabase();
  });

  it('registers a new user with password hash, streak record, and welcome XP', () => {
    const email = 'marcus@habitat.discipline';
    const password = 'StrongPassword2026!';
    const displayName = 'Marcus Aurelius';

    const result = AuthService.register({
      email,
      password,
      displayName,
      timezone: 'Europe/Rome'
    });

    expect(result.user).toBeDefined();
    expect(result.user.email).toBe(email);
    expect(result.user.displayName).toBe(displayName);
    expect(result.user.disciplineScore).toBe(100);
    expect(result.user.totalXp).toBe(100); // 100 Welcome XP
    expect(result.token).toBeDefined();
    expect(typeof result.token).toBe('string');
  });

  it('rejects registration with duplicate email', () => {
    expect(() => {
      AuthService.register({
        email: 'alex@habitat.discipline', // Already seeded
        password: 'Password123!',
        displayName: 'Alex Duplicate'
      });
    }).toThrow('User with this email already exists.');
  });

  it('successfully authenticates and logs in with valid credentials', () => {
    const result = AuthService.login({
      email: 'alex@habitat.discipline',
      password: 'Discipline2026!'
    });

    expect(result.user).toBeDefined();
    expect(result.user.email).toBe('alex@habitat.discipline');
    expect(result.token).toBeDefined();

    // Verify Token signature
    const verified = AuthService.verifyToken(result.token);
    expect(verified).toBeDefined();
    expect(verified?.email).toBe('alex@habitat.discipline');
  });

  it('rejects login with incorrect password', () => {
    expect(() => {
      AuthService.login({
        email: 'alex@habitat.discipline',
        password: 'WrongPassword!'
      });
    }).toThrow('Invalid email or password.');
  });
});
