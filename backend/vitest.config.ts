import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Default timeout for most unit/integration tests
    testTimeout: 20000,
    hookTimeout: 30000,
    teardownTimeout: 30000,
    pool: 'forks',
  },
});

