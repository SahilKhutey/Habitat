// Storage Provider Domain Interface & Contracts

export interface UploadSessionRequest {
  userId: string;
  missionId: string;
  proofId: string;
  mediaType: 'PHOTO' | 'VIDEO';
  contentType: 'image/jpeg' | 'image/png' | 'video/mp4' | string;
  maxFileSizeBytes?: number;
  expiresInSeconds?: number;
}

export interface UploadSessionResponse {
  uploadId: string;
  proofId: string;
  objectKey: string;
  uploadUrl: string;
  downloadUrl: string;
  headers: Record<string, string>;
  expiresAt: string;
}

export interface ObjectMetadata {
  exists: boolean;
  sizeBytes: number;
  contentType: string;
  sha256?: string;
  lastModified?: Date;
}

export interface IStorageProvider {
  readonly providerType: 'LOCAL' | 'S3';

  createUploadSession(request: UploadSessionRequest): Promise<UploadSessionResponse>;
  getDownloadUrl(objectKey: string, expiresInSeconds?: number): Promise<string>;
  verifyObject(objectKey: string): Promise<ObjectMetadata>;
  deleteObject(objectKey: string): Promise<void>;
  saveBuffer?(objectKey: string, buffer: Buffer, contentType: string): Promise<ObjectMetadata>;
  getObjectBuffer(objectKey: string): Promise<Buffer>;
}
