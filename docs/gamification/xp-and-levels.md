# Immutable XP Ledger & Quadratic Level Progression

## 1. Immutable XP Ledger

XP in Habitat is never directly overwritten. All balance changes are computed from an append-only transaction ledger in `xp_transactions`:

$$\text{Total XP} = \sum_{i=1}^{N} \text{amount}_i \quad (\text{where } \text{user\_id} = U)$$

### Ledger Schema & Idempotency Key
```sql
CREATE TABLE xp_transactions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  mission_id TEXT,
  amount INTEGER NOT NULL,
  reason TEXT NOT NULL,
  source_type TEXT DEFAULT 'MISSION_COMPLETION',
  source_id TEXT,
  idempotency_key TEXT UNIQUE,
  created_at TEXT NOT NULL
);
```

### Anti-Gaming & Double-Award Protection
* **Idempotency Key**: `MISSION_COMPLETION:{missionId}` ensures sending the exact same completion event twice awards XP once.
* **Repetitive Limit**: Repeating the identical task more than twice in 24 hours triggers reward diminishing returns (1st: 100%, 2nd: 50%, 3rd+: 0 XP).

---

## 2. Quadratic Level Progression Curve

Level thresholds scale quadratically to maintain long-term engagement:

$$\text{Level Threshold}(L) = 50 \cdot (L - 1) \cdot L$$

| Level | Base XP Required | XP to Next Level | Cumulative Milestone |
| :---: | :---: | :---: | :---: |
| **Level 1** | $0\text{ XP}$ | $100\text{ XP}$ | Novice of Will |
| **Level 2** | $100\text{ XP}$ | $200\text{ XP}$ | Apprentice of Morning |
| **Level 3** | $300\text{ XP}$ | $300\text{ XP}$ | Order Architect |
| **Level 4** | $600\text{ XP}$ | $400\text{ XP}$ | Sentinel of Habit |
| **Level 5** | $1,000\text{ XP}$ | $500\text{ XP}$ | Iron Sovereign |
| **Level 10** | $4,500\text{ XP}$ | $1,000\text{ XP}$ | Master of Autonomy |

When total XP crosses a threshold, the system emits a single `LEVEL_UP` event for tactical UI celebration.
