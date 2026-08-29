# GitHub Integration & CI/CD Pipelines

## Remote Repository
- **URL:** `https://github.com/SahilKhutey/Habitat.git`
- **Main Branch:** `main`
- **Release Tags:** `v1.0.0`, `v1.0.0-rc.1`

## CI/CD Workflows (`.github/workflows/`)
1. `backend.yml` - TypeScript build, linting, and 42 Vitest test suites.
2. `android.yml` - Android Gradle build, unit testing, debug APK, and release AAB artifact packaging.
3. `ios.yml` - macOS runner, Xcode build verification, and test execution.
4. `web.yml` - Web dashboard build and packaging.

## Zero Secrets Policy
- Signing keys (`.keystore`, `.jks`, `.p12`, `.mobileprovision`), API secrets, and JWT tokens must NEVER be committed to Git.
- Sourced exclusively from GitHub Actions Encrypted Secrets (`ANDROID_KEYSTORE_BASE64`, `APPLE_CERT_P12_BASE64`, `JWT_SECRET`).
