// Infrastructure Boundary: Managed Prisma Client Lifecycle
import { PrismaClient } from '@prisma/client';

export class PrismaService {
  private static instance: PrismaClient | null = null;

  public static getClient(): PrismaClient {
    if (!this.instance) {
      this.instance = new PrismaClient({
        log: process.env.NODE_ENV === 'development' ? ['warn', 'error'] : ['error']
      });
    }
    return this.instance;
  }

  public static async disconnect(): Promise<void> {
    if (this.instance) {
      await this.instance.$disconnect();
      this.instance = null;
    }
  }

  public static setClientForTesting(mockClient: PrismaClient): void {
    this.instance = mockClient;
  }
}

export const prisma = PrismaService.getClient();
