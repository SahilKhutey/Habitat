// Automated Test Suite for Milestone B5: PostgreSQL Migration & Prisma Seed
import { describe, it, expect, vi } from 'vitest';
import * as fs from 'fs';
import * as path from 'path';
import { STARTER_TEMPLATES, hashPassword } from '../prisma/seed';

describe('Milestone B5: PostgreSQL Migration & Prisma Seed Verification', () => {
  const migrationPath = path.resolve(
    __dirname,
    '../prisma/migrations/20260829170000_init_postgres/migration.sql'
  );

  it('B5.1: Initial PostgreSQL migration file exists and contains complete DDL', () => {
    expect(fs.existsSync(migrationPath)).toBe(true);
    const sql = fs.readFileSync(migrationPath, 'utf-8');

    // Verify core tables created
    expect(sql).toContain('CREATE TABLE "users"');
    expect(sql).toContain('CREATE TABLE "task_templates"');
    expect(sql).toContain('CREATE TABLE "tasks"');
    expect(sql).toContain('CREATE TABLE "alarms"');
    expect(sql).toContain('CREATE TABLE "alarm_occurrences"');
    expect(sql).toContain('CREATE TABLE "missions"');
    expect(sql).toContain('CREATE TABLE "mission_attempts"');
    expect(sql).toContain('CREATE TABLE "proofs"');
    expect(sql).toContain('CREATE TABLE "verifications"');
    expect(sql).toContain('CREATE TABLE "xp_transactions"');
    expect(sql).toContain('CREATE TABLE "streaks"');
    expect(sql).toContain('CREATE TABLE "routines"');
    expect(sql).toContain('CREATE TABLE "sleep_sessions"');

    // Verify relational constraints
    expect(sql).toContain('ALTER TABLE "tasks" ADD CONSTRAINT "tasks_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id")');
    expect(sql).toContain('ALTER TABLE "alarms" ADD CONSTRAINT "alarms_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "tasks"("id")');
    expect(sql).toContain('ALTER TABLE "missions" ADD CONSTRAINT "missions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id")');
    expect(sql).toContain('ALTER TABLE "proofs" ADD CONSTRAINT "proofs_mission_id_fkey" FOREIGN KEY ("mission_id") REFERENCES "missions"("id")');
  });

  it('B5.2: Starter Task Templates are comprehensive and contain 10 canonical templates', () => {
    expect(STARTER_TEMPLATES).toHaveLength(10);
    const templateIds = STARTER_TEMPLATES.map((t) => t.id);

    expect(templateIds).toContain('tpl-make-bed');
    expect(templateIds).toContain('tpl-pushups-10');
    expect(templateIds).toContain('tpl-brush-teeth');
    expect(templateIds).toContain('tpl-hydrate-glass');
    expect(templateIds).toContain('tpl-morning-sunlight');
    expect(templateIds).toContain('tpl-clean-desk');
    expect(templateIds).toContain('tpl-walk-2min');
    expect(templateIds).toContain('tpl-read-2pages');
    expect(templateIds).toContain('tpl-body-stretch-30s');
    expect(templateIds).toContain('tpl-prep-tomorrow-clothes');
  });

  it('B5.3: Password hashing helper computes deterministic SHA-256 digests', () => {
    const hash1 = hashPassword('Discipline2026!');
    const hash2 = hashPassword('Discipline2026!');
    expect(hash1).toBe(hash2);
    expect(hash1.length).toBe(64);
  });

  it('B5.4: Package.json specifies prisma seed command', () => {
    const packageJsonPath = path.resolve(__dirname, '../package.json');
    const pkg = JSON.parse(fs.readFileSync(packageJsonPath, 'utf-8'));

    expect(pkg.prisma).toBeDefined();
    expect(pkg.prisma.seed).toContain('seed.ts');
    expect(pkg.scripts['db:seed']).toBe('prisma db seed');
  });
});
