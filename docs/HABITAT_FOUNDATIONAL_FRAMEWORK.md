# Habitat Foundational Framework

**Status:** Canonical Phase 0 specification  
**Scope:** Android, iOS, tablet, and web  
**Purpose:** Establish the product, UX, system, and governance rules that every Habitat interface must follow before visual screen design begins.

> This is a framework document, not a screen specification. It defines what the product must communicate and how its interface must behave. Individual screen designs may begin only after the applicable Phase 0, Phase 1, Phase 2, and Phase 3 acceptance criteria are met.

---

## 0. Product model and sequencing

Habitat moves a person from intention to a verified action and sustained progress:

```text
INTENTION -> ACTION -> COMPLETION -> FEEDBACK -> PROGRESS -> REFLECTION -> ADAPTATION
```

The user receives the information needed **now** before information about today, this week, or history. Configuration is progressively disclosed: simple first, advanced second, optional last.

```text
Phase 0  Foundational Framework
Phase 1  UX Foundation and Product Architecture
Phase 2  Visual Design System
Phase 3  Core User Flows and Interaction System
Phase 4  High-Fidelity Platform UI
Phase 5  Implementation, Responsiveness, and Accessibility
Phase 6  Validation, Polish, and Production Readiness
```

No Phase 4 screen is authoritative until its governing flow, component contracts, states, and platform behavior have been defined in Phases 0–3.

---

## 1. Product principles

1. **Action over friction.** The next useful action is clear, direct, and reachable without deciphering the product.
2. **Now before history.** Active alarms, due tasks, recovery needs, and immediate health actions take priority over analytics and configuration.
3. **Compassionate accountability.** A failed verification or missed task explains what happened, preserves user dignity, and gives a safe recovery path.
4. **One product, native behavior.** Brand, terminology, information architecture, data, and core intent stay consistent; platform conventions adapt where users expect them to.
5. **Local reliability is user trust.** Alarm and active-mission experiences remain understandable and functional when the network is unavailable.
6. **Feedback closes every loop.** A meaningful action always produces a timely system response and exposes the resulting state.
7. **Progress is evidence, not pressure.** Streaks and scores motivate without hiding recovery, uncertainty, or missing data.
8. **Accessibility is a product requirement.** A feature is incomplete until people using text scaling, assistive technology, keyboard input, or reduced motion can complete it.

---

## 2. UX architecture

### 2.1 Product foundations

| Foundation | Owns | Does not own |
|---|---|---|
| **Home** | Current priorities, today’s plan, immediate recovery, concise progress summary | Full task management, raw history, account configuration |
| **Tasks** | Tasks, actions, schedules, alarms, instructions, verification policy | Global health logging or profile preferences |
| **Health** | Water, meals, naps, health goals, daily health data | Alarm configuration and XP-ledger detail |
| **Progress** | Daily completion, streak, achievements, trends, history | Editing source tasks or profile details |
| **Profile** | Identity, goals, preferences, permissions, notifications, settings, data controls | Current mission execution |

### 2.2 Relationship model

```text
Profile -> preferences and goals -> Tasks -> actions and alarms -> completion
                                                     |              |
                                                     v              v
                                                   Home <- progress and streak

Health -> daily data -> Home and Progress
```

### 2.3 User types and jobs

| User type | Primary job | UX emphasis |
|---|---|---|
| New user | Establish the first reliable habit | Guided setup, clear explanations, minimal choices |
| Daily practitioner | Know what to do next and complete it | Speed, confidence, visible next action |
| Recovering user | Resume after a miss without losing context | Explanation, recovery plan, no dead ends |
| Insight-oriented user | Understand consistency and adjust plans | Meaningful trends, controllable detail |
| Accessibility-focused user | Complete every essential flow independently | Semantic structure, scaling, focus, low-motion alternatives |

---

## 3. Information architecture

```text
Habitat
|- Home
|- Tasks
|  |- All Tasks
|  |- Actions
|  |- Alarms
|  |- Task Detail
|  |- Create / Edit Task
|  `- Active Mission / Verification
|- Health
|  |- Water
|  |- Meals
|  `- Nap
|- Progress
|  |- Daily
|  |- Streak
|  |- Achievements
|  `- History
`- Profile
   |- Information
   |- Goals
   |- Preferences
   |- Permissions and Notifications
   `- Settings and Data Controls
