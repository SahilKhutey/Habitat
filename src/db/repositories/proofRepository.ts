// Proof Asset Repository
import { DatabaseService } from '../connection';
import { ProofAsset, VerificationStatus } from '../../domain/types';
import { v4 as uuidv4 } from 'uuid';

export class ProofRepository {
  public static getByMissionId(missionId: string): ProofAsset[] {
    const db = DatabaseService.getDb();
    const rows = db.prepare('SELECT * FROM proof_assets WHERE mission_id = ? ORDER BY captured_at DESC').all(missionId) as any[];
    return rows.map(this.mapToProof);
  }

  public static getById(id: string): ProofAsset | null {
    const db = DatabaseService.getDb();
    const row = db.prepare('SELECT * FROM proof_assets WHERE id = ?').get(id) as any;
    if (!row) return null;
    return this.mapToProof(row);
  }

  public static create(proof: Omit<ProofAsset, 'id' | 'createdAt'>): ProofAsset {
    const db = DatabaseService.getDb();
    const id = uuidv4();
    const now = new Date().toISOString();

    const stmt = db.prepare(`
      INSERT INTO proof_assets (id, mission_id, media_type, storage_url, thumbnail_url, captured_at, device_metadata, verification_status, ai_confidence_score, rejection_reason, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    stmt.run(
      id,
      proof.missionId,
      proof.mediaType,
      proof.storageUrl,
      proof.thumbnailUrl ?? null,
      proof.capturedAt,
      JSON.stringify(proof.deviceMetadata || {}),
      proof.verificationStatus,
      proof.aiConfidenceScore ?? null,
      proof.rejectionReason ?? null,
      now
    );

    return {
      ...proof,
      id,
      createdAt: now
    };
  }

  public static updateStatus(
    id: string,
    status: VerificationStatus,
    confidence?: number,
    rejectionReason?: string
  ): void {
    const db = DatabaseService.getDb();
    const stmt = db.prepare(`
      UPDATE proof_assets 
      SET verification_status = ?, ai_confidence_score = ?, rejection_reason = ?
      WHERE id = ?
    `);
    stmt.run(status, confidence ?? null, rejectionReason ?? null, id);
  }

  private static mapToProof(row: any): ProofAsset {
    return {
      id: row.id,
      missionId: row.mission_id,
      mediaType: row.media_type,
      storageUrl: row.storage_url,
      thumbnailUrl: row.thumbnail_url,
      capturedAt: row.captured_at,
      deviceMetadata: JSON.parse(row.device_metadata || '{}'),
      verificationStatus: row.verification_status as VerificationStatus,
      aiConfidenceScore: row.ai_confidence_score,
      rejectionReason: row.rejection_reason,
      createdAt: row.created_at
    };
  }
}
