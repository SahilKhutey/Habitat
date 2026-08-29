// Habitat Retry Rules Domain Model
import 'package:flutter/foundation.dart';

enum RetryActionOnMaxFail {
  markMissed,
  stopAlarm,
  notifyAccountabilityPartner,
}

@immutable
class TaskRetryRulesModel {
  final bool enabled;
  final int retryIntervalMinutes; // Default 5 minutes
  final int maxAttempts; // Default 3 attempts
  final RetryActionOnMaxFail actionOnMaxFail;

  const TaskRetryRulesModel({
    this.enabled = true,
    this.retryIntervalMinutes = 5,
    this.maxAttempts = 3,
    this.actionOnMaxFail = RetryActionOnMaxFail.markMissed,
  });

  String get summaryDescription => enabled
      ? 'Every $retryIntervalMinutes minutes • Max $maxAttempts attempts'
      : 'No retries (Single attempt only)';
}
