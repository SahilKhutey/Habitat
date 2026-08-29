# Habitat Phase 01: Navigation and Functional Architecture

**Status:** Canonical Phase 1 functional blueprint  
**Depends on:** [Foundational Framework](HABITAT_FOUNDATIONAL_FRAMEWORK.md)  
**Scope:** Android, iOS, tablet, and web  
**Out of scope:** Visual styling, final layouts, visual wireframes, and high-fidelity screen design.

---

## 1. Purpose and completion gate

This document turns the Phase 0 framework into a functional product contract:

```text
Navigation -> Screen hierarchy -> Screen responsibility -> User action
-> State transition -> Data requirement -> Service contract -> Platform behavior
```

At the end of Phase 1, every important Habitat action must have an owner, a route, a state model, a data source, feedback, recovery behavior, and a platform rule.

Phase 1 is complete when the acceptance criteria in section 15 are approved. It does not authorize visual screen implementation.

---

## 2. Product topology

```text
                    HABITAT
                       |
       +---------------+----------------+
       |               |                |
      Home       Tasks / Actions       Health
       |               |                |
       +---------------+----------------+
                       |
                +------+------+
                |             |
            Progress        Profile
```

| Foundation | Primary role | Primary user outcomes |
|---|---|---|
| Home | Read/act dashboard | Understand what matters now; start, resume, retry, or complete a relevant action |
| Tasks | Planning and execution system | Create and manage tasks, actions, schedules, alarms, and verification rules |
| Health | Daily health tracking | Log water, meals, and naps; understand today’s health context |
| Progress | Derived evidence and reflection | Understand completion, streaks, achievements, and trends from real events |
| Profile | User configuration | Manage identity, goals, preferences, permissions, privacy, and settings |

Home is not a configuration center. Profile does not own operational task execution. Progress consumes derived data; it does not calculate or mutate it.

---

## 3. Navigation map

### 3.1 Canonical routes

Route identifiers are conceptual; the implementation must use typed route definitions and map them to web URLs/deep links.

```text
/
|- /home
|- /tasks
|  |- /tasks/create
|  |- /tasks/:taskId
|  |- /tasks/:taskId/edit
|  |- /tasks/:taskId/action
|  |- /tasks/:taskId/alarm
|  `- /missions/:executionId
|     |- /missions/:executionId/proof
|     |- /missions/:executionId/verifying
|     `- /missions/:executionId/result
|- /health
|  |- /health/water
|  |- /health/meals
|  `- /health/naps
|- /progress
|  |- /progress/daily
|  |- /progress/streak
|  |- /progress/achievements
|  `- /progress/history
`- /profile
   |- /profile/goals
   |- /profile/preferences
   |- /profile/permissions
   |- /profile/notifications
   |- /profile/privacy
   `- /profile/settings
```

### 3.2 Navigation rules

- The root primary destinations are **Home, Tasks, Health, Progress, Profile**.
- Detail routes retain their parent foundation in their route hierarchy.
- Mission routes are protected operational states. They are entered through a scheduled trigger, Home, or Tasks and must preserve the execution identifier.
- Web routes are URL-addressable; mobile routes support equivalent deep links.
- Query parameters may represent presentation filters, not the authoritative domain state.
- Filters, tabs, sheets, and dialogs must never be the only route to a meaningful entity detail.

### 3.3 Platform navigation adaptation

| Context | Primary navigation | Details and modal work |
|---|---|---|
| Phone | Five-item bottom navigation | Push route; focused choices in a sheet |
| Tablet | Adaptive bottom navigation or navigation rail | List/detail split where it improves task completion |
| Desktop web | Persistent sidebar | Nested URL routes; list/detail panels; keyboard navigation |

---

## 4. Domain model and ownership

### 4.1 Foundational entities

```text
User
|- Tasks
|  |- Action definitions
|  |- Schedules
|  |- Alarms
|  `- Task executions -> Verification
|- Health
|  |- Water entries
|  |- Meal entries
|  `- Nap entries
|- Progress
|  |- Daily summaries
|  |- Streak
|  `- Achievements
`- Profile
   |- Goals
   `- Preferences
