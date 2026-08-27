# Health & Wellness REST API Reference

| Method | Path | Description |
| :--- | :--- | :--- |
| `GET` | `/api/v1/health/overview` | Returns consolidated movement, hydration, sleep, and wellness goals |
| `GET` | `/api/v1/health/exercise` | List exercise sessions with weekly summary stats |
| `POST` | `/api/v1/health/exercise` | Log an exercise session |
| `GET` | `/api/v1/health/hydration` | Query daily hydration total and target progress |
| `POST` | `/api/v1/health/hydration` | Log hydration entry in milliliters ($\text{ml}$) |
| `GET` | `/api/v1/health/sleep` | Query sleep sessions and 7-day average duration |
| `POST` | `/api/v1/health/sleep` | Log a sleep session |
| `GET` | `/api/v1/health/goals` | List active personal wellness goals |
| `POST` | `/api/v1/health/goals` | Create a new wellness goal |
| `PATCH`| `/api/v1/health/goals/:id` | Update target or status of a goal |
| `GET` | `/api/v1/health/correlations` | Discipline + Wellness correlation analysis ($\ge 14$ days threshold) |
| `POST` | `/api/v1/health/sync` | Batch synchronization endpoint for Apple Health / Health Connect |
| `POST` | `/api/v1/health/providers/connect` | Connect a health data provider |
| `POST` | `/api/v1/health/providers/disconnect` | Disconnect a health provider |
| `DELETE`| `/api/v1/health/data/:category` | Granular deletion of `exercise`, `hydration`, or `sleep` data |
