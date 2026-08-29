# Habitat Discipline Platform — Build Guide

## 1. Prerequisites

- **Node.js**: `v20.x` or higher
- **npm**: `v10.x` or higher
- **Flutter SDK**: `v3.22.x` (channel stable)
- **Java Development Kit (JDK)**: OpenJDK 17
- **Android SDK & Build Tools**: API 34+
- **Xcode** (for macOS / iOS): 15.0+

---

## 2. Backend Build & Verification

```bash
# 1. Install dependencies
cd backend
npm install

# 2. Compile TypeScript
npm run build

# 3. Execute all 39 test suites (262 tests)
npm test
```

---

## 3. Mobile Build (Android & iOS)

### Android Build (.apk & .aab)

```bash
cd apps/mobile
flutter pub get

# Generate Release APK
flutter build apk --release --no-tree-shake-icons

# Generate Google Play App Bundle (.aab)
flutter build appbundle --release --no-tree-shake-icons
```

Output paths:
- **APK**: `apps/mobile/build/app/outputs/flutter-apk/app-release.apk`
- **AAB**: `apps/mobile/build/app/outputs/bundle/release/app-release.aab`

---

### iOS Build

```bash
cd apps/mobile
flutter pub get
flutter build ios --release --no-codesign --no-tree-shake-icons
```

---

## 4. Automated Release Verification

Run the automated release verification script from repo root:
```powershell
pwsh ./scripts/verify-release.ps1
```
or on Linux/macOS:
```bash
./scripts/verify-release.sh
```
