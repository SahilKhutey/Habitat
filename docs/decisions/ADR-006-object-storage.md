# ADR-006: Media Storage Architecture (Object Storage vs Database Blobs)

## Status
Accepted (2026-08-27)

## Context
User missions generate media proof files (JPEG photos and MP4 video recordings of exercise repetitions). Storing binary blobs directly in PostgreSQL degrades database performance, bloats backups, and increases storage costs.

## Decision
Store all photo and video proofs in an **S3-compatible Object Store** (MinIO for local development / AWS S3 or Cloudflare R2 for production), with PostgreSQL storing only storage keys, checksums, and verification metadata.

## Consequences
* **Positive**: Fast signed upload URLs; infinite storage scalability; low cost; zero load on database connections during media streaming.
* **Tradeoff**: Requires managing S3 presigned URL lifecycles and background bucket garbage collection.
