# REST API Specification (`docs/api`)

All endpoints are versioned under `/api/v1/`.

| Endpoint | Method | Purpose |
| :--- | :---: | :--- |
| `/api/v1/health` | `GET` | Health status and database check |
| `/api/v1/auth/register` | `POST` | User registration & initial XP deposit |
| `/api/v1/auth/login` | `POST` | Authenticate and issue JWT |
| `/api/v1/tasks` | `GET/POST` | Task catalog & custom task wizard |
| `/api/v1/alarms` | `GET/POST` | Exact recurrence scheduling |
| `/api/v1/missions` | `GET/POST` | Authoritative mission state machine |
| `/api/v1/proofs` | `POST/GET` | Object storage upload URLs & anti-cheat verification |
| `/api/v1/gamification` | `GET` | Financial XP ledger & streak vault |
| `/api/v1/sync/batch` | `POST` | Offline-first batch reconciliation |
