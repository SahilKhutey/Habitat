# Habitat API v1 Reference Specification

Authoritative REST API routes mounted under `/api/v1/`.

## 1. Authentication (`/api/v1/auth`)
* `POST /register` — Creates user account with password hash, generates auth token.
* `POST /login` — Validates credentials and returns JWT bearer token.
* `POST /refresh` — Refreshes expired session token.
* `POST /logout` — Invalidates session.

## 2. Tasks & Templates (`/api/v1/tasks`)
* `GET /templates` — Returns active canonical starter task templates.
* `GET /` — Returns customized tasks for current user.
* `POST /` — Creates a custom user task.
* `PUT /:id` — Updates user task parameters.
* `POST /:id/pause` — Transitions task to `PAUSED`.
* `POST /:id/resume` — Transitions task to `ACTIVE`.
* `POST /:id/archive` — Soft-archives user task.

## 3. Alarms & Scheduling (`/api/v1/alarms`, `/api/v1/alarm-schedules`)
* `GET /` — Lists user alarms with next fire calculations.
* `POST /` — Creates recurring alarm schedule with timezone and repeat days.
* `PUT /:id/toggle` — Toggles alarm enabled state.
* `DELETE /:id` — Deletes alarm schedule.

## 4. Missions (`/api/v1/missions`)
* `GET /current` — Returns the current active or in-progress mission.
* `POST /` — Idempotently creates a mission from an alarm trigger.
* `POST /:id/start` — Transitions mission to `IN_PROGRESS` and starts attempt #N.
* `POST /:id/submit` — Transitions mission to `VERIFYING`.
* `POST /:id/complete` — Atomically completes mission, stops future alarms, and emits `MISSION_COMPLETED`.
* `POST /:id/retry` — Rejects attempt, schedules +5 minute alarm retry (`nextRetryAt`).
* `POST /:id/cancel` — Cancels active mission.
* `GET /:id/events` — Chronological transition audit history.

## 5. Proofs & Verification (`/api/v1/proofs`)
* `POST /:id/assets` — Creates S3 upload session with signed URL.
* `POST /:id/submit` — Submits media for verification and evaluates acceptance criteria.
* `POST /:id/retry` — Resets proof state for recapture.
* `DELETE /:id` — Soft-deletes proof asset.

## 6. Gamification & Economics (`/api/v1/gamification`)
* `GET /overview` — Unified discipline telemetry, current level, streak, grace tokens, and score.
* `GET /ledger` — Itemized append-only audit trail of XP transactions.
* `GET /achievements` — Trophy showcase of unlocked and locked badges.

## 7. Offline Sync & Multi-Device Mesh (`/api/v1/sync`, `/api/v1/mesh`)
* `POST /sync/batch` — Bulk ingests offline completed missions with clock drift sanitization.
* `GET /sync/status` — Returns authoritative sync status and connected device counts.
* `POST /mesh/devices/register` — Registers companion phones, tablets, or web dashboards.
* `POST /mesh/broadcast/disarm` — Broadcasts remote alarm disarm across mesh network.
