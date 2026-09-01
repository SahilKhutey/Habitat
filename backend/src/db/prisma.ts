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

// Lazy proxy so importing this module never eagerly instantiates PrismaClient
export const prisma: PrismaClient = new Proxy({} as PrismaClient, {
  get(_target, prop) {
    const client = PrismaService.getClient() as any;
    const value = client[prop];
    return typeof value === 'function' ? value.bind(client) : value;
  }
});
