// Unit Test: MoveNet Lightning Model Cache & URI Resolution
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import * as fs from 'fs';
import * as path from 'path';
import {
  resolveMoveNetModelConfig,
  MoveNetLightningEngine
} from '../src/modules/verification/engine/movenet-lightning.engine';

describe('MoveNet Model Cache & Path Resolution (Track E)', () => {
  const tempTestModelDir = path.resolve(__dirname, 'temp_movenet_cache_test');
  const originalEnvDir = process.env.MOVENET_MODEL_DIR;
  const originalEnvUrl = process.env.MOVENET_MODEL_URL;

  beforeEach(() => {
    delete process.env.MOVENET_MODEL_DIR;
    delete process.env.MOVENET_MODEL_URL;
    MoveNetLightningEngine.resetForTesting();
  });

  afterEach(() => {
    if (originalEnvDir) process.env.MOVENET_MODEL_DIR = originalEnvDir;
    else delete process.env.MOVENET_MODEL_DIR;

    if (originalEnvUrl) process.env.MOVENET_MODEL_URL = originalEnvUrl;
    else delete process.env.MOVENET_MODEL_URL;

    if (fs.existsSync(tempTestModelDir)) {
      fs.rmSync(tempTestModelDir, { recursive: true, force: true });
    }
    MoveNetLightningEngine.resetForTesting();
  });

  it('1. Defaults to live TF Hub CDN when no local cache directory exists', () => {
    const resolution = resolveMoveNetModelConfig();
    expect(resolution.isLocalCache).toBe(false);
    expect(resolution.modelUrl).toBeUndefined();
  });

  it('2. Resolves explicit MOVENET_MODEL_URL when set', () => {
    process.env.MOVENET_MODEL_URL = 'https://custom-cdn.habitat.app/models/movenet/model.json';
    const resolution = resolveMoveNetModelConfig();
    expect(resolution.modelUrl).toBe('https://custom-cdn.habitat.app/models/movenet/model.json');
    expect(resolution.isLocalCache).toBe(false);
  });

  it('3. Resolves local model.json from MOVENET_MODEL_DIR when directory and file exist', () => {
    fs.mkdirSync(tempTestModelDir, { recursive: true });
    const dummyModelJson = path.join(tempTestModelDir, 'model.json');
    fs.writeFileSync(dummyModelJson, JSON.stringify({ format: 'layers-model', generatedBy: 'keras' }));

    process.env.MOVENET_MODEL_DIR = tempTestModelDir;

    const resolution = resolveMoveNetModelConfig();
    expect(resolution.isLocalCache).toBe(true);
    expect(resolution.modelUrl).toBeDefined();
    expect(resolution.modelUrl).toContain('file:');
    expect(resolution.resolvedPath).toBe(dummyModelJson);
  });
});
