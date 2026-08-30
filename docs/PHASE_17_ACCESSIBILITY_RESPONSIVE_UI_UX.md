# Habitat Phase 17 — Accessibility + Responsive UI/UX Architecture

## Overview
Phase 17 standardizes responsive layout primitives and accessibility semantics across Android, iOS, iPadOS, macOS, Linux, Windows, and Web.

## Responsive Primitives
1. **`HabitatPage`**:
   - Safe Area integration.
   - Dynamic horizontal padding ($\text{Mobile: }16\text{dp}$, $\text{Tablet: }24\text{dp}$, $\text{Desktop: }32\text{dp}$).
   - Maximum content constraint ($1200\text{px}$) preventing overly wide desktop stretched layouts.
2. **`HabitatAdaptiveGrid`**:
   - $\text{Width } < 600\text{px}$: 1 column.
   - $\text{Width } 600\text{px} - 1199\text{px}$: 2 columns.
   - $\text{Width } \ge 1200\text{px}$: 3–4 columns.
3. **Adaptive `AppShell`**:
   - Mobile ($<600\text{px}$): Bottom `NavigationBar`.
   - Tablet & Desktop ($\ge 600\text{px}$): Side `NavigationRail`.
   - Embeds `FocusTraversalGroup` for keyboard focus ordering.

## Accessibility Semantics (`HabitatA11y`)
- `HabitatA11y.button()`: Exposes button role, action label, hint, and enabled state.
- `HabitatA11y.heading()`: Exposes `header: true` allowing TalkBack / VoiceOver structural navigation.
- `HabitatA11y.status()`: `liveRegion: true` announcing dynamic metric updates (XP, streaks).
- `HabitatA11y.chartAlternative()`: Supplies textual narrative alternatives for visual graphs.
- `HabitatAccessibilityScrollBehavior`: Enables touch, mouse, trackpad, and stylus drag-scrolling on Web and Desktop.
- $\ge 48\times 48\text{dp}$ touch target guarantees across all interactive controls.
