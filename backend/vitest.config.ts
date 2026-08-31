import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Default timeout for most unit/integration tests
    testTimeout: 15000,

    // MoveNet model download + WASM warmup can take 30-60s on first run.
    // Per-suite overrides are applied via { timeout } in individual it() calls.
    // This global default covers the common case without slowing fast tests.
    hookTimeout: 30000,
  },
});
