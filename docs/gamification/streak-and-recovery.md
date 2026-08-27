# Timezone-Aware Streaks & Grace Vault Recovery Mechanics

## 1. Timezone-Aware Day Boundaries
A user's discipline streak is evaluated in the context of their local timezone (e.g. `Asia/Kolkata`, `America/New_York`, `UTC`) rather than a naive UTC day boundary:

```typescript
const localDateStr = new Intl.DateTimeFormat('en-CA', {
  timeZone: userTimezone || 'UTC',
  year: 'numeric',
  month: '2-digit',
  day: '2-digit'
}).format(now);
```

---

## 2. Daily Minimum Commitment
A day qualifies as successful when the user meets their daily minimum commitment (e.g. at least 1 verified morning mission completed on that calendar date).

---

## 3. Grace Vault Defense & Honest Streak Recovery

Life involves unavoidable disruptions (travel, sickness, genuine emergencies). Habitat introduces the **Grace Vault**:

* **Earning Rate**: User earns 1 Grace Token every 14 consecutive streak days (capped at a maximum of 3 tokens).
* **Recovery Mechanism**: If a user misses a day, they can consume 1 Grace Token to protect their current streak from resetting to zero.
* **Honesty Principle**: Consuming a Grace Token marks `recovery_used = 1` in streak metadata. It **never fabricates completed tasks in the database**. The audit log accurately records that the mission was missed, but the streak momentum is preserved.
