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
    case 'tfjs':
    case 'movenet':
      return new TfjsVisionProvider();

    case 'mock':
      return new MockVisionProvider();

    default:
      throw new Error(
        `Unsupported VISION_PROVIDER: "${providerType}". Expected "mock" or "tfjs".`
      );
  }
}
