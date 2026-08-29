# Habitat Design System — Repository Implementation

## Status

Phase 7 consolidation is implemented as the shared UI foundation for the
Android/iOS Flutter client and the Flutter Web application.

## Canonical foundations

1. Home
2. Tasks / Actions / Alarms
3. Health
4. Streak / Progress
5. Profile

Alarms remain inside the Tasks/Actions domain rather than becoming a sixth
primary product destination.

## Source of truth

- `packages/design_system/lib/tokens/`
- `packages/design_system/lib/theme/`
- `packages/design_system/lib/components/`
- `apps/mobile/lib/core/design_system/`
- `apps/mobile/lib/features/profile/presentation/pages/profile_page.dart`

## Rules

- Prefer semantic tokens over raw visual constants.
- Reuse shared components before creating feature-specific UI.
- Keep business logic outside reusable UI components.
- Use `NavigationBar` on compact screens and `NavigationRail` on desktop.
- Preserve minimum ~48 logical-pixel interactive targets.
- Every interactive icon has a tooltip and/or semantic label.
- Loading, empty, error and success states are first-class UI states.
- Respect light/dark theme and system text scaling.
- Keep desktop content constrained rather than stretching indefinitely.
- Alarms are a domain capability, not a top-level navigation destination.

## Verification

Run from `apps/mobile`:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build web
```
