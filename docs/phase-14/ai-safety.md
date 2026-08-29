# AI Safety Boundaries, Allowlist & Prompt Injection Defense

## 1. Action Allowlist Guard

Only explicitly authorized action types can be proposed by the AI:

### Allowed Actions:
* `PROPOSE_TASK`
* `PROPOSE_SCHEDULE_CHANGE`
* `PROPOSE_GOAL_CHANGE`
* `PROPOSE_RECOVERY`
* `PROPOSE_ROUTINE_CHANGE`
* `SHOW_INSIGHT`
* `SHOW_PLAN`

### Strictly Forbidden:
* `DELETE_USER_DATA`
* `DELETE_ALL_TASKS`
* `CHANGE_ACCOUNT_SECURITY`
* `CHANGE_HEALTH_PERMISSION`
* `CHANGE_VERIFICATION_POLICY`
* `EXECUTE_EXTERNAL_ACTION`
* `CHANGE_CORE_SYSTEM_SETTINGS`

---

## 2. Prompt Injection Defense Architecture

$$\boxed{\textbf{User Message} \longrightarrow \textbf{Sanitizer} \longrightarrow \textbf{Structured AI Response} \longrightarrow \textbf{Safety Filter} \longrightarrow \textbf{User Approval} \longrightarrow \textbf{Execution}}$$
User messages are treated as untrusted text. No natural language instruction can bypass the server-side Action Allowlist or directly execute destructive operations.
