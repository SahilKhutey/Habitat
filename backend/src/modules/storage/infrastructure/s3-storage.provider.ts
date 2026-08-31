// AWS S3 & MinIO Production Storage Provider with Presigned PUT/GET URLs
import {
  S3Client,
  PutObjectCommand,
  HeadObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { v4 as uuidv4 } from 'uuid';
import {
  IStorageProvider,
  ObjectMetadata,
  UploadSessionRequest,
  UploadSessionResponse
} from '../domain/storage-provider.interface';

export interface S3StorageConfig {
  bucket: string;
  region?: string;
  endpoint?: string;
  accessKeyId?: string;
  secretAccessKey?: string;
  forcePathStyle?: boolean;
}

export class S3StorageProvider implements IStorageProvider {
  public readonly providerType = 'S3';
  private readonly client: S3Client;
  private readonly bucket: string;

  constructor(config: S3StorageConfig) {
    this.bucket = config.bucket;
    this.client = new S3Client({
      region: config.region || 'us-east-1',
      endpoint: config.endpoint || undefined,
      forcePathStyle: config.forcePathStyle ?? (!!config.endpoint), // MinIO requires path-style
      credentials: config.accessKeyId && config.secretAccessKey
        ? {
            accessKeyId: config.accessKeyId,
            secretAccessKey: config.secretAccessKey
          }
        : undefined
    });
  }

  public async createUploadSession(request: UploadSessionRequest): Promise<UploadSessionResponse> {
    const uploadId = `upl_${uuidv4().replace(/-/g, '')}`;
    const ext = this.getExtension(request.contentType, request.mediaType);

    // Server-enforced object key: proofs/{userId}/{missionId}/{proofId}/original.{ext}
    const objectKey = `proofs/${request.userId}/${request.missionId}/${request.proofId}/original.${ext}`;
    const expiresIn = request.expiresInSeconds || 300;

    const command = new PutObjectCommand({
      Bucket: this.bucket,
      Key: objectKey,
      ContentType: request.contentType
    });

    const uploadUrl = await getSignedUrl(this.client, command, { expiresIn });
    const downloadUrl = await this.getDownloadUrl(objectKey, 3600);
    const expiresAt = new Date(Date.now() + expiresIn * 1000).toISOString();

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

  public async getDownloadUrl(objectKey: string, expiresInSeconds: number = 3600): Promise<string> {
    const command = new GetObjectCommand({
      Bucket: this.bucket,
      Key: objectKey
    });

    return getSignedUrl(this.client, command, { expiresIn: expiresInSeconds });
  }

  public async verifyObject(objectKey: string): Promise<ObjectMetadata> {
    try {
      const command = new HeadObjectCommand({
        Bucket: this.bucket,
        Key: objectKey
      });

      const response = await this.client.send(command);
      return {
        exists: true,
        sizeBytes: response.ContentLength || 0,
        contentType: response.ContentType || 'application/octet-stream',
        sha256: response.ETag?.replace(/"/g, '') || undefined,
        lastModified: response.LastModified
      };
    } catch (e: any) {
      if (e.name === 'NotFound' || e.$metadata?.httpStatusCode === 404) {
        return { exists: false, sizeBytes: 0, contentType: 'application/octet-stream' };
      }
      throw e;
    }
  }

  public async deleteObject(objectKey: string): Promise<void> {
    const command = new DeleteObjectCommand({
      Bucket: this.bucket,
      Key: objectKey
    });
    await this.client.send(command);
  }

  public async getObjectBuffer(objectKey: string): Promise<Buffer> {
    const command = new GetObjectCommand({
      Bucket: this.bucket,
      Key: objectKey
    });
    const response = await this.client.send(command);
    if (!response.Body) {
      throw new Error(`Empty body for object: ${objectKey}`);
    }
    const bytes = await response.Body.transformToByteArray();
    return Buffer.from(bytes);
  }

  private getExtension(contentType: string, mediaType: 'PHOTO' | 'VIDEO'): string {
    if (contentType.includes('jpeg') || contentType.includes('jpg')) return 'jpg';
    if (contentType.includes('png')) return 'png';
    if (contentType.includes('mp4')) return 'mp4';
    return mediaType === 'VIDEO' ? 'mp4' : 'jpg';
  }
}