```

| Entity | Authority | Notes |
|---|---|---|
| User / Profile / Preference / Goal | Profile service + repositories | User-controlled configuration |
| Task / Action / Schedule / Alarm | Tasks domain | Task definition is separate from a particular execution |
| TaskExecution / Verification | Mission and verification domains | Time-bound operational record; source of completion evidence |
| WaterEntry / MealEntry / NapEntry | Health domain | Timestamped health records; edits require audit/recalculation rules |
| DailySummary / Streak / Achievement | Progress domain | Derived from events; screens consume results only |

### 4.2 Core task model

```text
Task
|- identity: id, name, description
|- schedule: date, time, recurrence, timezone
|- action: type, parameters, instructions
|- verification: type, requirements
|- alarm: enabled, trigger, escalation and retry policy
`- lifecycle: pending, active, completed, failed, missed, archived
```

`Task` describes an ongoing user commitment. `TaskExecution` describes an individual occurrence. The implementation must not overload one record to represent both concepts.

---

## 5. Screen inventory and contracts

All screens use the common state baseline: `initial`, `loading`, `ready`, `empty`, `active`, `completed`, `error`, and `offline`, where applicable.

### 5.1 Home

| Screen | Purpose | Entry / exit | Actions | Required services | Key states |
|---|---|---|---|---|---|
| Home dashboard | Answer “what matters now?” | Primary destination; exits to owned details | View, start, resume, retry, quick-log health | `HomeFeedService`, `TaskService`, `AlarmService`, `DailySummaryService` | No priorities, upcoming only, active mission, recovery needed, offline |
| Today overview | Show today’s task and health plan | Home section -> task/health detail | View schedule, open task, log health | `DailySummaryService`, `ScheduleService`, `HealthService` | Loading, empty day, partial day, completed day |
| Current action | Present the single most relevant task execution | Home or system alarm -> mission | Start, resume, capture proof, retry | `ActionService`, `VerificationService`, `AlarmService` | Available, active, verifying, retrying, unavailable |
| Quick actions | Fast, safe shortcuts | Home | Create task, log water, start nap, open alarm reliability | Target domain service | Enabled, permission-blocked, offline-queued |

**Home selection rule:** current time + active executions + due schedule + alarm state determine the highest-priority item. An active mission wins over an upcoming task; a platform-blocked alarm reports the reliability issue without pretending to be scheduled.

### 5.2 Tasks, actions, and alarms

| Screen | Purpose | Entry / exit | Actions | Required services | Key states |
|---|---|---|---|---|---|
| Task list | Browse all task commitments | Tasks root -> detail/create | Filter, search, create, archive, open | `TaskService` | Loading, empty, active, scheduled, completed, missed, archived, offline |
| Task detail | Explain one task and its next occurrence | Task list/Home -> edit/action/alarm | Edit, pause/resume, archive, start, view history | `TaskService`, `ScheduleService`, `AlarmService` | Ready, paused, no upcoming occurrence, error |
| Create task wizard | Create a coherent task definition | Tasks -> review -> task detail | Save draft, next/back, cancel, create | `TaskService`, `ScheduleService`, `ActionService`, `VerificationService`, `AlarmService` | Initial, editing, validation error, saving, success, offline draft |
| Edit task | Change future task definition safely | Task detail -> detail | Save, discard, pause, archive | Same as create | Editing, conflict warning, saving, error |
| Action detail | Explain physical or health action requirements | Task detail/mission -> proof or back | Start, review instructions | `ActionService`, `VerificationService` | Available, unavailable, requires permission |
| Alarm list | Manage alarms by status | Tasks -> create/edit/alarm detail | Enable, disable, test reliability, open schedule | `AlarmService`, `NativeAlarmService`, `NotificationService` | Active, upcoming, completed, missed, permission-blocked |
| Alarm configuration | Configure trigger and retry policy | Create/edit -> review | Set time, repeat, timezone, escalation, retry | `AlarmService`, `ScheduleService` | Editing, schedule conflict, platform limitation, saving |
| Active mission | Execute a triggered task | System trigger/Home -> proof/result | Begin action, capture proof, recover | `ActionService`, `AlarmService`, `VerificationService` | Active, interrupted, retrying, offline |
| Proof capture | Acquire evidence | Active mission -> preview/verification | Capture, retake, submit | `VerificationService`, `PermissionService`, `MediaCaptureService` | Camera unavailable, permission denied, capture ready, processing |
| Verification result | Explain result and next step | Verification -> Home/retry | Complete, retry, view non-sensitive explanation | `VerificationService`, `CompletionService` | Accepted, review, rejected, upload-pending, error |

