# Deployment & Infrastructure (`docs/deployment`)

## Docker Compose Stack
- **PostgreSQL 16**: Port 5432
- **Redis 7**: Port 6379
- **MinIO S3**: Port 9000 (API), Port 9001 (Console UI)

## Start Infrastructure
```bash
docker compose -f infrastructure/docker/docker-compose.yml up -d
```
