# ADR-002: Backend Architecture Selection (Modular TypeScript + Express; NestJS Deferred)

## Status
Accepted (Revised 2026-08-29)

## Context
The Habitat backend serves as the single source of truth for:
* User identity and tenant isolation.
* Authoritative mission lifecycles (`SCHEDULED` $\to$ `ACTIVE` $\to$ `VERIFYING` $\to$ `COMPLETED` $\lor$ `RETRY`).
* Append-only XP Transaction Ledger and timezone-aware streak calculations.
* Real-time WebSocket event dispatching to mobile clients.
* Multi-signal evidence verification and cryptographic challenge nonces.

Earlier architectural documentation proposed NestJS; however, the active backend is already implemented, tested, and performing cleanly as a modular TypeScript + Express service.

## Decision
Retain and harden the **Modular TypeScript + Express Architecture**. Defer any framework migration to NestJS until specific growth criteria are met:
1. Multi-engineer backend team expansion requiring strict declarative conventions.
2. Manual dependency injection across complex multi-service domains becoming unwieldy.
3. Middleware, guards, pipes, and interceptor requirements expanding significantly.
4. Scale expanding beyond 100+ endpoints and multiple background queue workers.

## Architectural Guidelines
1. **Strict Layering**: `HTTP -> Controller -> Service/UseCase -> Repository -> Database`. Controllers contain zero business logic.
2. **Authentication**: Authenticated user context derived strictly from JWT middleware (`req.user.id`), not query parameters.
3. **Validation & Errors**: Standardized Zod request schemas and centralized JSON error formatting.
4. **Data Isolation**: Replaceable repository abstractions (`Repository<T>`) decoupling domain services from underlying storage engines (SQLite in local/dev; PostgreSQL in production).

## Consequences
* **Positive**: Eliminates framework migration churn; preserves 100% of tested domain engines; keeps startup lightweight and iteration velocity high.
* **Tradeoff**: Dependency injection and middleware wiring must be disciplined manually without NestJS decorators until migration threshold is reached.

