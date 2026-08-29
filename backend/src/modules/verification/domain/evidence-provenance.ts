// Vision Model & Evidence Provenance Metadata
export interface ModelProvenance {
  modelName: 'MoveNet-Lightning' | 'MoveNet-Thunder' | 'MediaPipe-Pose' | 'CoreML-Pose' | string;
  modelVersion: string;
  provider: 'TFLite' | 'CoreML' | 'WebGPU' | 'WASM' | string;
  runtimePlatform: 'android' | 'ios' | 'web';
  inputResolution: [number, number]; // e.g. [192, 192] or [256, 256]
  inferenceLatencyMs?: number;
  schemaVersion: '2.0.0' | string;
  timestamp: string;
}

export function createDefaultProvenance(overrides?: Partial<ModelProvenance>): ModelProvenance {
  return {
    modelName: 'MoveNet-Lightning',
    modelVersion: '1.0.0',
    provider: 'TFLite',
    runtimePlatform: 'android',
    inputResolution: [192, 192],
    inferenceLatencyMs: 24,
    schemaVersion: '2.0.0',
    timestamp: new Date().toISOString(),
    ...overrides
  };
}
