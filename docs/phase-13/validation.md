# Phase 13 Input Validation & Safeguards

## 1. Input Sanitization Safeguards

* **Duration Constraints**: Rejects negative duration values (`durationSec < 0`).
* **Quantity Constraints**: Rejects negative quantities (`quantity < 0`).
* **Hydration Limits**: Requires positive amounts (`amountMl > 0`).
* **Sleep Window Integrity**: Requires strictly `endedAt > startedAt`.
* **Wellness Goal Targets**: Requires positive numeric targets (`target > 0` and not `NaN`).
* **Correlation Safeguard**: Enforces $\ge 14$ observation days before claiming behavioral association.
