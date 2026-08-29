// SQLite Proof Asset Repository Implementation
import { DatabaseService } from '../db/connection';
import { IProofRepository, ProofAssetEntity } from './interfaces/proof.repository.interface';
import { v4 as uuidv4 } from 'uuid';

export class ProofRepository implements IProofRepository {
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
      telemetry = JSON.parse(row.device_telemetry || '{}');
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
      sizeBytes: row.size_bytes,
      sha256: row.sha256,
      durationMs: row.duration_ms,
      width: row.width,
      height: row.height,
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

export const proofRepository = new ProofRepository();
