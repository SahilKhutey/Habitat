# Habitat Offline-First Architecture & Protocols

## Zero-Cloud Independence
Habitat is designed from first principles as an **offline-first local system**.
- **No Cloud Startup Delay:** Launches directly into local SQLite state without splash screen network blocking.
- **Local Media Storage:** Photos and videos are stored in application-sandboxed directories (`habitat/proofs/`).
- **Atomic Operations:** Task completion, XP append, and streak advancement execute within an atomic transaction.
- **Offline Diagnostics & Sharing:** Feedback queues locally and exports to JSON/ZIP via the native OS share sheet.
