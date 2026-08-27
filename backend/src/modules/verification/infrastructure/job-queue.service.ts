// Verification Job Queue & Worker Service
import { v4 as uuidv4 } from 'uuid';

export interface VerificationJob {
  id: string;
  missionId: string;
  proofId: string;
  userId: string;
  attempts: number;
  maxAttempts: number;
  status: 'QUEUED' | 'PROCESSING' | 'COMPLETED' | 'FAILED';
  createdAt: Date;
}

export class VerificationJobQueueService {
  private static jobs: Map<string, VerificationJob> = new Map();

  public static enqueueJob(params: {
    missionId: string;
    proofId: string;
    userId: string;
  }): VerificationJob {
    const job: VerificationJob = {
      id: uuidv4(),
      missionId: params.missionId,
      proofId: params.proofId,
      userId: params.userId,
      attempts: 0,
      maxAttempts: 3,
      status: 'QUEUED',
      createdAt: new Date()
    };

    this.jobs.set(job.id, job);
    return job;
  }

  public static getJob(jobId: string): VerificationJob | undefined {
    return this.jobs.get(jobId);
  }

  public static completeJob(jobId: string): void {
    const job = this.jobs.get(jobId);
    if (job) {
      job.status = 'COMPLETED';
    }
  }

  public static failJob(jobId: string): void {
    const job = this.jobs.get(jobId);
    if (job) {
      job.attempts++;
      if (job.attempts >= job.maxAttempts) {
        job.status = 'FAILED';
      }
    }
  }
}
