// Production Proof File Storage Engine
import fs from 'fs';
import path from 'path';
import crypto from 'crypto';

export interface ProofFileMetadata {
  storageKey: string;
  filePath: string;
  fileSizeBytes: number;
  sha256: string;
  createdAt: string;
  mimeType: string;
}

export class ProofFileStore {
  private static baseStorageDir = path.resolve(process.cwd(), 'data', 'proofs');

  public static setStorageDirForTesting(customDir: string): void {
    this.baseStorageDir = customDir;
  }

  public static getStorageDir(): string {
    return this.baseStorageDir;
  }

  public static computeSha256(bytes: Buffer): string {
    return crypto.createHash('sha256').update(bytes).digest('hex');
  }

  public static async saveProof(params: {
    missionId: string;
    proofId: string;
    bytes: Buffer;
    extension?: string;
    mimeType?: string;
  }): Promise<ProofFileMetadata> {
    const ext = (params.extension || 'bin').replace(/^\./, '');
    const missionDir = path.join(this.baseStorageDir, params.missionId);

    if (!fs.existsSync(missionDir)) {
      fs.mkdirSync(missionDir, { recursive: true });
    }

    const filename = `${params.proofId}.${ext}`;
    const filePath = path.join(missionDir, filename);
    const storageKey = `proofs/${params.missionId}/${filename}`;

    fs.writeFileSync(filePath, params.bytes);

    const sha256 = this.computeSha256(params.bytes);

    return {
      storageKey,
      filePath,
      fileSizeBytes: params.bytes.length,
      sha256,
      createdAt: new Date().toISOString(),
      mimeType: params.mimeType || 'application/octet-stream'
    };
  }

  public static readProof(storageKey: string): Buffer {
    const filePath = this.resolvePath(storageKey);
    if (!fs.existsSync(filePath)) {
      throw new Error(`FILE_NOT_FOUND: Proof file not found at ${storageKey}`);
    }
    return fs.readFileSync(filePath);
  }

  public static exists(storageKey: string): boolean {
    const filePath = this.resolvePath(storageKey);
    return fs.existsSync(filePath);
  }

  public static deleteProof(storageKey: string): boolean {
    const filePath = this.resolvePath(storageKey);
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
      return true;
    }
    return false;
  }

  public static getMetadata(storageKey: string): ProofFileMetadata | null {
    const filePath = this.resolvePath(storageKey);
    if (!fs.existsSync(filePath)) return null;

    const stats = fs.statSync(filePath);
    const bytes = fs.readFileSync(filePath);
    const sha256 = this.computeSha256(bytes);

    return {
      storageKey,
      filePath,
      fileSizeBytes: stats.size,
      sha256,
      createdAt: stats.birthtime.toISOString(),
      mimeType: storageKey.endsWith('.mp4')
        ? 'video/mp4'
        : storageKey.endsWith('.jpg') || storageKey.endsWith('.jpeg')
          ? 'image/jpeg'
          : 'application/octet-stream'
    };
  }

  private static resolvePath(storageKey: string): string {
    const cleanKey = storageKey.replace(/^proofs\//, '');
    return path.join(this.baseStorageDir, cleanKey);
  }
}
