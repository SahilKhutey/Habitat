# Schedule Conflict Detection & Dependency Engine

## 1. Conflict Detection & Severity Levels

The `ConflictEngine` scans scheduled task time windows for overlaps:

$$\text{Overlap} = \min(\text{EndTime}_A, \text{EndTime}_B) - \max(\text{StartTime}_A, \text{StartTime}_B)$$

| Severity | Threshold | Recommended User Action |
| :--- | :--- | :--- |
| **`LOW`** | Overlap $\le 5$ minutes | Minor time shift or keep both |
| **`MEDIUM`** | $5 < \text{Overlap} \le 15$ minutes | Adjust schedule window |
| **`HIGH`** | Overlap $> 15$ minutes OR mandatory tasks collide | Move one task or cancel conflict |

---

## 2. Task Dependency Types

* **`HARD` Dependency**: Dependent task cannot start until prerequisite task is verified and completed.
* **`SOFT` Dependency**: Dependent task remains accessible, but displays a contextual prompt: *"This is normally completed after your morning task."*

---

## 3. Circular Dependency Cycle Protection

The `DependencyEngine` runs a topological depth-first search (DFS) recursion over routine task graphs. If a cycle is detected ($A \to B \to C \to A$), the engine rejects the routine edit with `DEPENDENCY_CYCLE`, preventing impossible deadlock states.
