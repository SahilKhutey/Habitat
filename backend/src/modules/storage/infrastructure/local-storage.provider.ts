// Local Filesystem Storage Provider for Development & Offline Environments
import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { v4 as uuidv4 } from 'uuid';
import {
  IStorageProvider,
  ObjectMetadata,
  UploadSessionRequest,
  UploadSessionResponse
} from '../domain/storage-provider.interface';

export class LocalStorageProvider implements IStorageProvider {
  public readonly providerType = 'LOCAL';
  private readonly baseDir: string;
  private readonly baseUrl: string;

  constructor(baseDir?: string, baseUrl: string = 'http://localhost:4000') {
    this.baseDir = baseDir || path.resolve(process.cwd(), 'data', 'uploads');
    this.baseUrl = baseUrl;
    if (!fs.existsSync(this.baseDir)) {
      fs.mkdirSync(this.baseDir, { recursive: true });
    }
  }

  public async createUploadSession(request: UploadSessionRequest): Promise<UploadSessionResponse> {
    const uploadId = `upl_${uuidv4().replace(/-/g, '')}`;
    const ext = this.getExtension(request.contentType, request.mediaType);
    
    // Server-enforced object key: proofs/{userId}/{missionId}/{proofId}/original.{ext}
    const objectKey = `proofs/${request.userId}/${request.missionId}/${request.proofId}/original.${ext}`;
    const targetFilePath = path.resolve(this.baseDir, objectKey);
    const targetDir = path.dirname(targetFilePath);

    if (!fs.existsSync(targetDir)) {
      fs.mkdirSync(targetDir, { recursive: true });
    }

    const expiresAt = new Date(Date.now() + (request.expiresInSeconds || 300) * 1000).toISOString();
    const uploadUrl = `${this.baseUrl}/api/v1/storage/upload?key=${objectKey}&uploadId=${uploadId}`;
    const downloadUrl = `${this.baseUrl}/api/v1/storage/file?key=${objectKey}`;

    return {
      uploadId,
      proofId: request.proofId,
      objectKey,
      uploadUrl,
      downloadUrl,
      headers: {
        'Content-Type': request.contentType
      },
      expiresAt
    };
  }

  public async getDownloadUrl(objectKey: string, _expiresInSeconds: number = 3600): Promise<string> {
    const safeKey = this.sanitizeKey(objectKey);
    return `${this.baseUrl}/api/v1/storage/file?key=${encodeURIComponent(safeKey)}`;
  }

  public async verifyObject(objectKey: string): Promise<ObjectMetadata> {
    const safeKey = this.sanitizeKey(objectKey);
    const filePath = path.resolve(this.baseDir, safeKey);

    if (!fs.existsSync(filePath)) {
      return { exists: false, sizeBytes: 0, contentType: 'application/octet-stream' };
    }

    const stats = fs.statSync(filePath);
    const fileBuffer = fs.readFileSync(filePath);
    const sha256 = crypto.createHash('sha256').update(fileBuffer).digest('hex');
    const contentType = this.inferContentType(safeKey);

    return {
      exists: true,
      sizeBytes: stats.size,
      contentType,
      sha256,
      lastModified: stats.mtime
    };
  }

  public async saveBuffer(objectKey: string, buffer: Buffer, _contentType: string): Promise<ObjectMetadata> {
    const safeKey = this.sanitizeKey(objectKey);
    const filePath = path.resolve(this.baseDir, safeKey);
    const dir = path.dirname(filePath);

    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    fs.writeFileSync(filePath, buffer);
    return this.verifyObject(safeKey);
  }

  public async deleteObject(objectKey: string): Promise<void> {
    const safeKey = this.sanitizeKey(objectKey);
    const filePath = path.resolve(this.baseDir, safeKey);
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
  }

  public async getObjectBuffer(objectKey: string): Promise<Buffer> {
    const safeKey = this.sanitizeKey(objectKey);
    const filePath = path.resolve(this.baseDir, safeKey);
    if (!fs.existsSync(filePath)) {
      throw new Error(`Object not found: ${objectKey}`);
    }
    return fs.readFileSync(filePath);
  }

  public getFilePath(objectKey: string): string {
    const safeKey = this.sanitizeKey(objectKey);
    return path.resolve(this.baseDir, safeKey);
  }

  private sanitizeKey(key: string): string {
    // Prevent directory traversal attacks
    return key.replace(/(\.\.[\/\\])+/g, '').replace(/^[\/\\]+/, '');
  }

  private getExtension(contentType: string, mediaType: 'PHOTO' | 'VIDEO'): string {
    if (contentType.includes('jpeg') || contentType.includes('jpg')) return 'jpg';
    if (contentType.includes('png')) return 'png';
    if (contentType.includes('mp4')) return 'mp4';
    return mediaType === 'VIDEO' ? 'mp4' : 'jpg';
  }

  private inferContentType(key: string): string {
    if (key.endsWith('.jpg') || key.endsWith('.jpeg')) return 'image/jpeg';
    if (key.endsWith('.png')) return 'image/png';
    if (key.endsWith('.mp4')) return 'video/mp4';
    return 'application/octet-stream';
  }
}