```

Rules:

- A feature belongs to the foundation that owns the user’s intent, not merely the data it displays.
- Home may summarize another foundation, but it must link to the owned destination for management or deep detail.
- A task execution state is a modal product state, not a sixth primary destination.
- Journal/reflection is a contextual action entered after completion or from Progress; it does not become a competing primary foundation unless product research proves it needs one.
- Feature names are nouns in navigation and verbs in primary actions: **Tasks** / **Create task**, **Water** / **Log water**.

---

## 4. Navigation architecture

### 4.1 Canonical navigation

The five primary destinations are: **Home, Tasks, Health, Progress, Profile**.

| Context | Primary navigation | Secondary behavior |
|---|---|---|
| Phone | Bottom navigation with five destinations | Push detail routes; modal sheets for focused choices |
| Tablet | Navigation rail or adaptive bottom navigation | Two-pane list/detail where useful |
| Desktop web | Persistent sidebar | URL-addressable nested routes and contextual panels |

### 4.2 Route and back rules

- Every non-transient destination has a stable, shareable web URL and a deep-link equivalent for mobile.
- Back returns to the prior meaningful context, never silently discarding edited data.
- A primary-tab tap returns to that foundation’s root; it must not unexpectedly restart an active mission.
- Destructive or irreversible operations require confirmation with a clear consequence.
- Active alarm/mission states are protected: the system back action must follow the safety and recovery policy, not merely dismiss the view.

### 4.3 Current implementation alignment

The current mobile root uses `Today`, `Tasks`, `Journey`, and `More`; this is transitional. Future routing must adopt the canonical five foundations and replace ad-hoc `Navigator` paths with a typed, deep-linkable route model. `go_router` is already available to the applications and is the preferred routing foundation.

---

## 5. Design-token framework

Token names express purpose, never a one-off screen. Feature code must consume semantic tokens through the shared design-system package.

```text
color.*       typography.*   spacing.*    size.*
radius.*      border.*       elevation.*  opacity.*
motion.*      breakpoint.*   zIndex.*
```

Existing candidate foundations include `AppColors`, `AppSpacing`, `AppRadii`, `AppElevation`, and `AppMotion` in `packages/design_system`. Phase 2 must reconcile these with legacy feature-level themes and expose one public token API.

Token rules:

- No raw color, spacing, radius, duration, or elevation value in feature UI code, except a documented platform-system value.
- Semantic colors include at least surface, content, border, action, success, warning, error, info, disabled, and focus.
- State colors must communicate state without relying on hue alone.
- Dark and light themes use the same semantic token names.
- Breakpoints and density rules are tokens, not screen-local decisions.

---

## 6. Component architecture and contracts

### 6.1 Foundation components

Navigation, buttons, inputs, forms, cards, lists, dialogs, sheets, tabs, menus, feedback, progress indicators, charts, and data display are foundation components.

### 6.2 Habitat components

`TaskCard`, `ActionCard`, `AlarmCard`, `TaskProgress`, `StreakIndicator`, `AchievementCard`, `WaterTracker`, `MealTracker`, `NapTracker`, `DailyProgress`, and `HealthSummary` are product components.

### 6.3 Required component contract

Every reusable component documents:

| Contract field | Requirement |
|---|---|
| Purpose | User problem and appropriate use |
| Inputs | Required, optional, and invalid values |
| Variants | Named variants with intended contexts |
| States | Loading, ready, disabled, error, success, and any domain state |
| Interaction | Tap/click, long-press, keyboard, focus, and back/dismiss behavior |
| Accessibility | Label, role, semantics, minimum target, focus order, announcement behavior |
| Responsive behavior | Reflow, truncation, density, and overflow rules |
| Platform adaptation | Android, iOS, and web exceptions |
| Analytics | Meaningful events, excluding sensitive content by default |

Never create a new component while an existing component can meet the interaction without an incoherent variant.

---

## 7. Interaction framework

### 7.1 Universal interaction sequence

```text
User action -> system acknowledgement -> visual/haptic/audio feedback -> new state -> next useful action
```

### 7.2 Input rules

| Input | Rule |
|---|---|
| Tap / click | The primary action is obvious and has immediate acknowledgement |
| Long press | Reserved for discoverable secondary actions; never required for an essential task |
| Swipe / drag | Must have a visible alternative control and cancellation path |
| Scroll | Must not hide a time-critical alarm action |
| Dismiss | Sheets and dialogs expose a clear dismissal path; critical mission states follow safety policy |
| Back | Preserves context and requests confirmation when work would be lost |
| Keyboard | All web functionality is operable with keyboard only |

### 7.3 Interaction states

Interactive components support, where relevant: `default`, `hover`, `focus`, `pressed`, `selected`, `disabled`, `loading`, `success`, and `error`. Hover is additive and never the sole signal for an action.

---

## 8. State framework

Every data-dependent screen and component defines the state contract below before visual design:

```text
initial -> loading -> ready
                     |- empty
                     |- active
                     |- completed
                     |- error
                     `- offline
```

