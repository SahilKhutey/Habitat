// Unit Tests: ProofRepository & TransactionManager
import { describe, it, expect, beforeEach } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { proofRepository } from '../src/repositories/proof.repository';
import { TransactionManager } from '../src/db/transaction-manager';

describe('ProofRepository & TransactionManager', () => {
  beforeEach(() => {
    DatabaseService.resetDbForTesting();
    const db = DatabaseService.getDb();
    db.prepare(`
      INSERT INTO users (id, email, password_hash, display_name, created_at, updated_at)
      VALUES ('user-uuid-303', 'test@habitat.com', 'h', 'Test User', datetime('now'), datetime('now')),
             ('u-tx', 'tx@habitat.com', 'h', 'TX User', datetime('now'), datetime('now'))
    `).run();
    db.prepare(`
      INSERT INTO tasks (id, slug, title, description, instructions, category, proof_type, validation_rules, created_at)
      VALUES ('task-1', 'tpl-pushups-10', 'Pushups', 'Do 10 reps', 'Full depth', 'PHYSICAL', 'VIDEO', '{}', datetime('now'))
    `).run();
    db.prepare(`
      INSERT INTO missions (id, user_id, task_id, scheduled_at, status, created_at)
      VALUES ('mission-uuid-202', 'user-uuid-303', 'task-1', datetime('now'), 'SCHEDULED', datetime('now')),
             ('m-tx', 'u-tx', 'task-1', datetime('now'), 'SCHEDULED', datetime('now'))
    `).run();
  });

  it('creates, retrieves, and queries proofs by mission and upload ID', () => {
    const proof = proofRepository.create({
      id: 'proof-uuid-101',
      missionId: 'mission-uuid-202',
      userId: 'user-uuid-303',
      uploadId: 'upl_test_999',
      mediaType: 'VIDEO',
      storageKey: 'proofs/user-uuid-303/mission-uuid-202/proof-uuid-101/original.mp4',
      objectKey: 'proofs/user-uuid-303/mission-uuid-202/proof-uuid-101/original.mp4',
      mimeType: 'video/mp4',
      sizeBytes: 2048000,
      verificationStatus: 'PENDING'
    });

    expect(proof.id).toBe('proof-uuid-101');
    expect(proof.verificationStatus).toBe('PENDING');

    const fetched = proofRepository.findById('proof-uuid-101');
    expect(fetched).toBeDefined();
    expect(fetched?.uploadId).toBe('upl_test_999');

    const byMission = proofRepository.findByMissionId('mission-uuid-202');
    expect(byMission.length).toBe(1);
    expect(byMission[0].id).toBe('proof-uuid-101');

    const byUpload = proofRepository.findByUploadId('upl_test_999');
    expect(byUpload).toBeDefined();
    expect(byUpload?.id).toBe('proof-uuid-101');
  });

  it('marks upload complete with file size and SHA-256 hash', () => {
    const proof = proofRepository.create({
      id: 'proof-uuid-102',
      missionId: 'mission-uuid-202',
      userId: 'user-uuid-303',
      mediaType: 'PHOTO',
      storageKey: 'proofs/u/m/p/original.jpg',
      verificationStatus: 'PENDING'
    });

    const sha256Hash = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
    proofRepository.markUploadComplete('proof-uuid-102', 154200, sha256Hash);

    const updated = proofRepository.findById('proof-uuid-102');
    expect(updated?.verificationStatus).toBe('UPLOADED');
    expect(updated?.sizeBytes).toBe(154200);
    expect(updated?.sha256).toBe(sha256Hash);
    expect(updated?.uploadedAt).toBeDefined();
  });

  it('updates verification decision and rejection reason', () => {
    proofRepository.create({
      id: 'proof-uuid-103',
      missionId: 'mission-uuid-202',
      userId: 'user-uuid-303',
      mediaType: 'VIDEO',
      storageKey: 'proofs/u/m/p/original.mp4',
      verificationStatus: 'PENDING'
    });

    proofRepository.updateVerification('proof-uuid-103', 'ACCEPTED', null);
    const accepted = proofRepository.findById('proof-uuid-103');
    expect(accepted?.verificationStatus).toBe('ACCEPTED');
    expect(accepted?.verifiedAt).toBeDefined();

    proofRepository.updateVerification('proof-uuid-103', 'REJECTED', 'Shallow reps');
    const rejected = proofRepository.findById('proof-uuid-103');
    expect(rejected?.verificationStatus).toBe('REJECTED');
    expect(rejected?.rejectionReason).toBe('Shallow reps');
  });

  it('TransactionManager: commits multiple writes atomically', () => {
    TransactionManager.run(() => {
      proofRepository.create({
        id: 'tx-proof-1',
        missionId: 'm-tx',
        userId: 'u-tx',
        mediaType: 'PHOTO',
        storageKey: 'k1'
      });
      proofRepository.create({
        id: 'tx-proof-2',
        missionId: 'm-tx',
        userId: 'u-tx',
        mediaType: 'PHOTO',
        storageKey: 'k2'
      });
    });

    expect(proofRepository.findById('tx-proof-1')).toBeDefined();
    expect(proofRepository.findById('tx-proof-2')).toBeDefined();
  });

  it('TransactionManager: rolls back all operations if an error occurs', () => {
    expect(() => {
      TransactionManager.run(() => {
        proofRepository.create({
          id: 'tx-rollback-proof',
          missionId: 'm-tx',
          userId: 'u-tx',
          mediaType: 'PHOTO',
          storageKey: 'k3'
        });
        throw new Error('SIMULATED_TRANSACTION_FAILURE');
      });
    }).toThrow('SIMULATED_TRANSACTION_FAILURE');

    expect(proofRepository.findById('tx-rollback-proof')).toBeNull();
  });
});
