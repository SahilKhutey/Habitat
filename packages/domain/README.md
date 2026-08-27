# Domain Package (`packages/domain`)

Pure Dart domain engine and business models for the Habitat Discipline Platform.

## Core Responsibilities
- Canonical Domain Models (`User`, `Task`, `Alarm`, `Mission`, `Attempt`, `Proof`, `XpTransaction`, `Streak`).
- `MissionStateMachine` governing the authoritative lifecycle:
  `SCHEDULED -> TRIGGERED -> ACTIVE -> PROOF_SUBMITTED -> VERIFYING -> COMPLETED / RETRYING (+5m)`.
- `MetricsEngine` computing waking resistance ($\Delta t_R = t_{\text{completed}} - t_{\text{scheduled}}$) and speed multipliers.
- Zero UI or Flutter framework dependencies.
