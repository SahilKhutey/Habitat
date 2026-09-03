// Unified Database Factory & Provider Selection (Milestone B4)
import { IUserRepository, SqliteUserRepository, PrismaUserRepository } from '../repositories/user.repository';
import { ITaskRepository, SqliteTaskRepository, PrismaTaskRepository } from '../repositories/task.repository';
import { IAlarmRepository, SqliteAlarmRepository, PrismaAlarmRepository } from '../repositories/alarm.repository';
import { IMissionRepository, SqliteMissionRepository, PrismaMissionRepository } from '../repositories/mission.repository';
import { IProofRepository } from '../repositories/interfaces/proof.repository.interface';
import { SqliteProofRepository, PrismaProofRepository } from '../repositories/proof.repository';
import { PrismaService } from './prisma';

export interface DatabaseRepositories {
  users: IUserRepository;
  tasks: ITaskRepository;
  alarms: IAlarmRepository;
  missions: IMissionRepository;
  proofs: IProofRepository;
}

export type DatabaseProviderType = 'sqlite' | 'postgres';

export class DatabaseFactory {
  private static cachedRepositories: DatabaseRepositories | null = null;
  private static cachedProvider: DatabaseProviderType | null = null;

  /**
   * Resolves the active database provider following explicit precedence rules:
   * 1. In test environment (NODE_ENV === 'test'), always force 'sqlite' unless explicitly testing factory overrides.
   * 2. Otherwise inspect DB_PROVIDER or DATABASE_PROVIDER env vars (defaulting to 'sqlite').
   * 3. Throw a fail-fast error on any unsupported/typo values.
   */
  public static resolveProvider(explicitProvider?: string): DatabaseProviderType {
    if (process.env.NODE_ENV === 'test' && !explicitProvider) {
      return 'sqlite';
    }

    const raw = (explicitProvider ?? process.env.DB_PROVIDER ?? process.env.DATABASE_PROVIDER ?? 'sqlite')
      .toLowerCase()
      .trim();

    if (raw === 'sqlite') {
      return 'sqlite';
    }

    if (raw === 'postgres' || raw === 'postgresql') {
      return 'postgres';
    }

    throw new Error(
      `Unsupported DB_PROVIDER: "${raw}". Expected "sqlite" or "postgres".`
    );
  }

  /**
   * Constructs fresh repository instances for the resolved database provider
   */
  public static createRepositories(providerOverride?: string): DatabaseRepositories {
    const provider = this.resolveProvider(providerOverride);

    switch (provider) {
      case 'sqlite': {
        return {
          users: new SqliteUserRepository(),
          tasks: new SqliteTaskRepository(),
          alarms: new SqliteAlarmRepository(),
          missions: new SqliteMissionRepository(),
          proofs: new SqliteProofRepository()
        };
      }

      case 'postgres': {
        const prismaClient = PrismaService.getClient();
        return {
          users: new PrismaUserRepository(prismaClient),
          tasks: new PrismaTaskRepository(prismaClient),
          alarms: new PrismaAlarmRepository(prismaClient),
          missions: new PrismaMissionRepository(prismaClient),
          proofs: new PrismaProofRepository(prismaClient)
        };
      }
    }
  }

  /**
   * Returns cached singleton repository container for the active environment
   */
  public static getRepositories(): DatabaseRepositories {
    const activeProvider = this.resolveProvider();
    if (!this.cachedRepositories || this.cachedProvider !== activeProvider) {
      this.cachedRepositories = this.createRepositories();
      this.cachedProvider = activeProvider;
    }
    return this.cachedRepositories;
  }

  /**
   * Returns the canonical name of the active database provider
   */
  public static getProviderName(): DatabaseProviderType {
    return this.resolveProvider();
  }

  public static getTaskRepository(): ITaskRepository {
    return this.getRepositories().tasks;
  }

  public static getMissionRepository(): IMissionRepository {
    return this.getRepositories().missions;
  }

  public static getAlarmRepository(): IAlarmRepository {
    return this.getRepositories().alarms;
  }

  public static getProofRepository(): IProofRepository {
    return this.getRepositories().proofs;
  }

  public static getUserRepository(): IUserRepository {
    return this.getRepositories().users;
  }

  /**
   * Resets internal cache (for isolated unit/factory testing)
   */
  public static resetCacheForTesting(): void {
    this.cachedRepositories = null;
    this.cachedProvider = null;
  }
}
