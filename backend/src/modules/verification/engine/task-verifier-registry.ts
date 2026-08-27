// Task Verifier Registry & Strategy Router
import { OutdoorPhotoVerifier } from '../verifiers/photo/outdoor-scene-verifier';
import { BrushingPhotoVerifier } from '../verifiers/brushing/brushing-verifier';
import { PushupVideoVerifier } from '../verifiers/exercise/pushup-verifier';

export type TaskType = 'PHOTO_OUTSIDE' | 'BRUSHING_PHOTO' | 'PUSHUP_VIDEO' | 'EXERCISE_VIDEO' | 'GENERIC';

export class TaskVerifierRegistry {
  public static resolveVerifier(taskSlugOrType: string): {
    verifierName: string;
    verifierVersion: string;
    verify: (telemetry: any) => any;
  } {
    const slug = taskSlugOrType.toLowerCase();

    if (slug.includes('sunlight') || slug.includes('outside') || slug.includes('outdoor')) {
      return {
        verifierName: 'OutdoorPhotoVerifier',
        verifierVersion: OutdoorPhotoVerifier.VERSION,
        verify: (telemetry) => OutdoorPhotoVerifier.verify(telemetry)
      };
    }

    if (slug.includes('brush') || slug.includes('teeth')) {
      return {
        verifierName: 'BrushingPhotoVerifier',
        verifierVersion: BrushingPhotoVerifier.VERSION,
        verify: (telemetry) => BrushingPhotoVerifier.verify(telemetry)
      };
    }

    if (slug.includes('pushup') || slug.includes('push-up') || slug.includes('push_up')) {
      return {
        verifierName: 'PushupVideoVerifier',
        verifierVersion: PushupVideoVerifier.VERSION,
        verify: (telemetry) => PushupVideoVerifier.verify(telemetry)
      };
    }

    // Default / Generic
    return {
      verifierName: 'OutdoorPhotoVerifier',
      verifierVersion: OutdoorPhotoVerifier.VERSION,
      verify: (telemetry) => OutdoorPhotoVerifier.verify(telemetry)
    };
  }
}