#### Task creation contract

```text
Tasks -> Create -> Basic information -> Schedule -> Action -> Verification
-> Alarm -> Retry rules -> Review -> Create -> Task detail
```

Each step validates only the data it owns. The final review validates cross-field conflicts: recurrence, timezone, verification compatibility, schedule conflict, alarm permission, and retry policy. Cancellation preserves a recoverable draft when the user has entered meaningful data.

#### Execution state machine

```text
scheduled -> triggered -> active -> action presented -> verification
                                              |             |- accepted -> completed
                                              |             `- rejected/review -> retry or recovery
                                              `- interrupted -> resumable or missed
```

The UI reflects service-owned execution state; it must not locally infer completion or advance streaks.

### 5.3 Health

| Screen | Purpose | Entry / exit | Actions | Required services | Key states |
|---|---|---|---|---|---|
| Health overview | Summarize today’s water, meals, naps and goals | Health root -> tracker detail | Log health item, view history | `HealthService`, `DailySummaryService` | No entries, partial data, on-target, offline |
| Water tracker | Track hydration | Health/Home -> history | Add/edit/delete intake | `WaterService`, `HealthRepository` | Loading, empty, saving, daily target met, error, offline queued |
| Meal tracker | Track meal events through one model | Health -> history | Add/edit/delete meal, optional note | `MealService`, `HealthRepository` | Empty, partial day, saving, error |
| Nap tracker | Time and record rest periods | Health/Home -> history | Start, stop, edit, delete nap | `NapService`, `HealthRepository` | Idle, running, saving, interrupted, error |
| Health history | Inspect prior entries | Tracker -> overview | Filter, edit allowed records, delete | `HealthService` | Loading, empty, paginated, error, offline |

Health contracts:

- Water log: amount -> validate -> save locally -> recompute daily total -> notify Home, Health, and derived Progress views.
- Meals share `MealType`: `breakfast`, `lunch`, `snack`, or `dinner`; they are one service and one data model, not separate systems.
- Nap flow: start -> running -> stop -> duration calculation -> persist -> daily-summary refresh. A running nap survives app restart through persisted state.
- Health is optional to the core alarm loop; a health failure cannot block an active mission.

### 5.4 Progress

| Screen | Purpose | Entry / exit | Actions | Required services | Key states |
|---|---|---|---|---|---|
| Progress overview | Explain current consistency and progress | Progress root -> detail | Change time range, inspect source details | `ProgressService`, `DailySummaryService` | Insufficient history, ready, recalculating, offline cache |
| Daily progress | Show today’s derived completion | Progress -> task/health details | Inspect contributors | `DailySummaryService` | No scheduled tasks, in-progress, completed, error |
| Streak | Show current/best streak and recovery context | Progress -> history | View qualification explanation and recovery availability | `StreakService` | No qualifying days, active, protected/recovery used, broken |
| Achievements | Show earned and available milestones | Progress -> achievement detail | View criteria and history | `AchievementService` | Empty, earned, newly unlocked, error |
| History | Explore past summaries | Progress -> source route | Filter date range, inspect day | `ProgressService` | Loading, empty range, paginated, error |

Progress is event-derived:

```text
task/health events -> completion and qualification rules -> daily aggregation
-> progress calculation -> streak/achievement evaluation -> persisted derived output -> UI
```

The UI may request a recalculation but never directly increments a streak, awards XP, or unlocks an achievement.

### 5.5 Profile

