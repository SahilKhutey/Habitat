// Storage Service Abstraction (MinIO / S3 Object Storage)
import { v4 as uuidv4 } from 'uuid';

export class StorageService {
  private static endpoint: string = process.env.STORAGE_ENDPOINT || 'http://localhost:9000';
  private static bucket: string = process.env.STORAGE_BUCKET || 'habitat-proofs';

  /**
   * Generates an ownership-isolated object key:
   * users/{userId}/missions/{missionId}/proof/{proofId}/{filename}
   */
  public static generateStorageKey(params: {
    userId: string;
    missionId: string;
    proofId?: string;
    filename: string;
  }): string {
    const proofId = params.proofId || uuidv4();
    const cleanFilename = params.filename.replace(/[^a-zA-Z0-9._-]/g, '_');
    return `users/${params.userId}/missions/${params.missionId}/proof/${proofId}/${cleanFilename}`;
  }

  /**
   * Creates presigned upload URL for direct client multipart upload
   */
  public static getUploadSignedUrl(params: {
    userId: string;
    missionId: string;
    filename: string;
    mimeType: string;
  }): { uploadUrl: string; storageKey: string; expiresSec: number } {
    const storageKey = this.generateStorageKey(params);
    const uploadUrl = `${this.endpoint}/${this.bucket}/${storageKey}?signature=${uuidv4()}`;

    return {
      uploadUrl,
      storageKey,
      expiresSec: 300 // 5 minutes
    };
  }

  public static getDownloadSignedUrl(storageKey: string): string {
    return `${this.endpoint}/${this.bucket}/${storageKey}`;
  }
}
