# Habitat iOS Build & Distribution Guide

## Cloud CI/CD Automation (Recommended)
Habitat provides an automated GitHub Actions workflow for building iOS archives on Apple silicon macOS runners:
- **Workflow:** [`.github/workflows/ios.yml`](file:///c:/Users/ASUS/Documents/Habitat/.github/workflows/ios.yml)
- **Runner:** `macos-14`
- **Output:** `.ipa` application package & Runner xcarchive

Trigger via GitHub CLI:
```bash
gh workflow run .github/workflows/ios.yml --ref main
```

---

## Local Compilation on macOS

```bash
cd apps/mobile
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release --no-codesign
```

For device distribution or TestFlight:
```bash
flutter build ipa --export-method development
```
