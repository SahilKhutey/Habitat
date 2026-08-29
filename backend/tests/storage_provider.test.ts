// Unit Tests: Storage Provider Abstraction (LocalStorageProvider & S3StorageProvider)
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import fs from 'fs';
import path from 'path';
import { LocalStorageProvider } from '../src/modules/storage/infrastructure/local-storage.provider';
import { S3StorageProvider } from '../src/modules/storage/infrastructure/s3-storage.provider';
import { StorageFactory } from '../src/modules/storage/storage.factory';

describe('StorageProvider Abstraction', () => {
  const testUploadsDir = path.resolve(__dirname, 'temp_test_uploads');

  beforeEach(() => {
    StorageFactory.resetForTesting();
    if (!fs.existsSync(testUploadsDir)) {
      fs.mkdirSync(testUploadsDir, { recursive: true });
    }
  });

  afterEach(() => {
    if (fs.existsSync(testUploadsDir)) {
      fs.rmSync(testUploadsDir, { recursive: true, force: true });
    }
  });

  describe('LocalStorageProvider', () => {
    it('creates upload session with server-enforced object key hierarchy', async () => {
      const provider = new LocalStorageProvider(testUploadsDir);
      const session = await provider.createUploadSession({
        userId: 'user-789',
        missionId: 'mission-456',
        proofId: 'proof-123',
        mediaType: 'VIDEO',
        contentType: 'video/mp4',
        sizeBytes: 5000000
      });

      expect(session.uploadId).toBeDefined();
      expect(session.proofId).toBe('proof-123');
      expect(session.objectKey).toBe('proofs/user-789/mission-456/proof-123/original.mp4');
      expect(session.uploadUrl).toContain('/api/v1/storage/upload');
      expect(session.downloadUrl).toContain('/api/v1/storage/file');
      expect(session.headers['Content-Type']).toBe('video/mp4');
    });

    it('saves binary buffer, verifies object existence and computes SHA-256 hash', async () => {
      const provider = new LocalStorageProvider(testUploadsDir);
      const objectKey = 'proofs/u1/m1/p1/original.jpg';
      const testBuffer = Buffer.from('HABITAT_PROOF_RAW_BINARY_SIMULATION_DATA');

      // Initially does not exist
      const checkBefore = await provider.verifyObject(objectKey);
      expect(checkBefore.exists).toBe(false);

      // Save buffer
      const saved = await provider.saveBuffer(objectKey, testBuffer, 'image/jpeg');
      expect(saved.exists).toBe(true);
      expect(saved.sizeBytes).toBe(testBuffer.length);
      expect(saved.sha256).toBeDefined();
      expect(saved.sha256?.length).toBe(64); // 256-bit hex hash

      // Verify again
      const checkAfter = await provider.verifyObject(objectKey);
      expect(checkAfter.exists).toBe(true);
      expect(checkAfter.sizeBytes).toBe(testBuffer.length);
      expect(checkAfter.sha256).toBe(saved.sha256);

      // Delete object
      await provider.deleteObject(objectKey);
      const checkDeleted = await provider.verifyObject(objectKey);
      expect(checkDeleted.exists).toBe(false);
    });

    it('sanitizes directory traversal attack attempts in object keys', async () => {
      const provider = new LocalStorageProvider(testUploadsDir);
      const maliciousKey = '../../../../etc/passwd';
      const safePath = provider.getFilePath(maliciousKey);

      expect(safePath).not.toContain('..');
      expect(safePath.startsWith(testUploadsDir)).toBe(true);
    });
  });

  describe('S3StorageProvider', () => {
    it('creates presigned PUT upload session for S3 / MinIO targets', async () => {
      const s3Provider = new S3StorageProvider({
        bucket: 'habitat-proofs-test',
        region: 'us-east-1',
        accessKeyId: 'test-key',
        secretAccessKey: 'test-secret'
      });

      const session = await s3Provider.createUploadSession({
        userId: 'user-alpha',
        missionId: 'mission-bravo',
        proofId: 'proof-charlie',
        mediaType: 'VIDEO',
        contentType: 'video/mp4'
      });

      expect(session.uploadId).toBeDefined();
      expect(session.objectKey).toBe('proofs/user-alpha/mission-bravo/proof-charlie/original.mp4');
      expect(session.uploadUrl).toContain('https://habitat-proofs-test.s3.us-east-1.amazonaws.com');
      expect(session.uploadUrl).toContain('X-Amz-Signature');
    });
  });

  describe('StorageFactory', () => {
    it('resolves LocalStorageProvider by default and supports singleton lifecycle', () => {
      const provider = StorageFactory.getProvider();
      expect(provider.providerType).toBe('LOCAL');

      const provider2 = StorageFactory.getProvider();
      expect(provider2).toBe(provider); // Singleton identity
    });
  });
});
