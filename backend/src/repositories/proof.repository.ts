// SQLite & Prisma Proof Asset Repository Dual Implementations
import { DatabaseService } from '../db/connection';
import { PrismaService } from '../db/prisma';
import { PrismaClient } from '@prisma/client';
import { IProofRepository, ProofAssetEntity } from './interfaces/proof.repository.interface';
import { v4 as uuidv4 } from 'uuid';

/**
 * SQLite Implementation of Proof Repository
 */
export class SqliteProofRepository implements IProofRepository {
  public findById(id: string): ProofAssetEntity | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM proofs WHERE id = ?').get(id) as any;
    if (!row) return null;
    return this.mapRow(row);
  }

  public findByMissionId(missionId: string): ProofAssetEntity[] {
    const db = DatabaseService.getDb();
    const rows = db.prepare('SELECT * FROM proofs WHERE mission_id = ? ORDER BY created_at DESC').all(missionId) as any[];
    return rows.map((r) => this.mapRow(r));
  }

  public findByUploadId(uploadId: string): ProofAssetEntity | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM proofs WHERE upload_id = ?').get(uploadId) as any;
    if (!row) return null;
    return this.mapRow(row);
  }

  public create(entity: Partial<ProofAssetEntity>): ProofAssetEntity {
    const db = DatabaseService.getDb();
    const id = entity.id || uuidv4();
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO proofs (
        id, mission_id, user_id, attempt_id, upload_id, media_type, storage_key, object_key,
        thumbnail_key, mime_type, size_bytes, sha256, duration_ms, width, height,
        captured_at, uploaded_at, verified_at, device_telemetry, verification_status,
        rejection_reason, created_at, updated_at
      ) VALUES (
        ?, ?, ?, ?, ?, ?, ?, ?,
        ?, ?, ?, ?, ?, ?, ?,
        ?, ?, ?, ?, ?,
        ?, ?, ?
      )
    `).run(
      id,
      entity.missionId || '',
      entity.userId || '',
      entity.attemptId || null,
      entity.uploadId || null,
      entity.mediaType || 'PHOTO',
      entity.storageKey || entity.objectKey || '',
      entity.objectKey || entity.storageKey || '',
      entity.thumbnailKey || null,
      entity.mimeType || 'image/jpeg',
      entity.sizeBytes || 0,
      entity.sha256 || null,
      entity.durationMs || null,
      entity.width || null,
      entity.height || null,
      entity.capturedAt || now,
      entity.uploadedAt || null,
      entity.verifiedAt || null,
      JSON.stringify(entity.deviceTelemetry || {}),
      entity.verificationStatus || 'PENDING',
      entity.rejectionReason || null,
      entity.createdAt || now,
      entity.updatedAt || now
    );

    return this.findById(id)!;
  }

  public update(id: string, patch: Partial<ProofAssetEntity>): void {
    const existing = this.findById(id);
    if (!existing) return;

    const db = DatabaseService.getDb();
    const now = new Date().toISOString();

    db.prepare(`
      UPDATE proofs SET
        verification_status = COALESCE(?, verification_status),
        rejection_reason = COALESCE(?, rejection_reason),
        size_bytes = COALESCE(?, size_bytes),
        sha256 = COALESCE(?, sha256),
        uploaded_at = COALESCE(?, uploaded_at),
        verified_at = COALESCE(?, verified_at),
        updated_at = ?
      WHERE id = ?
    `).run(
      patch.verificationStatus || null,
      patch.rejectionReason || null,
      patch.sizeBytes ?? null,
      patch.sha256 || null,
      patch.uploadedAt || null,
      patch.verifiedAt || null,
      now,
      id
    );
  }

  public updateVerification(id: string, status: 'ACCEPTED' | 'REJECTED' | 'REVIEW', reason?: string | null): void {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();
    db.prepare(`
      UPDATE proofs SET
        verification_status = ?,
        rejection_reason = ?,
        verified_at = ?,
        updated_at = ?
      WHERE id = ?
    `).run(status, reason || null, now, now, id);
  }

  public markUploadComplete(id: string, sizeBytes: number, sha256: string): void {
    const db = DatabaseService.getDb();
    const now = new Date().toISOString();
    db.prepare(`
      UPDATE proofs SET
        verification_status = 'UPLOADED',
        size_bytes = ?,
        sha256 = ?,
        uploaded_at = ?,
        updated_at = ?
      WHERE id = ?
    `).run(sizeBytes, sha256, now, now, id);
  }

  public delete(id: string): void {
    const db = DatabaseService.getDb();
    db.prepare('DELETE FROM proofs WHERE id = ?').run(id);
  }

  private mapRow(row: any): ProofAssetEntity {
    let telemetry = {};
    try {
      telemetry = typeof row.device_telemetry === 'string' ? JSON.parse(row.device_telemetry || '{}') : (row.device_telemetry || {});
    } catch {
      telemetry = {};
    }

    return {
      id: row.id,
      missionId: row.mission_id,
      userId: row.user_id,
      attemptId: row.attempt_id,
      uploadId: row.upload_id,
      mediaType: row.media_type,
      storageKey: row.storage_key,
      objectKey: row.object_key || row.storage_key,
      thumbnailKey: row.thumbnail_key,
      mimeType: row.mime_type,
      sizeBytes: Number(row.size_bytes),
      sha256: row.sha256,
      durationMs: row.duration_ms !== null ? Number(row.duration_ms) : null,
      width: row.width !== null ? Number(row.width) : null,
      height: row.height !== null ? Number(row.height) : null,
      capturedAt: row.captured_at,
      uploadedAt: row.uploaded_at,
      verifiedAt: row.verified_at,
      verificationStatus: row.verification_status,
      rejectionReason: row.rejection_reason,
      deviceTelemetry: telemetry,
      createdAt: row.created_at,
      updatedAt: row.updated_at
    };
  }
}

/**
 * Prisma PostgreSQL Implementation of Proof Repository
 */
export class PrismaProofRepository implements IProofRepository {
  constructor(private readonly db: PrismaClient) {}

  public async findById(id: string): Promise<ProofAssetEntity | null> {
    const proof = await this.db.proof.findUnique({
      where: { id }
    });
    if (!proof) return null;
    return this.mapPrismaModel(proof);
  }

  public async findByMissionId(missionId: string): Promise<ProofAssetEntity[]> {
    const proofs = await this.db.proof.findMany({
      where: { missionId },
      orderBy: { createdAt: 'desc' }
    });
    return proofs.map(this.mapPrismaModel);
  }

  public async findByUploadId(uploadId: string): Promise<ProofAssetEntity | null> {
    const proof = await this.db.proof.findFirst({
      where: { uploadId }
    });
    if (!proof) return null;
    return this.mapPrismaModel(proof);
  }

  public async create(entity: Partial<ProofAssetEntity>): Promise<ProofAssetEntity> {
    const proof = await this.db.proof.create({
      data: {
        id: entity.id,
        missionId: entity.missionId || '',
        userId: entity.userId || null,
        attemptId: entity.attemptId || null,
        uploadId: entity.uploadId || null,
        mediaType: entity.mediaType || 'PHOTO',
        storageKey: entity.storageKey || entity.objectKey || '',
        objectKey: entity.objectKey || entity.storageKey || null,
        thumbnailKey: entity.thumbnailKey || null,
        mimeType: entity.mimeType || 'image/jpeg',
        sizeBytes: entity.sizeBytes || 0,
        sha256: entity.sha256 || null,
        durationMs: entity.durationMs || null,
        width: entity.width || null,
        height: entity.height || null,
        capturedAt: entity.capturedAt ? new Date(entity.capturedAt) : new Date(),
        uploadedAt: entity.uploadedAt ? new Date(entity.uploadedAt) : null,
        verifiedAt: entity.verifiedAt ? new Date(entity.verifiedAt) : null,
        deviceTelemetry: JSON.stringify(entity.deviceTelemetry || {}),
        verificationStatus: entity.verificationStatus || 'PENDING',
        rejectionReason: entity.rejectionReason || null
      }
    });

    return this.mapPrismaModel(proof);
  }

  public async update(id: string, patch: Partial<ProofAssetEntity>): Promise<void> {
    await this.db.proof.update({
      where: { id },
      data: {
        verificationStatus: patch.verificationStatus,
        rejectionReason: patch.rejectionReason,
        sizeBytes: patch.sizeBytes,
        sha256: patch.sha256,
        uploadedAt: patch.uploadedAt ? new Date(patch.uploadedAt) : undefined,
        verifiedAt: patch.verifiedAt ? new Date(patch.verifiedAt) : undefined
      }
    });
  }

  public async updateVerification(id: string, status: 'ACCEPTED' | 'REJECTED' | 'REVIEW', reason?: string | null): Promise<void> {
    await this.db.proof.update({
      where: { id },
      data: {
        verificationStatus: status,
        rejectionReason: reason || null,
        verifiedAt: new Date()
      }
    });
  }

  public async markUploadComplete(id: string, sizeBytes: number, sha256: string): Promise<void> {
    await this.db.proof.update({
      where: { id },
      data: {
        verificationStatus: 'UPLOADED',
        sizeBytes,
        sha256,
        uploadedAt: new Date()
      }
    });
  }

  public async delete(id: string): Promise<void> {
    await this.db.proof.delete({
      where: { id }
    });
  }

  private mapPrismaModel(p: any): ProofAssetEntity {
    let telemetry = {};
    try {
      telemetry = typeof p.deviceTelemetry === 'string' ? JSON.parse(p.deviceTelemetry || '{}') : (p.deviceTelemetry || {});
    } catch {
      telemetry = {};
    }

    return {
      id: p.id,
      missionId: p.missionId,
      userId: p.userId,
      attemptId: p.attemptId,
      uploadId: p.uploadId,
      mediaType: p.mediaType as any,
      storageKey: p.storageKey,
      objectKey: p.objectKey || p.storageKey,
      thumbnailKey: p.thumbnailKey,
      mimeType: p.mimeType,
      sizeBytes: p.sizeBytes,
      sha256: p.sha256,
      durationMs: p.durationMs,
      width: p.width,
      height: p.height,
      capturedAt: p.capturedAt instanceof Date ? p.capturedAt.toISOString() : String(p.capturedAt),
      uploadedAt: p.uploadedAt ? (p.uploadedAt instanceof Date ? p.uploadedAt.toISOString() : String(p.uploadedAt)) : null,
      verifiedAt: p.verifiedAt ? (p.verifiedAt instanceof Date ? p.verifiedAt.toISOString() : String(p.verifiedAt)) : null,
      verificationStatus: p.verificationStatus,
      rejectionReason: p.rejectionReason,
      deviceTelemetry: telemetry,
      createdAt: p.createdAt instanceof Date ? p.createdAt.toISOString() : String(p.createdAt),
      updatedAt: p.updatedAt ? (p.updatedAt instanceof Date ? p.updatedAt.toISOString() : String(p.updatedAt)) : null
    };
  }
}

/**
 * Facade maintaining 100% backward-compatible IProofRepository singleton
 */
export class ProofRepository implements IProofRepository {
  private sqliteAdapter = new SqliteProofRepository();
  private prismaAdapter: PrismaProofRepository | null = null;

  public findById(id: string): ProofAssetEntity | null {
    return this.sqliteAdapter.findById(id);
  }

  public findByMissionId(missionId: string): ProofAssetEntity[] {
    return this.sqliteAdapter.findByMissionId(missionId);
  }

  public findByUploadId(uploadId: string): ProofAssetEntity | null {
    return this.sqliteAdapter.findByUploadId(uploadId);
  }

  public create(entity: Partial<ProofAssetEntity>): ProofAssetEntity {
    return this.sqliteAdapter.create(entity);
  }

  public update(id: string, patch: Partial<ProofAssetEntity>): void {
    return this.sqliteAdapter.update(id, patch);
  }

  public updateVerification(id: string, status: 'ACCEPTED' | 'REJECTED' | 'REVIEW', reason?: string | null): void {
    return this.sqliteAdapter.updateVerification(id, status, reason);
  }

  public markUploadComplete(id: string, sizeBytes: number, sha256: string): void {
    return this.sqliteAdapter.markUploadComplete(id, sizeBytes, sha256);
  }

  public delete(id: string): void {
    return this.sqliteAdapter.delete(id);
  }
}

export const proofRepository = new ProofRepository();
