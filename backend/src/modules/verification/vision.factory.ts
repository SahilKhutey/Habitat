// Canonical Vision Provider Factory for Runtime Environment Selection
import { IVisionProvider } from './domain/vision-provider.interface';
import { TfjsVisionProvider } from './infrastructure/tfjs-vision.provider';
import { MockVisionProvider as IsolatedTestVisionProvider } from './infrastructure/mock-vision.provider';

export function createVisionProvider(overrideType?: string): IVisionProvider {
  const isProduction =
    process.env.NODE_ENV === 'production' || process.env.HABITAT_ENV === 'production';

  const rawProviderType = overrideType ?? process.env.VISION_PROVIDER;

  // In production, default strictly to 'tfjs' (MoveNet Lightning) and reject 'mock'
  const providerType = (
    rawProviderType ?? (isProduction ? 'tfjs' : 'mock')
  )
    .trim()
    .toLowerCase();

  if (isProduction && providerType === 'mock') {
    throw new Error(
      '[FATAL] Production startup rejected: MockVisionProvider cannot be loaded in production environment.'
    );
  }

  switch (providerType) {
    // All real-vision aliases resolve to TfjsVisionProvider, which is the only
    // complete implementation — it has detectPose AND generateVerificationEvidence,
    // delegating inference through MoveNetPoseAdapter -> MoveNetLightningEngine.
    case 'movenet':
    case 'tflite':
    case 'tfjs':
      return new TfjsVisionProvider();

    case 'mock':
      return new IsolatedTestVisionProvider();

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
