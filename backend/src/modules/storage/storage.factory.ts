// Storage Provider Factory & Singleton Container
import { IStorageProvider } from './domain/storage-provider.interface';
import { LocalStorageProvider } from './infrastructure/local-storage.provider';
import { S3StorageProvider } from './infrastructure/s3-storage.provider';

export class StorageFactory {
  private static instance: IStorageProvider | null = null;

  public static getProvider(): IStorageProvider {
    if (this.instance) {
      return this.instance;
    }

    const providerType = process.env.STORAGE_PROVIDER || 'local';

    if (providerType.toLowerCase() === 's3') {
      const bucket = process.env.AWS_S3_BUCKET || 'habitat-proofs';
      const region = process.env.AWS_REGION || 'us-east-1';
      const endpoint = process.env.AWS_ENDPOINT; // e.g. http://localhost:9000 for local MinIO
      const accessKeyId = process.env.AWS_ACCESS_KEY_ID;
      const secretAccessKey = process.env.AWS_SECRET_ACCESS_KEY;

      this.instance = new S3StorageProvider({
        bucket,
        region,
        endpoint,
        accessKeyId,
        secretAccessKey
      });
    } else {
      this.instance = new LocalStorageProvider();
    }

    return this.instance;
  }

  public static setProvider(provider: IStorageProvider): void {
    this.instance = provider;
  }

  public static resetForTesting(): void {
    this.instance = null;
  }
}