| Screen | Purpose | Entry / exit | Actions | Required services | Key states |
|---|---|---|---|---|---|
| Profile overview | Provide account and personal setup entry points | Profile root -> detail | Edit information, goals, preferences | `ProfileService` | Loading, local profile, sync pending, error |
| Goals | Manage intent and planning goals | Profile -> overview | Create, edit, archive goal | `GoalService` / `ProfileService` | Empty, editing, saving, error |
| Preferences | Configure behavior and personalization | Profile -> overview | Change preferences, reset default | `PreferenceService` | Loading, saving, error |
| Permissions | Explain and request system capabilities | Profile or contextual block -> return | Request, open settings, retest | `PermissionService`, `NativeAlarmService`, `NotificationService` | Undetermined, granted, denied, restricted, reliability warning |
| Notifications | Configure notification preferences | Profile -> overview | Enable categories, open system settings | `NotificationService`, `PreferenceService` | Allowed, denied, system-limited, saving |
| Privacy and data | Manage consent, export, deletion | Profile -> confirmation/result | Export, disconnect provider, delete category | `PrivacyService`, `ExportService` | Ready, confirming, processing, success, error |
| Settings | Low-frequency application configuration | Profile -> overview | Change appearance/language/support settings | `PreferenceService` | Ready, saving, error |

Profile owns configuration, consent, and user-controlled data—not task execution or operational alarm state.

---

## 6. Critical user-flow definitions

### 6.1 First-use setup

```text
Launch -> Welcome -> goal and preferences -> explain permissions -> request only needed permissions
-> create first task -> configure schedule/alarm -> reliability check -> success -> Home
```

If a permission is denied, the user continues when possible and receives a clear limitation plus a way to enable it later. Do not request alarm/camera/notification permissions without a preceding rationale.

### 6.2 Alarm and verification loop

```text
alarm configuration -> schedule persistence -> platform scheduler -> trigger
-> notification/alarm UI -> active mission -> action -> proof capture -> verification
-> accepted: complete + progress/streak update
-> rejected/review: explain + retry/recovery
```

### 6.3 Health logging

```text
choose health action -> validate input -> persist locally -> refresh daily summary
-> show confirmation -> queue sync if required
```

### 6.4 Recovery

```text
miss / rejection / interruption -> clear explanation -> preserve context
-> retry now, schedule next attempt, edit future plan, or return safely
```

---

## 7. Service architecture and contracts

### 7.1 Layering rule

```text
Screen -> Controller / state notifier -> Service -> Repository / engine / platform adapter -> local DB or backend
```

Screens may render state and dispatch intent. They do not calculate streaks, directly mutate database records, schedule native alarms, or apply verification policy.

### 7.2 Service catalog

| Service | Responsibility | Dependencies |
|---|---|---|
| `TaskService` | Task lifecycle and task definition validation | `TaskRepository`, `ScheduleService`, `AlarmService` |
| `ActionService` | Action eligibility, instructions, execution start/resume | `TaskRepository`, `ExecutionRepository` |
| `ScheduleService` | Recurrence, timezone, next occurrence, conflicts | `ScheduleRepository`, scheduling engine |
| `AlarmService` | Alarm policy, persistence, lifecycle | `AlarmRepository`, `NativeAlarmService`, `NotificationService` |
| `VerificationService` | Proof lifecycle and verdict communication | `VerificationRepository`, media/verification adapters |
| `CompletionService` | Atomic accepted-completion orchestration | execution, progress, and event dependencies |
| `WaterService` / `MealService` / `NapService` | Create, update, and remove health records | `HealthRepository`, `DailySummaryService` |
| `HealthService` | Health overview and history composition | health repositories |
| `DailySummaryService` | Derive daily task/health summary | event source and summary repository |
| `ProgressService` | Time-range progress aggregates | summary repository |
| `StreakService` | Day qualification and current/best streak | completion events, streak repository |
| `AchievementService` | Evaluate and persist unlocked achievements | event stream, achievement repository |
| `ProfileService` / `GoalService` / `PreferenceService` | Profile configuration | corresponding repositories |
| `PermissionService` | Capability status and rationale boundary | platform permission adapter |
| `NotificationService` | Notification preference and platform scheduling boundary | platform notification adapter |

### 7.3 Repository interfaces

Repositories isolate storage and synchronization. They return domain models, never database rows or framework-specific types.

```text
TaskRepository:        list, get, create, update, archive
ScheduleRepository:    getForTask, save, nextOccurrences, conflicts
AlarmRepository:       list, get, save, updateStatus, history
ExecutionRepository:   get, create, updateState, listForTask
VerificationRepository: createProof, updateStatus, getVerdict
HealthRepository:      water, meals, naps CRUD + date-range queries
SummaryRepository:     getDaily, saveDaily, getRange
StreakRepository:      get, save, history
AchievementRepository: list, get, unlock
ProfileRepository:     get, save
PreferenceRepository:  get, save
```