| State | Required behavior |
|---|---|
| Initial | Avoid a blank or misleading layout while state is resolving |
| Loading | Preserve context where possible; communicate progress without blocking unrelated actions |
| Empty | Explain the value, tell the user how to begin, provide one clear action |
| Active | Show current status, next action, and safe exit/recovery route |
| Completed | Confirm outcome and direct the user to the next useful step |
| Error | Explain in plain language, preserve input, provide retry or alternate route |
| Offline | State what is local, queued, or unavailable; never imply sync succeeded when it has not |

Failure is never a dead end:

```text
Failure -> explanation -> recovery options -> retry or safe exit
```

For proof verification, feedback distinguishes capture failure, upload/sync delay, review, rejection, and accepted completion. A rejected proof must state the actionable reason without revealing security-sensitive anti-cheat thresholds.

---

## 9. Responsive framework

Phase 2 defines numeric breakpoints; Phase 0 establishes the behavior contract.

| Concern | Phone | Tablet | Desktop web |
|---|---|---|---|
| Navigation | Bottom navigation | Rail or adaptive bottom navigation | Persistent sidebar |
| Layout | One primary column | Adaptive one/two column | Grid, panels, higher data density |
| Detail | Full route or sheet | Side-by-side where practical | List-detail or contextual panel |
| Modal | Full-height sheet where necessary | Centered dialog or sheet | Dialog/panel with keyboard focus trap |
| Tables/charts | Summary + drilldown | Adaptive labels | Full controls, tooltips, sortable detail |

- Content reflows; it must not depend on horizontal scrolling for essential use.
- Typography scales without clipping, overlap, or loss of controls.
- Touch targets remain usable on touch devices; pointer density must not reduce accessibility.
- Responsive behavior belongs in component and layout contracts, never only in a single screen.

---

## 10. Platform framework

| Platform | Required adaptation |
|---|---|
| Android | Material conventions where appropriate; system back; system bars; notification channels; exact-alarm and battery-optimization explanations; native alarm reliability behavior |
| iOS | Safe areas; platform navigation and sheet behavior; Dynamic Type; permission explanations; haptic conventions; local-notification limitations communicated honestly |
| Web | URL/deep-link state; browser navigation; keyboard and focus; pointer/hover states; responsive desktop density; browser notification limitations |

Shared product intent must not vary: an alarm’s requirements, verification result, completion semantics, and recovery options mean the same thing on every platform.

Platform differences must be documented in the component/flow contract; they cannot be hidden in feature code.

---

## 11. Accessibility framework

Web accessibility targets WCAG 2.2 AA as the baseline. Android and iOS must use their respective accessibility APIs and platform guidance.

Required checks:

- Color contrast and color-independent status communication.
- Dynamic text/text scaling without loss of task completion.
- Minimum target sizes appropriate to platform guidance.
- Logical semantic labels, roles, values, and announcements.
- Predictable focus order, visible focus indicators, and keyboard-only operation on web.
- Screen-reader access to task state, alarm status, progress, and verification outcome.
- Reduced-motion support and no time-critical instruction conveyed only through motion, sound, or haptics.
- Error messages linked to their inputs and written in actionable language.

Accessibility acceptance is tested for every critical flow, not inferred from a component library.

---

## 12. Motion framework

Motion communicates cause and effect. It is never required to understand a result or complete a task.

| Motion type | Purpose | Rule |
|---|---|---|
| Navigation | Preserve orientation | Short, interruptible, consistent |
| Entry / exit | Explain containment and context | Never delays urgent action |
| State change | Explain updated task, alarm, or health state | Paired with text/semantic state |
| Success | Confirm meaningful completion | Respect reduced-motion preference |
| Error | Draw attention to recovery | Avoid punitive or excessive motion |
| Progress | Show work still happening | Must not imply guaranteed completion |
| Microinteraction | Acknowledge a direct input | Subtle and consistent |

Phase 2 standardizes durations, curves, and reduced-motion alternatives using the shared `AppMotion` token API.

