# App Store & Play Store Code Signing Protocol

## Security Directive: Zero Secrets in Source Control

Private keys, certificates, keystores, and credentials MUST NEVER be committed to Git. All signing configurations utilize CI/CD environment secrets.

---

## 1. Android Release Signing

In CI/CD environments (GitHub Secrets), provide:
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

---

## 2. iOS Code Signing

In CI/CD environments (macOS runner), provide:
- `APPLE_CERTIFICATE_BASE64`
- `APPLE_CERTIFICATE_PASSWORD`
- `PROVISIONING_PROFILE_BASE64`
- `APP_STORE_CONNECT_API_KEY`
