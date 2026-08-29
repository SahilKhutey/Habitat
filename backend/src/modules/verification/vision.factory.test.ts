// Unit Tests: Vision Provider Factory & Runtime Configuration
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { createVisionProvider } from './vision.factory';
import { MockVisionProvider } from './infrastructure/mock-vision.provider';
import { TfjsVisionProvider } from './infrastructure/tfjs-vision.provider';

describe('Vision Provider Factory (A3)', () => {
  const originalEnv = process.env.VISION_PROVIDER;

  beforeEach(() => {
    delete process.env.VISION_PROVIDER;
  });

  afterEach(() => {
    process.env.VISION_PROVIDER = originalEnv;
  });

  it('A3.1: returns MockVisionProvider when VISION_PROVIDER=mock', () => {
    process.env.VISION_PROVIDER = 'mock';
    const provider = createVisionProvider();
    expect(provider instanceof MockVisionProvider).toBe(true);
    expect(provider.providerId).toBe('mock-movenet-provider');
  });

  it('A3.2: returns TfjsVisionProvider when VISION_PROVIDER=tfjs', () => {
    process.env.VISION_PROVIDER = 'tfjs';
    const provider = createVisionProvider();
    expect(provider instanceof TfjsVisionProvider).toBe(true);
    expect(provider.modelName).toBe('MoveNet-Lightning');
  });

  it('A3.3: returns TfjsVisionProvider when VISION_PROVIDER=movenet', () => {
    process.env.VISION_PROVIDER = 'movenet';
    const provider = createVisionProvider();
    expect(provider instanceof TfjsVisionProvider).toBe(true);
    expect(provider.modelName).toBe('MoveNet-Lightning');
  });

  it('A3.4: defaults to MockVisionProvider when VISION_PROVIDER is unset (fast CI / unit tests)', () => {
    delete process.env.VISION_PROVIDER;
    const provider = createVisionProvider();
    expect(provider instanceof MockVisionProvider).toBe(true);
    expect(provider.providerId).toBe('mock-movenet-provider');
  });

  it('A3.5: throws explicit error on invalid or typo provider configuration (fails safe)', () => {
    process.env.VISION_PROVIDER = 'tfj';
    expect(() => createVisionProvider()).toThrowError(
      'Unsupported VISION_PROVIDER: "tfj". Expected "mock" or "tfjs".'
    );

    process.env.VISION_PROVIDER = 'unknown_cloud_provider';
    expect(() => createVisionProvider()).toThrowError(
      'Unsupported VISION_PROVIDER: "unknown_cloud_provider". Expected "mock" or "tfjs".'
    );
  });

  it('A3.6: allows explicit override parameter', () => {
    const mockOverride = createVisionProvider('mock');
    expect(mockOverride instanceof MockVisionProvider).toBe(true);

    const tfjsOverride = createVisionProvider('tfjs');
    expect(tfjsOverride instanceof TfjsVisionProvider).toBe(true);

    expect(() => createVisionProvider('bad_val')).toThrowError(
      'Unsupported VISION_PROVIDER: "bad_val". Expected "mock" or "tfjs".'
    );
  });
});
