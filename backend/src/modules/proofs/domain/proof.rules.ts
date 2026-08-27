// Proof Validation Rules & Configuration Limits

export const proofLimits = {
  photoMaxBytes: 15 * 1024 * 1024, // 15 MB
  videoMaxBytes: 50 * 1024 * 1024, // 50 MB
  videoMaxDurationSeconds: 60,
  videoMinDurationSeconds: 5,
  allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime']
};

export class ProofRules {
  public static validateUploadSession(params: {
    type: 'PHOTO' | 'VIDEO' | 'NONE' | 'PHOTO_OR_VIDEO';
    mimeType: string;
    sizeBytes: number;
    durationSeconds?: number;
  }): void {
    if (!proofLimits.allowedMimeTypes.includes(params.mimeType)) {
      throw new Error(`INVALID_FORMAT: Unsupported MIME type ${params.mimeType}`);
    }

    if (params.type === 'PHOTO' || params.mimeType.startsWith('image/')) {
      if (params.sizeBytes <= 0) {
        throw new Error('INVALID_FILE: Photo file is empty');
      }
      if (params.sizeBytes > proofLimits.photoMaxBytes) {
        throw new Error(`FILE_TOO_LARGE: Photo exceeds maximum limit of ${proofLimits.photoMaxBytes / (1024 * 1024)}MB`);
      }
    }

    if (params.type === 'VIDEO' || params.mimeType.startsWith('video/')) {
      if (params.sizeBytes <= 0) {
        throw new Error('INVALID_FILE: Video file is empty');
      }
      if (params.sizeBytes > proofLimits.videoMaxBytes) {
        throw new Error(`FILE_TOO_LARGE: Video exceeds maximum limit of ${proofLimits.videoMaxBytes / (1024 * 1024)}MB`);
      }
      if (params.durationSeconds !== undefined && params.durationSeconds > proofLimits.videoMaxDurationSeconds) {
        throw new Error(`VIDEO_TOO_LONG: Video duration exceeds maximum ${proofLimits.videoMaxDurationSeconds} seconds`);
      }
    }
  }
}
