// Automated Test Suite for Milestone B4: Environment-driven Database Factory & Provider Selection
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { DatabaseFactory } from '../src/db/database.factory';
import { PrismaService } from '../src/db/prisma';
import { SqliteUserRepository, PrismaUserRepository } from '../src/repositories/user.repository';
import { SqliteTaskRepository, PrismaTaskRepository } from '../src/repositories/task.repository';
import { SqliteAlarmRepository, PrismaAlarmRepository } from '../src/repositories/alarm.repository';
import { SqliteMissionRepository, PrismaMissionRepository } from '../src/repositories/mission.repository';
import { SqliteProofRepository, PrismaProofRepository } from '../src/repositories/proof.repository';

describe('Milestone B4: Environment-Driven Database Factory', () => {
  const originalEnv = { ...process.env };

  beforeEach(() => {
    DatabaseFactory.resetCacheForTesting();
    // Provide offline mock Prisma client for factory instantiation tests
    PrismaService.setClientForTesting({
      user: {},
      task: {},
      alarm: {},
      mission: {},
      proof: {},
      $disconnect: async () => {},
    } as any);
  });

  afterEach(() => {
    process.env = { ...originalEnv };
    DatabaseFactory.resetCacheForTesting();
    PrismaService.setClientForTesting(null as any);
  });

  it('B4.1: NODE_ENV=test strictly forces SQLite provider by default', () => {
    process.env.NODE_ENV = 'test';
    process.env.DB_PROVIDER = 'postgres';

    const provider = DatabaseFactory.resolveProvider();
    expect(provider).toBe('sqlite');

    const repos = DatabaseFactory.getRepositories();
    expect(repos.users).toBeInstanceOf(SqliteUserRepository);
    expect(repos.tasks).toBeInstanceOf(SqliteTaskRepository);
    expect(repos.alarms).toBeInstanceOf(SqliteAlarmRepository);
    expect(repos.missions).toBeInstanceOf(SqliteMissionRepository);
    expect(repos.proofs).toBeInstanceOf(SqliteProofRepository);
  });

  it('B4.2: Explicit sqlite provider returns SQLite repository suite', () => {
    const repos = DatabaseFactory.createRepositories('sqlite');
    expect(repos.users).toBeInstanceOf(SqliteUserRepository);
    expect(repos.tasks).toBeInstanceOf(SqliteTaskRepository);
    expect(repos.alarms).toBeInstanceOf(SqliteAlarmRepository);
    expect(repos.missions).toBeInstanceOf(SqliteMissionRepository);
    expect(repos.proofs).toBeInstanceOf(SqliteProofRepository);
  });

  it('B4.3: Explicit postgres provider returns Prisma repository suite', () => {
    const repos = DatabaseFactory.createRepositories('postgres');
    expect(repos.users).toBeInstanceOf(PrismaUserRepository);
    expect(repos.tasks).toBeInstanceOf(PrismaTaskRepository);
    expect(repos.alarms).toBeInstanceOf(PrismaAlarmRepository);
    expect(repos.missions).toBeInstanceOf(PrismaMissionRepository);
    expect(repos.proofs).toBeInstanceOf(PrismaProofRepository);
  });

  it('B4.4: DB_PROVIDER=postgres in non-test environment returns Prisma provider', () => {
    process.env.NODE_ENV = 'production';
    process.env.DB_PROVIDER = 'postgres';

    const provider = DatabaseFactory.resolveProvider();
    expect(provider).toBe('postgres');

    const repos = DatabaseFactory.createRepositories();
    expect(repos.users).toBeInstanceOf(PrismaUserRepository);
    expect(repos.tasks).toBeInstanceOf(PrismaTaskRepository);
  });

  it('B4.5: Unsupported DB_PROVIDER throws explicit fail-fast Error', () => {
    expect(() => DatabaseFactory.resolveProvider('garbage')).toThrowError(
      'Unsupported DB_PROVIDER: "garbage". Expected "sqlite" or "postgres".'
    );

    expect(() => DatabaseFactory.resolveProvider('mysql')).toThrowError(
      'Unsupported DB_PROVIDER: "mysql". Expected "sqlite" or "postgres".'
    );
  });

  it('B4.6: DatabaseFactory caches repository container for active provider', () => {
    const repos1 = DatabaseFactory.getRepositories();
    const repos2 = DatabaseFactory.getRepositories();
    expect(repos1).toBe(repos2);
  });
});