---

## 13. Content framework

### 13.1 Vocabulary

Use one canonical term per concept:

| Concept | Canonical wording |
|---|---|
| A scheduled unit of behavior | Task |
| The immediate execution of a task | Action |
| Time-based prompt and escalation | Alarm |
| Proof assessment | Verification |
| Favorable verification outcome | Verified / Completed |
| Unfavorable assessment | Needs retry |
| Missed or interrupted plan | Recovery |

Do not interchange **Complete**, **Done**, **Finish**, and **Mark Complete** for the same action without a defined contextual rule. Default primary verb: **Complete**.

### 13.2 Writing rules

- Lead with the user’s next action.
- Explain why a permission is needed before requesting it.
- Make empty states constructive; make errors specific and recoverable.
- Never imply an alarm is guaranteed on a platform when operating-system limits apply.
- Avoid shaming language after misses, retries, or recovery.
- Use concise labels; put education in progressive disclosure.

---

## 14. Feedback framework

| Event | Required feedback | Permitted channels |
|---|---|---|
| Success | Confirmation and resulting state | Inline confirmation, haptic, audio where appropriate, notification |
| Failure | Clear cause and recovery action | Inline error, dialog only when needed, haptic/audio only if non-punitive |
| Warning | Prevent or inform before risk | Inline warning, contextual dialog, notification |
| System status | Tell the user what is happening | Status region, progress indicator, notification |

Feedback hierarchy:

1. Inline feedback for local, recoverable changes.
2. Snackbar for brief, non-blocking confirmation with an optional undo.
3. Sheet or dialog only for a decision that needs attention.
4. System notification only for time-sensitive or background-relevant events.
5. Haptic and audio reinforce, but never replace, visual and semantic feedback.

---

## 15. UX governance rules

1. No future screen bypasses the canonical information architecture or navigation model.
2. Every new flow documents entry, action, feedback, success, failure, recovery, and exit.
3. Every data-dependent screen declares loading, empty, ready, error, and offline behavior.
4. Every primary action has an explicit acknowledgement and resulting-state feedback.
5. Feature UI consumes shared tokens and components; raw visual constants in feature screens are a migration exception that must be tracked and removed.
6. Platform variations are intentional, documented, and preserve product intent.
7. No accessibility exception is accepted without a documented accessible alternative.
8. No analytics event captures proof media, journal content, or sensitive health detail unless explicitly consented to and governed by privacy policy.
9. Component additions require a contract and an owner in the design-system package.
10. Design-system changes require Android, iOS, and web impact review.

---

## Phase 0 acceptance criteria

Phase 0 is complete only when all criteria are demonstrably met:

- [ ] Product principles are approved and reflected in all critical-flow decisions.
- [ ] The five foundations, hierarchy, and ownership boundaries are approved.
- [ ] Typed navigation and deep-link conventions are specified for mobile and web.
- [ ] Public design-token naming and migration plan are approved.
- [ ] Foundation and Habitat component inventories have contracts and owners.
- [ ] State, error, offline, and recovery policies are defined for every critical flow.
- [ ] Responsive behavior is defined at the component/layout level.
- [ ] Android, iOS, and web platform differences are documented.
- [ ] WCAG 2.2 AA baseline and mobile accessibility test criteria are adopted.
- [ ] Motion, content, and feedback rules are adopted.
- [ ] Governance rules are part of pull-request and design-review checklists.

## Required Phase 1 artifacts

Once Phase 0 is accepted, Phase 1 produces:

1. Personas and jobs-to-be-done.
2. A complete information-architecture map.
3. User journeys for onboarding, first task, task/alarm creation, alarm execution, verification success/failure, health logging, progress review, and recovery.
4. Typed route map and state ownership model.
5. Traceability table: user action -> UI state -> local/backend operation -> feedback -> recovery path.

## Implementation alignment backlog

The current repository has a design-system package and broad screen inventory, but it does not yet fully conform to this framework. Prioritize:

1. Make `packages/design_system` the dependency and public UI authority for mobile and web.
2. Consolidate feature-level `HabitatTheme` constants into semantic shared tokens.
3. Replace the current four-tab mobile root with the canonical five-foundation navigation after Phase 1 route approval.
4. Adopt a typed `go_router` route map, including web URLs and deep links.
5. Write component contracts for existing reusable components before creating new feature UI.
6. Add accessibility, responsive, and interaction-state tests to the UI validation plan.

