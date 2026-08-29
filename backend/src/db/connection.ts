// Database Connection with Node Native SQLite (with automatic WAL mode & Task Templates schema)
import { DatabaseSync } from 'node:sqlite';
import * as path from 'path';
import * as fs from 'fs';

const DB_DIR = path.resolve(process.cwd(), 'data');
if (!fs.existsSync(DB_DIR)) {
  fs.mkdirSync(DB_DIR, { recursive: true });
}

const DB_PATH = process.env.NODE_ENV === 'test'
  ? ':memory:'
  : path.join(DB_DIR, 'habitat_v1.db');

export class DatabaseService {
  private static instance: DatabaseSync | null = null;

  public static getDb(): DatabaseSync {
    if (!this.instance) {
      this.instance = new DatabaseSync(DB_PATH);
      if (DB_PATH !== ':memory:') {
        this.instance.exec('PRAGMA journal_mode = WAL;');
      }
      this.instance.exec('PRAGMA foreign_keys = ON;');
      this.initializeSchema();
    }
    return this.instance;
  }

  public static resetDbForTesting(): DatabaseSync {
    if (this.instance) {
      this.instance.close();
    }
    this.instance = new DatabaseSync(':memory:');
    this.instance.exec('PRAGMA foreign_keys = ON;');
    this.initializeSchema();
    return this.instance;
  }

