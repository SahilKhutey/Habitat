// Canonical Vision Provider Factory for Runtime Environment Selection
import { IVisionProvider } from './domain/vision-provider.interface';
import { MockVisionProvider } from './infrastructure/mock-vision.provider';
import { TfjsVisionProvider } from './infrastructure/tfjs-vision.provider';

export function createVisionProvider(overrideType?: string): IVisionProvider {
  const providerType = (
    overrideType ??
    process.env.VISION_PROVIDER ??
    'mock'
  )
    .trim()
    .toLowerCase();

  switch (providerType) {
    // All real-vision aliases resolve to TfjsVisionProvider, which is the only
    // complete implementation — it has detectPose AND generateVerificationEvidence,
    // delegating inference through MoveNetPoseAdapter -> MoveNetLightningEngine.
    case 'movenet':
    case 'tflite':
    case 'tfjs':
      return new TfjsVisionProvider();

    case 'mock':
      return new MockVisionProvider();

    default:
      throw new Error(
        `Unsupported VISION_PROVIDER: "${providerType}". Valid options: "mock", "tfjs", "movenet", "tflite".`
      );
  }
}

export class VisionProviderFactory {
  private static cachedProvider: IVisionProvider | null = null;

  public static getProvider(overrideType?: string): IVisionProvider {
    if (overrideType) {
      return createVisionProvider(overrideType);
    }
    return createVisionProvider();
  }

  public static resetForTesting(): void {
    this.cachedProvider = null;
  }
}