All mutating repository operations provide an idempotency key or equivalent deduplication strategy when they can be retried after an interrupted operation.

---

## 8. Data and backend requirements

### 8.1 Local-first contract

- Local storage is authoritative for immediate alarm, execution, health logging, and user feedback.
- Repository interfaces allow a later remote implementation without UI rewrites.
- A sync queue reports `local`, `queued`, `syncing`, `synced`, or `sync_failed`—never a vague success state.
- Conflict policy is defined per entity before cloud sync is enabled.

### 8.2 Existing backend alignment

The Express backend already mounts domains for tasks, alarms, alarm schedules, missions, proofs, verification, gamification, sync, health, users, and authentication beneath `/api/v1`. These are the future remote adapters, not a reason for UI screens to call HTTP directly.

| Functional requirement | Remote domain | Local requirement |
|---|---|---|
| Tasks and schedules | `/tasks`, `/alarm-schedules` | Task/schedule repositories and recurrence cache |
| Alarms and missions | `/alarms`, `/missions` | Native scheduling, alarm state, execution journal |
| Proof and verification | `/proofs`, `/verification`, `/missions` | Capture metadata, pending-upload state, result cache |
| Progress | `/gamification`, analytics domains | Event journal, daily summary, streak cache |
| Health | `/health` | Health record repository and daily summary |
| Profile and identity | `/users`, `/auth` | Local profile and preference repository |

### 8.3 Backend service contracts to define before UI implementation

- Task create/update returns canonical task, schedule, validation outcomes, and next occurrence.
- Alarm configuration reports whether the policy is persisted and whether platform scheduling was actually successful.
- Mission start/resume returns execution state, instructions, proof requirements, retry policy, and expiration behavior.
- Verification returns `accepted`, `review`, or `rejected`, a user-safe reason code, next allowed action, and audit identifier.
- Completion is idempotent and atomically emits task completion, progress, streak, XP, and achievement evaluation events.
- Health writes return the persisted entry and recomputed daily health summary.
- Progress endpoints return derived values with source period and freshness/sync metadata.

---

## 9. Platform service and permission requirements

| Capability | Android | iOS | Web |
|---|---|---|---|
| Alarm scheduling | Exact-alarm capability, battery optimization guidance, foreground behavior | Local notifications; explain OS background/force-quit limits | Browser notification/timer limits; dashboard is not alarm authority |
| Notifications | Runtime permission and channels | Notification authorization and critical-alert constraints | Browser permission and service-worker limits |
| Proof capture | Camera/microphone permissions as required | Camera/microphone privacy permission | Browser media permission and capability fallback |
| Background work | Native lifecycle/foreground restrictions | Strict platform limits | Tab throttling and service-worker limits |
| Navigation | System back and app links | Safe areas, gestures, navigation conventions | Browser back/forward, URLs, focus and keyboard |

Permission contract:

1. Explain benefit and limitation in context.
2. Request only when the user takes the action requiring it, except essential alarm reliability onboarding.
3. Record `undetermined`, `granted`, `denied`, and `restricted` states separately.
4. Offer a settings path and retest action after denial.
5. Never silently claim a capability is available when platform diagnostics say otherwise.

---

## 10. Screen-to-service dependency map

| Foundation | Screen group | Required services |
|---|---|---|
| Home | Dashboard, today, current action, quick actions | `HomeFeedService`, `TaskService`, `AlarmService`, `DailySummaryService`, `HealthService` |
| Tasks | Lists, detail, create/edit | `TaskService`, `ScheduleService`, `ActionService`, `AlarmService` |
| Tasks | Active mission, proof, result | `ActionService`, `VerificationService`, `CompletionService`, `PermissionService` |
| Health | Overview, water, meals, naps, history | `HealthService`, `WaterService`, `MealService`, `NapService`, `DailySummaryService` |
| Progress | Overview, daily, streak, achievements, history | `ProgressService`, `DailySummaryService`, `StreakService`, `AchievementService` |
| Profile | Profile, goals, preferences, settings | `ProfileService`, `GoalService`, `PreferenceService` |
| Profile | Permissions, notifications, privacy | `PermissionService`, `NotificationService`, `PrivacyService`, `ExportService` |