  private static initializeSchema(): void {
    if (!this.instance) return;

    const schema = `
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        display_name TEXT NOT NULL,
        timezone TEXT NOT NULL DEFAULT 'UTC',
        discipline_score INTEGER DEFAULT 100,
        autonomy_level INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS user_preferences (
        user_id TEXT PRIMARY KEY,
        theme TEXT NOT NULL DEFAULT 'system',
        notifications_enabled INTEGER DEFAULT 1,
        sound_enabled INTEGER DEFAULT 1,
        vibration_enabled INTEGER DEFAULT 1,
        motivational_feedback INTEGER DEFAULT 1,
        reduced_motion INTEGER DEFAULT 0,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS task_templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        instructions TEXT NOT NULL,
        category TEXT NOT NULL,
        proof_type TEXT NOT NULL,
        default_difficulty INTEGER DEFAULT 2,
        base_xp INTEGER NOT NULL DEFAULT 20,
        estimated_duration_sec INTEGER NOT NULL DEFAULT 60,
        icon_name TEXT DEFAULT 'hotel',
        validation_rules TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS tasks (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        template_id TEXT,
        slug TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        name TEXT,
        description TEXT NOT NULL,
        instructions TEXT NOT NULL,
        category TEXT NOT NULL,
        proof_type TEXT NOT NULL,
        verification_type TEXT NOT NULL DEFAULT 'BASIC',
        difficulty INTEGER NOT NULL DEFAULT 2, -- 1 to 5
        base_xp INTEGER NOT NULL DEFAULT 20,
        xp_reward INTEGER NOT NULL DEFAULT 25,
        estimated_duration_sec INTEGER NOT NULL DEFAULT 60,
        icon_name TEXT DEFAULT 'hotel',
        validation_rules TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'ACTIVE', -- 'DRAFT', 'ACTIVE', 'PAUSED', 'ARCHIVED'
        is_active INTEGER DEFAULT 1,
        is_starter INTEGER DEFAULT 0,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        archived_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (template_id) REFERENCES task_templates(id) ON DELETE SET NULL
      );

      CREATE TABLE IF NOT EXISTS alarms (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        task_id TEXT NOT NULL,
        time_of_day TEXT NOT NULL,
        timezone TEXT NOT NULL DEFAULT 'UTC',
        repeat_days TEXT NOT NULL,
        discipline_mode TEXT NOT NULL DEFAULT 'DISCIPLINE',
        retry_interval_minutes INTEGER DEFAULT 5,
        is_enabled INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS alarm_occurrences (
        occurrence_id TEXT PRIMARY KEY,
        alarm_id TEXT NOT NULL,
        mission_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        scheduled_at TEXT NOT NULL,
        scheduler_registered_at TEXT NOT NULL,
        triggered_at TEXT,
        mission_started_at TEXT,
        completed_at TEXT,
        retry_count INTEGER DEFAULT 0,
        failure_reason TEXT,
        platform TEXT NOT NULL DEFAULT 'android',
        status TEXT NOT NULL DEFAULT 'SCHEDULED',
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (alarm_id) REFERENCES alarms(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS audio_profiles (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        name TEXT NOT NULL,
        base_frequency_hz INTEGER NOT NULL DEFAULT 440,
        binaural_beat_hz REAL NOT NULL DEFAULT 40.0,
        escalation_profile TEXT NOT NULL DEFAULT 'EXPONENTIAL',
        strobe_interval_ms INTEGER DEFAULT 250,
        is_preset INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS mesh_devices (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        device_name TEXT NOT NULL,
        device_type TEXT NOT NULL,
        push_token TEXT,
        last_ping_at TEXT NOT NULL,
        is_online INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS mesh_events (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        payload TEXT NOT NULL,
        dispatched_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS lockdown_settings (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL UNIQUE,
        is_shield_enabled INTEGER DEFAULT 1,
        blocked_apps TEXT NOT NULL,
        quarantine_duration_min INTEGER DEFAULT 60,
        strict_mode INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS discipline_bonds (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        mission_id TEXT,
        staked_xp INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        created_at TEXT NOT NULL,
        settled_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS emergency_bypasses (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        reason TEXT NOT NULL,
        authorized_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS routines (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT DEFAULT '',
        title TEXT,
        description TEXT,
        type TEXT NOT NULL DEFAULT 'MORNING',
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        version INTEGER NOT NULL DEFAULT 1,
        trigger_time TEXT,
        repeat_days TEXT,
        is_enabled INTEGER DEFAULT 1,
        pause_until TEXT,
        minimum_required_tasks INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS routine_tasks (
        id TEXT PRIMARY KEY,
        routine_id TEXT NOT NULL,
        task_id TEXT,
        task_template_id TEXT,
        sequence INTEGER NOT NULL DEFAULT 1,
        step_order INTEGER DEFAULT 1,
        offset_minutes INTEGER DEFAULT 0,
        required INTEGER DEFAULT 1,
        created_at TEXT,
        FOREIGN KEY (routine_id) REFERENCES routines(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS squads (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        invite_code TEXT UNIQUE NOT NULL,
        collective_streak INTEGER DEFAULT 0,
        created_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS squad_members (
        id TEXT PRIMARY KEY,
        squad_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'MEMBER',
        joined_at TEXT NOT NULL,
        UNIQUE(squad_id, user_id),
        FOREIGN KEY (squad_id) REFERENCES squads(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS squad_events (
        id TEXT PRIMARY KEY,
        squad_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        description TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (squad_id) REFERENCES squads(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS challenges (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        duration_days INTEGER NOT NULL,
        reward_xp INTEGER NOT NULL,
        trophy_name TEXT NOT NULL,
        task_ids TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS challenge_participants (
        id TEXT PRIMARY KEY,
        challenge_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        days_completed INTEGER DEFAULT 0,
        average_resistance_sec INTEGER DEFAULT 120,
        is_completed INTEGER DEFAULT 0,
        joined_at TEXT NOT NULL,
        UNIQUE(challenge_id, user_id),
        FOREIGN KEY (challenge_id) REFERENCES challenges(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS physical_anchors (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        anchor_type TEXT NOT NULL,
        location_label TEXT NOT NULL,
        hardware_identifier TEXT NOT NULL,
        secret_key TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS anchor_verifications (
        id TEXT PRIMARY KEY,
        anchor_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        mission_id TEXT,
        nonce TEXT NOT NULL,
        verified_at TEXT NOT NULL,
        FOREIGN KEY (anchor_id) REFERENCES physical_anchors(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS accountability_partners (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        escalation_threshold INTEGER DEFAULT 3,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS accountability_logs (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        mission_id TEXT,
        partner_id TEXT NOT NULL,
        message TEXT NOT NULL,
        dispatched_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (partner_id) REFERENCES accountability_partners(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS sleep_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        start_time TEXT,
        end_time TEXT,
        started_at TEXT,
        ended_at TEXT,
        duration_minutes INTEGER DEFAULT 0,
        duration_sec INTEGER DEFAULT 0,
        deep_sleep_minutes INTEGER DEFAULT 0,
        rem_sleep_minutes INTEGER DEFAULT 0,
        hrv_score INTEGER,
        recovery_score INTEGER DEFAULT 80,
        source TEXT DEFAULT 'MANUAL',
        quality INTEGER,
        notes TEXT,
        external_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS coach_insights (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        insight_type TEXT NOT NULL,
        headline TEXT NOT NULL,
        content TEXT NOT NULL,
        actionable_recommendation TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS missions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        alarm_id TEXT,
        task_id TEXT NOT NULL,
        scheduled_at TEXT NOT NULL,
        started_at TEXT,
        triggered_at TEXT,
        completed_at TEXT,
        cancelled_at TEXT,
        expired_at TEXT,
        status TEXT NOT NULL DEFAULT 'SCHEDULED',
        attempt_count INTEGER DEFAULT 0,
        retry_count INTEGER DEFAULT 0,
        next_retry_at TEXT,
        resistance_seconds INTEGER,
        discipline_mode TEXT NOT NULL DEFAULT 'DISCIPLINE',
        routine_id TEXT,
        source TEXT DEFAULT 'MANUAL',
        routine_version INTEGER,
        idempotency_key TEXT UNIQUE,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (alarm_id) REFERENCES alarms(id) ON DELETE SET NULL,
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS mission_attempts (
        id TEXT PRIMARY KEY,
        mission_id TEXT NOT NULL,
        attempt_index INTEGER NOT NULL,
        started_at TEXT,
        submitted_at TEXT,
        triggered_at TEXT,
        resolved_at TEXT,
        status TEXT NOT NULL DEFAULT 'IGNORED',
        siren_volume_level INTEGER DEFAULT 70,
        failure_reason TEXT,
        created_at TEXT,
        FOREIGN KEY (mission_id) REFERENCES missions(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS mission_events (
        id TEXT PRIMARY KEY,
        mission_id TEXT NOT NULL,
        type TEXT NOT NULL,
        from_status TEXT,
        to_status TEXT,
        metadata TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (mission_id) REFERENCES missions(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS proofs (
        id TEXT PRIMARY KEY,
        mission_id TEXT NOT NULL,
        user_id TEXT,
        attempt_id TEXT,
        upload_id TEXT,
        media_type TEXT NOT NULL,
        storage_key TEXT NOT NULL,
        object_key TEXT,
        thumbnail_key TEXT,
        mime_type TEXT,
        size_bytes INTEGER DEFAULT 0,
        sha256 TEXT,
        duration_ms INTEGER,
        width INTEGER,
        height INTEGER,
        captured_at TEXT NOT NULL,
        uploaded_at TEXT,
        verified_at TEXT,
        device_telemetry TEXT NOT NULL DEFAULT '{}',
        verification_status TEXT NOT NULL DEFAULT 'PENDING',
        rejection_reason TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (mission_id) REFERENCES missions(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS verification_reports (
        id TEXT PRIMARY KEY,
        mission_id TEXT NOT NULL,
        proof_id TEXT,
        strategy_used TEXT NOT NULL,
        is_valid INTEGER NOT NULL,
        confidence_score REAL NOT NULL,
        rejection_reason TEXT,
        extracted_metrics TEXT NOT NULL DEFAULT '{}',
        created_at TEXT NOT NULL,
        FOREIGN KEY (mission_id) REFERENCES missions(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS verifications (
        id TEXT PRIMARY KEY,
        proof_id TEXT NOT NULL,
        mission_id TEXT NOT NULL,
        attempt_id TEXT,
        user_id TEXT NOT NULL,
        status TEXT NOT NULL,
        decision TEXT,
        confidence REAL,
        verifier TEXT NOT NULL,
        verifier_version TEXT NOT NULL,
        reasons TEXT DEFAULT '[]',
        checks TEXT DEFAULT '[]',
        started_at TEXT,
        completed_at TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (mission_id) REFERENCES missions(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS xp_transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        mission_id TEXT,
        amount INTEGER NOT NULL,
        reason TEXT NOT NULL,
        source_type TEXT DEFAULT 'MISSION_COMPLETION',
        source_id TEXT,
        idempotency_key TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS streaks (
        user_id TEXT PRIMARY KEY,
        current_streak INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        grace_tokens INTEGER DEFAULT 1,
        last_completed_date TEXT,
        recovery_used INTEGER DEFAULT 0,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS user_gamification (
        user_id TEXT PRIMARY KEY,
        total_xp INTEGER DEFAULT 0,
        level INTEGER DEFAULT 1,
        discipline_score REAL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS achievements (
        id TEXT PRIMARY KEY,
        code TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        requirement TEXT NOT NULL,
        xp_reward INTEGER DEFAULT 0,
        active INTEGER DEFAULT 1
      );

      CREATE TABLE IF NOT EXISTS user_achievements (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        achievement_id TEXT NOT NULL,
        unlocked_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (achievement_id) REFERENCES achievements(id) ON DELETE CASCADE,
        UNIQUE(user_id, achievement_id)
      );

      CREATE TABLE IF NOT EXISTS daily_discipline_stats (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        tasks_assigned INTEGER DEFAULT 0,
        tasks_completed INTEGER DEFAULT 0,
        tasks_failed INTEGER DEFAULT 0,
        xp_earned INTEGER DEFAULT 0,
        discipline_score REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(user_id, date)
      );

      CREATE TABLE IF NOT EXISTS routine_versions (
        id TEXT PRIMARY KEY,
        routine_id TEXT NOT NULL,
        version INTEGER NOT NULL,
        configuration TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (routine_id) REFERENCES routines(id) ON DELETE CASCADE,
        UNIQUE(routine_id, version)
      );

      CREATE TABLE IF NOT EXISTS schedule_rules (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        routine_id TEXT,
        task_template_id TEXT,
        schedule_type TEXT NOT NULL,
        time_of_day TEXT,
        schedule_window_start TEXT,
        schedule_window_end TEXT,
        days_of_week TEXT,
        start_date TEXT,
        end_date TEXT,
        timezone TEXT NOT NULL DEFAULT 'UTC',
        enabled INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS task_dependencies (
        id TEXT PRIMARY KEY,
        routine_id TEXT,
        prerequisite_id TEXT NOT NULL,
        dependent_id TEXT NOT NULL,
        dependency_type TEXT NOT NULL DEFAULT 'HARD',
        created_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS rest_days (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        reason TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(user_id, date)
      );

      CREATE TABLE IF NOT EXISTS behavior_events (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        mission_id TEXT,
        task_id TEXT,
        routine_id TEXT,
        timestamp TEXT NOT NULL,
        metadata TEXT,
        idempotency_key TEXT UNIQUE,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS task_performances (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        task_template_id TEXT NOT NULL,
        period_start TEXT NOT NULL,
        period_end TEXT NOT NULL,
        attempts INTEGER DEFAULT 0,
        completions INTEGER DEFAULT 0,
        misses INTEGER DEFAULT 0,
        average_delay_sec INTEGER DEFAULT 0,
        average_duration_sec INTEGER DEFAULT 0,
        success_rate REAL DEFAULT 0.0,
        difficulty_score REAL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS recommendations (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        priority TEXT NOT NULL DEFAULT 'MEDIUM',
        confidence REAL NOT NULL DEFAULT 0.8,
        title TEXT NOT NULL,
        explanation TEXT NOT NULL,
        payload TEXT,
        status TEXT NOT NULL DEFAULT 'PENDING',
        created_at TEXT NOT NULL,
        expires_at TEXT,
        resolved_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS exercise_templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        unit TEXT NOT NULL DEFAULT 'REPETITIONS',
        difficulty TEXT DEFAULT 'BALANCED',
        active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS exercise_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        duration_sec INTEGER DEFAULT 0,
        quantity REAL DEFAULT 0,
        unit TEXT DEFAULT 'REPETITIONS',
        sets INTEGER DEFAULT 1,
        notes TEXT,
        source TEXT DEFAULT 'APP',
        external_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS hydration_entries (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        amount_ml INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        source TEXT DEFAULT 'APP',
        external_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS wellness_goals (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        target REAL NOT NULL,
        unit TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS wellness_metrics (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        value REAL NOT NULL,
        unit TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        source TEXT NOT NULL,
        external_id TEXT,
        metadata TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS health_provider_connections (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        provider TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'DISCONNECTED',
        permissions TEXT,
        last_sync_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(user_id, provider)
      );

      CREATE TABLE IF NOT EXISTS discipline_profiles (
        id TEXT PRIMARY KEY,
        user_id TEXT UNIQUE NOT NULL,
        preferred_wake TEXT,
        preferred_sleep TEXT,
        consistency REAL DEFAULT 0.0,
        completion_rate REAL DEFAULT 0.0,
        preferred_days TEXT,
        preferred_times TEXT,
        strengths TEXT,
        friction_points TEXT,
        coaching_style TEXT DEFAULT 'DIRECT',
        planning_autonomy TEXT DEFAULT 'ASSISTED',
        version INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS behavior_patterns (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        pattern_type TEXT NOT NULL,
        confidence REAL NOT NULL DEFAULT 0.8,
        sample_size INTEGER NOT NULL DEFAULT 0,
        period_days INTEGER NOT NULL DEFAULT 30,
        evidence TEXT,
        classification TEXT NOT NULL DEFAULT 'OBSERVED',
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS daily_plans (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        plan_date TEXT NOT NULL,
        schedule_items TEXT NOT NULL,
        conflicts TEXT,
        status TEXT NOT NULL DEFAULT 'PROPOSED',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(user_id, plan_date)
      );

      CREATE TABLE IF NOT EXISTS coach_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        summary TEXT,
        metadata TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS coach_messages (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        metadata TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES coach_sessions(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS user_entitlements (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        entitlement_code TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        expires_at TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(user_id, entitlement_code)
      );

      CREATE TABLE IF NOT EXISTS social_relationships (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        target_user_id TEXT NOT NULL,
        relationship_type TEXT NOT NULL, -- 'FRIEND', 'BLOCKED', 'PENDING'
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (target_user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(user_id, target_user_id)
      );

      CREATE TABLE IF NOT EXISTS content_reports (
        id TEXT PRIMARY KEY,
        reporter_id TEXT NOT NULL,
        target_id TEXT NOT NULL,
        target_type TEXT NOT NULL,
        reason TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'REVIEWED', 'ACTIONED', 'DISMISSED'
        created_at TEXT NOT NULL,
        FOREIGN KEY (reporter_id) REFERENCES users(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS feature_flags (
        id TEXT PRIMARY KEY,
        key TEXT UNIQUE NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        description TEXT,
        created_at TEXT NOT NULL
      );

      CREATE INDEX IF NOT EXISTS idx_behavior_events ON behavior_events(user_id, timestamp);
      CREATE INDEX IF NOT EXISTS idx_discipline_profiles_user ON discipline_profiles(user_id);
      CREATE INDEX IF NOT EXISTS idx_behavior_patterns_user ON behavior_patterns(user_id, pattern_type);
      CREATE INDEX IF NOT EXISTS idx_daily_plans_user_date ON daily_plans(user_id, plan_date);
      CREATE INDEX IF NOT EXISTS idx_coach_sessions_user ON coach_sessions(user_id, created_at);
      CREATE INDEX IF NOT EXISTS idx_coach_messages_session ON coach_messages(session_id, created_at);
      CREATE INDEX IF NOT EXISTS idx_user_entitlements ON user_entitlements(user_id, entitlement_code);
      CREATE INDEX IF NOT EXISTS idx_social_relationships ON social_relationships(user_id, relationship_type);
      CREATE INDEX IF NOT EXISTS idx_behavior_type ON behavior_events(user_id, type);
      CREATE INDEX IF NOT EXISTS idx_recommendations_user ON recommendations(user_id, status);
      CREATE INDEX IF NOT EXISTS idx_task_templates ON task_templates(is_active, sort_order);
      CREATE INDEX IF NOT EXISTS idx_tasks_user_status ON tasks(user_id, status);
      CREATE INDEX IF NOT EXISTS idx_tasks_category ON tasks(category, difficulty);
      CREATE INDEX IF NOT EXISTS idx_mesh_devices ON mesh_devices(user_id, is_online);
      CREATE INDEX IF NOT EXISTS idx_audio_profiles ON audio_profiles(user_id, is_preset);
      CREATE INDEX IF NOT EXISTS idx_lockdown_user ON lockdown_settings(user_id);
      CREATE INDEX IF NOT EXISTS idx_bonds_user ON discipline_bonds(user_id, status);
      CREATE INDEX IF NOT EXISTS idx_physical_anchors ON physical_anchors(user_id, is_active);
      CREATE INDEX IF NOT EXISTS idx_challenges_active ON challenges(is_active, start_date);
      CREATE INDEX IF NOT EXISTS idx_challenge_participants ON challenge_participants(challenge_id, user_id);
      CREATE INDEX IF NOT EXISTS idx_coach_insights ON coach_insights(user_id, created_at);
      CREATE INDEX IF NOT EXISTS idx_squad_members ON squad_members(squad_id, user_id);
      CREATE INDEX IF NOT EXISTS idx_squad_events ON squad_events(squad_id, created_at);
      CREATE INDEX IF NOT EXISTS idx_sleep_user ON sleep_sessions(user_id, start_time);
      CREATE INDEX IF NOT EXISTS idx_missions_user ON missions(user_id, status);
      CREATE INDEX IF NOT EXISTS idx_alarms_user ON alarms(user_id, is_enabled);
      CREATE INDEX IF NOT EXISTS idx_xp_user ON xp_transactions(user_id);
    `;

    this.instance.exec(schema);
  }
}
