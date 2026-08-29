# Habitat Offline Data Model Specifications

## SQLite Table Schema
- `users`: `id`, `displayName`, `timezone`, `createdAt`
- `tasks`: `id`, `title`, `description`, `category`, `taskType`, `requiresPhoto`, `requiresVideo`, `requiresVerification`, `active`, `createdAt`, `updatedAt`
- `alarms`: `id`, `taskId`, `scheduledTime`, `enabled`, `repeatType`, `repeatDays`, `retryIntervalMinutes`, `maxRetries`, `nextTrigger`, `createdAt`
- `task_attempts`: `id`, `taskId`, `alarmId`, `attemptNumber`, `status`, `triggeredAt`, `completedAt`
- `proofs`: `id`, `taskId`, `attemptId`, `type`, `localPath`, `durationSeconds`, `isVerified`, `createdAt`
- `xp_events`: `id`, `eventType`, `taskId`, `amount`, `createdAt` (Append-Only)
- `streaks`: `currentStreak`, `longestStreak`, `lastCompletedDate`
- `feedback`: `id`, `type`, `title`, `message`, `rating`, `screenshotPath`, `status`, `createdAt`
