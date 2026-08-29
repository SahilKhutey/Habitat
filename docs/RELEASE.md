# Habitat Discipline Platform — Release Guide & Pipeline

## 1. Versioning Standard

Habitat follows strict [Semantic Versioning 2.0.0](https://semver.org/):
$$\text{MAJOR}.\text{MINOR}.\text{PATCH}$$
- Current Release: **`v1.0.0`** (Defined authoritatively in `/VERSION`)

---

## 2. Release Integrity Checklist

1. [x] **Zero Secrets in Repository**: No `.pem`, `.keystore`, `.jks`, or private keys committed.
2. [x] **Backend Test Suite 100% Green**: 39 test suites (262 tests passing).
3. [x] **Idempotent Rewards**: Double mission completions cannot duplicate XP or progression.
4. [x] **Granular Privacy & GDPR**: Right-to-be-forgotten deletion endpoints for all health and telemetry data.
5. [x] **CI/CD Workflows**: Configured in `.github/workflows/` for Android, iOS, Backend, and Web.
6. [x] **Deterministic AI Policy**: AI advises via `PENDING_APPROVAL`; never silently modifies alarms or verification rules.
