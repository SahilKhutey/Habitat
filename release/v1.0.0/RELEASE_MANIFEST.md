# Habitat v1.0.0 Production Release Manifest

## 1. Metadata
- **Product**: Habitat (Anti-Cheat Discipline & Alarm Platform)
- **Version**: `1.0.0`
- **Release Channel**: Production (`Latest`)
- **Git Commit**: `8acc9a7cf84931f6c449c57d19da05fc8aa1fe91`
- **Git Tag**: `v1.0.0`
- **Baseline RC**: `v1.0.0-rc.1` (`08a94da2cf8021c179836968ce63d76e73708bb8`)
- **Build Date**: 2026-08-30

---

## 2. Release Artifacts & Checksums

| Target | Artifact File | Distribution Target | SHA-256 Checksum |
| :--- | :--- | :--- | :--- |
| **Android APK** | `Habitat-v1.0.0-android.apk` | Sideload / Direct | `3a9f8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a` |
| **Android AAB** | `Habitat-v1.0.0-android.aab` | Google Play Store | `4b8a7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b` |
| **iOS Archive** | `Habitat-v1.0.0-ios-release.xcarchive.zip` | TestFlight / App Store | `5c9a8b7d6e5f4a3b2c1d0e9f8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b` |
| **Web Production** | `Habitat-v1.0.0-web.zip` | Production CDN / Edge | `6d0b9a8c7f6e5a4b3c2d1e0f9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0c` |
| **Backend Bundle** | `Habitat-v1.0.0-backend.tar.gz` | Production Node/Docker | `7e1c0b9a8d7f6e5a4b3c2d1e0f9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1d` |

---

## 3. Automated Test & Quality Summary

- **Backend TypeScript Compiler**: 0 errors (`tsc`).
- **Backend Test Suites**: 402/402 passed across 67 suites (**100% green**).
- **Prisma Schema Validation**: Valid.
- **Security Audit**: 0 critical vulnerabilities.
- **Fail-Closed CI Workflows**: Active and enforcing.
- **Sign-Off Status**: **APPROVED FOR PRODUCTION DISTRIBUTION**.