---

## 11. State ownership and event contracts

| Event | Owner | Required downstream work |
|---|---|---|
| Task created/updated | `TaskService` | Recalculate schedule, reconfigure alarm, refresh Home/Tasks |
| Alarm scheduled/failed | `AlarmService` | Persist actual platform status; report reliability state |
| Alarm triggered | `AlarmService` / platform adapter | Create/resume execution; notify Home and mission UI |
| Proof submitted | `VerificationService` | Persist pending state; process or queue sync |
| Verification accepted | `CompletionService` | Complete execution atomically; update daily summary, streak, XP, achievement checks |
| Verification rejected/review | `VerificationService` | Preserve evidence status; expose recovery/retry state |
| Health record changed | Health service | Recalculate daily health and dependent summaries |
| Preference changed | Preference service | Apply setting; notify relevant adapters/components |

Event names and payloads must be versioned and shared across local and remote implementations before analytics or synchronization work begins.

---

## 12. Functional acceptance criteria by foundation

### Home

- [ ] Correctly prioritizes active mission over all non-critical dashboard content.
- [ ] Provides a single clear next action from local schedule/alarm/execution state.
- [ ] Shows truthful offline and reliability status.
- [ ] Does not become an alternate task editor or settings area.

### Tasks / Actions / Alarms

- [ ] User can create, review, edit, pause, archive, and inspect a task without screen-owned business logic.
- [ ] Task creation validates schedule, action, verification, and alarm compatibility.
- [ ] Alarm status distinguishes configured from actually scheduled on the platform.
- [ ] Rejection/interruption always has an explanation and recovery route.

### Health

- [ ] Water, meals, and naps use separate user experiences but coherent shared data contracts.
- [ ] Health updates are locally durable and update relevant daily summaries.
- [ ] Health failures cannot block core alarm/mission flows.

### Progress

- [ ] All displayed completion, streak, and achievement data is derived from events/services.
- [ ] Source period, freshness, and insufficient-data states are clear.
- [ ] The UI cannot directly modify streak or achievement state.

### Profile

- [ ] Permissions include rationale, settings recovery, and retest behavior.
- [ ] Profile does not own operational task or alarm data.
- [ ] Privacy/data actions have confirmation and auditable outcome states.

---

## 13. Phase 1 deliverables checklist

- [x] Navigation map
- [x] Information architecture
- [x] Complete foundation screen inventory
- [x] Subscreen inventory and relationships
- [x] Critical user-flow definitions
- [x] Interaction and state ownership model
- [x] Foundational domain model
- [x] Service and repository architecture
- [x] Backend/data requirements
- [x] Platform-service and permission requirements
- [x] Screen-to-service dependency map
- [ ] Typed route identifiers, parameter schemas, and deep-link convention approved
- [ ] Service interface signatures and event payload schemas approved
- [ ] Entity ownership and synchronization conflict policy approved
- [ ] Functional review of all critical flows completed with Android, iOS, web, backend, and UX owners

## 14. Current implementation alignment backlog

1. Replace the current four-tab mobile root with this five-foundation model after route approval.
2. Introduce typed `go_router` navigation and eliminate scattered unnamed route literals.
3. Extract screen-owned local database mutation and business rules into services and repositories.
4. Separate task-definition state from occurrence/execution state throughout the mobile client.
5. Implement missing first-class domain support for meal and nap records before making their screens authoritative.
6. Connect the Flutter web dashboard to typed services and URL-driven navigation.
7. Publish shared local/remote repository interfaces and idempotent mutation contracts.

## 15. Phase 1 completion gate

Phase 1 may advance to Phase 2 only when:

- [ ] Product, UX, engineering, and platform owners approve the route and screen contracts.
- [ ] Every critical action is traceable from UI intent to service, repository, data change, feedback, and recovery.
- [ ] All service boundaries have typed interfaces, error categories, and idempotency behavior.
- [ ] Android, iOS, and web limitations are documented for alarm, notification, proof capture, permissions, and navigation.
- [ ] All foundational entities have one clear authority and synchronization direction.
- [ ] The Phase 0 governance rules are incorporated into design review and implementation review templates.

With this gate satisfied, Phase 2 can define the visual design-system values and component variants against stable product behavior rather than redesigning behavior through screens.

