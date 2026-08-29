.PHONY: help dev test build docker-up docker-down clean

help:
	@echo "Habitat Discipline Platform - Developer Commands"
	@echo "--------------------------------------------------"
	@echo "make docker-up    - Start PostgreSQL, Redis & MinIO S3 containers"
	@echo "make docker-down  - Stop all local infrastructure containers"
	@echo "make dev-backend  - Start TypeScript/Express backend in development mode"
	@echo "make dev-mobile   - Run Flutter mobile app"
	@echo "make dev-web      - Run Flutter web dashboard"
	@echo "make test         - Run backend and domain unit/integration test suites"
	@echo "make build        - Compile backend TypeScript and build client bundles"

docker-up:
	docker compose -f infrastructure/docker/docker-compose.yml up -d

docker-down:
	docker compose -f infrastructure/docker/docker-compose.yml down

dev-backend:
	cd backend && npm run dev

dev-mobile:
	cd apps/mobile && flutter run

dev-web:
	cd apps/web && flutter run -d chrome

test:
	cd backend && npm test

build-backend:
	cd backend && npm run build

clean:
	rm -rf backend/dist apps/mobile/build apps/web/build
