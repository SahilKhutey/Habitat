// Vision Provider Factory: Controlled Provider Resolution based on VISION_PROVIDER environment
import { IVisionProvider } from '../domain/vision-provider.interface';
import { MoveNetVisionProvider } from './movenet-vision.provider';
import { MockVisionProvider } from './mock-vision.provider';

export class VisionProviderFactory {
  /**
   * Resolves the configured vision provider based on environment setting
   * Options:
   * - 'movenet' | 'tflite' -> Production MoveNetVisionProvider
   * - 'mock' -> MockVisionProvider for deterministic offline unit testing
   */
  public static getProvider(overrideType?: 'movenet' | 'mock'): IVisionProvider {
    const configuredType =
      overrideType ||
      (process.env.VISION_PROVIDER as 'movenet' | 'mock') ||
      'mock';

    switch (configuredType.toLowerCase()) {
      case 'movenet':
      case 'tflite':
        return new MoveNetVisionProvider();
      case 'mock':
      default:
        return new MockVisionProvider();
    }
  }
}
