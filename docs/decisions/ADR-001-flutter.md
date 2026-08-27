# ADR-001: Client Application Framework Selection (Flutter + Dart)

## Status
Accepted (2026-08-27)

## Context
The Habitat application requires:
1. Exact, high-framerate rendering (60/120fps) for wake-up missions, viewfinder HUDs, and real-time animations.
2. Unified codebase across iOS, Android, and modern Web (CanvasKit / WebAssembly).
3. Access to low-level native OS APIs (Android Foreground Services, AlarmManager, iOS AVAudioSession, Critical Alerts).
4. A clean, modular domain architecture that can scale from an alarm tool to a full Health & Personal Development platform.

## Decision
Adopt **Flutter + Dart** as the universal client application layer, while reserving native **Android (Kotlin)** and **iOS (Swift)** platform modules for time-critical alarm, audio, and background execution integrations.

## Consequences
* **Positive**: Single product model and single UI codebase across mobile and web; deterministic 120fps rendering; seamless platform channel extensibility.
* **Tradeoff**: Web builds run via CanvasKit/Wasm rather than standard DOM elements; native alarm integration requires platform-specific Kotlin and Swift code.
