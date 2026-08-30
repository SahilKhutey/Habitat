// Phase 19 Local-First SQLite Database Engine & Data Access Objects
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class LocalUser {
  final String id;
  final String displayName;
  final String bio;
  final String avatarUrl;
  final String disciplineLevel;
  final String timezone;
  final DateTime createdAt;

  LocalUser({
    required this.id,
    required this.displayName,
    this.bio = 'Building the life I want to live with Habitat.',
    this.avatarUrl = '',
    this.disciplineLevel = 'Explorer',
    required this.timezone,
    required this.createdAt,
  });

  LocalUser copyWith({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? disciplineLevel,
    String? timezone,
  }) =>
      LocalUser(
        id: id,
        displayName: displayName ?? this.displayName,
        bio: bio ?? this.bio,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        disciplineLevel: disciplineLevel ?? this.disciplineLevel,
        timezone: timezone ?? this.timezone,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'displayName': displayName,
    'bio': bio,
    'avatarUrl': avatarUrl,
    'disciplineLevel': disciplineLevel,
    'timezone': timezone,
    'createdAt': createdAt.toIso8601String(),
  };

  factory LocalUser.fromMap(Map<String, dynamic> map) => LocalUser(
    id: map['id'],
    displayName: map['displayName'],
    bio: map['bio'] ?? 'Building the life I want to live with Habitat.',
    avatarUrl: map['avatarUrl'] ?? '',
    disciplineLevel: map['disciplineLevel'] ?? 'Explorer',
    timezone: map['timezone'] ?? 'UTC',
    createdAt: DateTime.parse(map['createdAt']),
  );
}

class LocalTask {
  final String id;
  final String title;
  final String description;
  final String category;
  final String taskType;
  final bool requiresPhoto;
  final bool requiresVideo;
  final bool requiresVerification;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  LocalTask({
    required this.id,
    required this.title,
    this.description = '',
    required this.category,
    required this.taskType,
    this.requiresPhoto = false,
    this.requiresVideo = false,
    this.requiresVerification = true,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'taskType': taskType,
    'requiresPhoto': requiresPhoto ? 1 : 0,
    'requiresVideo': requiresVideo ? 1 : 0,
    'requiresVerification': requiresVerification ? 1 : 0,
    'active': active ? 1 : 0,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class LocalAlarm {
  final String id;
  final String taskId;
  final String scheduledTime; // HH:mm
  final bool enabled;
  final String repeatType; // DAILY, WEEKDAYS, CUSTOM
  final List<int> repeatDays;
  final int retryIntervalMinutes; // 5 minutes standard, 1 minute test mode
  final int maxRetries;
  final DateTime? nextTrigger;
  final DateTime createdAt;

  LocalAlarm({
    required this.id,
    required this.taskId,
    required this.scheduledTime,
    this.enabled = true,
    this.repeatType = 'DAILY',
    this.repeatDays = const [1, 2, 3, 4, 5, 6, 7],
    this.retryIntervalMinutes = 5,
    this.maxRetries = 6,
    this.nextTrigger,
    required this.createdAt,
  });
}

class LocalTaskAttempt {
  final String id;
  final String taskId;
  final String alarmId;
  final int attemptNumber;
  final String status; // SCHEDULED, RINGING, AWAITING_ACTION, COMPLETED, FAILED, RETRY
  final DateTime triggeredAt;
  final DateTime? completedAt;

  LocalTaskAttempt({
    required this.id,
    required this.taskId,
    required this.alarmId,
    required this.attemptNumber,
    required this.status,
    required this.triggeredAt,
    this.completedAt,
  });
}

class LocalProof {
  final String id;
  final String taskId;
  final String attemptId;
  final String type; // PHOTO, VIDEO
  final String localPath;
  final int durationSeconds;
  final bool isVerified;
  final DateTime createdAt;

  LocalProof({
    required this.id,
    required this.taskId,
    required this.attemptId,
    required this.type,
    required this.localPath,
    this.durationSeconds = 0,
    this.isVerified = false,
    required this.createdAt,
  });
}

class LocalXPEvent {
  final String id;
  final String eventType;
  final String taskId;
  final int amount;
  final DateTime createdAt;

  LocalXPEvent({
    required this.id,
    required this.eventType,
    required this.taskId,
    required this.amount,
    required this.createdAt,
  });
}

class LocalStreak {
  final int currentStreak;
  final int longestStreak;
  final String lastCompletedDate; // YYYY-MM-DD

  LocalStreak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate = '',
  });
}

class LocalFeedback {
  final String id;
  final String type; // Bug, Suggestion, Task idea, UI/UX, Alarm problem, Camera problem, Other
  final String title;
  final String message;
  final int rating; // 1-5
  final String? screenshotPath;
  final String status; // PENDING, EXPORTED
  final DateTime createdAt;

  LocalFeedback({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.rating,
    this.screenshotPath,
    this.status = 'PENDING',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'message': message,
    'rating': rating,
    'screenshotPath': screenshotPath,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };
}

class LocalWaterEntry {
  final String id;
  final int milliliters;
  final DateTime recordedAt;

  LocalWaterEntry({required this.id, required this.milliliters, required this.recordedAt});
}

class LocalMealEntry {
  final String id;
  final String type;
  final DateTime recordedAt;
  final String? notes;

  LocalMealEntry({required this.id, required this.type, required this.recordedAt, this.notes});
}

class LocalNapEntry {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;

  LocalNapEntry({required this.id, required this.startedAt, this.endedAt});

  bool get isRunning => endedAt == null;
  int get durationMinutes => (endedAt ?? DateTime.now()).difference(startedAt).inMinutes;
}

class LocalEventLog {
  final String id;
  final String eventType;
  final String entityId;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  LocalEventLog({
    required this.id,
    required this.eventType,
    required this.entityId,
    required this.timestamp,
    this.metadata = const {},
  });
}

class LocalHealthLog {
  final String id;
  final String type; // WATER, MEAL, NAP, EXERCISE
  final DateTime recordedAt;
  final double amount;
  final String unit;
  final String? mealType;
  final int? durationMinutes;
  final String note;

  LocalHealthLog({
    required this.id,
    required this.type,
    required this.recordedAt,
    this.amount = 0.0,
    this.unit = '',
    this.mealType,
    this.durationMinutes,
    this.note = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'recordedAt': recordedAt.toIso8601String(),
    'amount': amount,
    'unit': unit,
    'mealType': mealType,
    'durationMinutes': durationMinutes,
    'note': note,
  };
}

/// In-Memory / SQLite Repository Layer for Local-First MVP
class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._internal();
  LocalDatabase._internal();

  LocalUser? _currentUser;
  final Map<String, LocalTask> _tasks = {};
  final Map<String, LocalAlarm> _alarms = {};
  final List<LocalTaskAttempt> _attempts = [];
  final List<LocalProof> _proofs = [];
  final List<LocalXPEvent> _xpEvents = [];
  final List<LocalWaterEntry> _waterEntries = [];
  final List<LocalMealEntry> _mealEntries = [];
  final List<LocalNapEntry> _napEntries = [];
  final List<LocalHealthLog> _healthLogs = [];
  final List<LocalEventLog> _eventLogs = [];
  final List<LocalFeedback> _feedbackList = [];
  int _waterGoal = 2000;
  final Set<String> _unlockedAchievements = {'FIRST_STEP'};
  int _graceTokens = 1;

  Map<String, dynamic> _preferences = {
    'language': 'English',
    'timeFormat24h': false,
    'weekStartsOnMonday': true,
    'defaultTaskView': 'List',
    'defaultProgressRange': 'Today',
  };
  Map<String, dynamic> _notificationSettings = {
    'taskReminders': true,
    'alarmNotifications': true,
    'progressUpdates': true,
    'achievementAlerts': true,
    'quietHours': false,
    'quietHoursStart': '22:00',
    'quietHoursEnd': '07:00',
  };
  Map<String, dynamic> _appearanceSettings = {
    'themeMode': 'system',
    'reduceMotion': false,
    'highContrast': false,
    'largerText': false,
  };
  Map<String, dynamic> _privacySettings = {
    'analytics': false,
    'dataSharing': false,
    'localFirstNoticeAccepted': true,
  };
  Map<String, dynamic> _securitySettings = {
    'appLock': false,
    'biometric': false,
    'pin': null,
  };

  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  void _notifyChanged() => changes.value++;

  // Default MVP Template Tasks
  void initializeDefaultTemplates() {
    if (_tasks.isNotEmpty) return;

    final templates = [
      LocalTask(id: 'task-brush', title: 'Brush Teeth', category: 'HEALTH', taskType: 'PHOTO', requiresPhoto: true, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      LocalTask(id: 'task-pushups', title: '15 Pushups', category: 'EXERCISE', taskType: 'VIDEO', requiresVideo: true, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      LocalTask(id: 'task-water', title: 'Drink 500ml Water', category: 'HEALTH', taskType: 'PHOTO', requiresPhoto: true, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      LocalTask(id: 'task-bed', title: 'Make Bed', category: 'DISCIPLINE', taskType: 'PHOTO', requiresPhoto: true, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      LocalTask(id: 'task-outside', title: 'Morning Sunlight Walk', category: 'DISCIPLINE', taskType: 'PHOTO', requiresPhoto: true, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      LocalTask(id: 'task-stretch', title: '5-Minute Stretch', category: 'EXERCISE', taskType: 'VIDEO', requiresVideo: true, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      LocalTask(id: 'task-read', title: 'Read 10 Pages', category: 'MIND', taskType: 'PHOTO', requiresPhoto: true, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      LocalTask(id: 'task-workspace', title: 'Clean Workspace', category: 'DISCIPLINE', taskType: 'PHOTO', requiresPhoto: true, createdAt: DateTime.now(), updatedAt: DateTime.now()),
    ];

    for (final t in templates) {
      _tasks[t.id] = t;
    }
    _notifyChanged();
  }

  // Profile Management
  LocalUser getOrCreateProfile({String name = 'Discipline Explorer'}) {
    _currentUser ??= LocalUser(
      id: const Uuid().v4(),
      displayName: name,
      timezone: 'UTC',
      createdAt: DateTime.now(),
    );
    return _currentUser!;
  }

  void updateProfile({required String displayName, required String bio, String? avatarUrl}) {
    final current = getOrCreateProfile();
    _currentUser = current.copyWith(
      displayName: displayName,
      bio: bio,
      avatarUrl: avatarUrl,
    );
    _notifyChanged();
  }

  // Tasks & Alarms
  List<LocalTask> getAllTasks() => _tasks.values.toList();
  LocalTask? getTask(String id) => _tasks[id];
  LocalTask? getTaskById(String id) => _tasks[id];
  void saveTask(LocalTask task) {
    _tasks[task.id] = task;
    _notifyChanged();
  }
  void updateTask(LocalTask task) {
    _tasks[task.id] = task;
    _notifyChanged();
  }
  void deleteTask(String id) {
    _tasks.remove(id);
    _notifyChanged();
  }
  void completeTask(String taskId) {
    final task = _tasks[taskId];
    if (task == null) return;
    if (task.requiresPhoto || task.requiresVideo) {
      final hasVerifiedProof = _proofs.any((p) => p.taskId == taskId && p.isVerified) ||
          _attempts.any((a) => a.taskId == taskId && a.status == 'COMPLETED');
      if (!hasVerifiedProof) {
        throw StateError('Task requires a verified proof before completion');
      }
    }
    _tasks[taskId] = task.copyWith(
      isCompleted: true,
      updatedAt: DateTime.now(),
    );
    _notifyChanged();
  }

  List<LocalAlarm> getAllAlarms() => _alarms.values.toList();
  void saveAlarm(LocalAlarm alarm) {
    _alarms[alarm.id] = alarm;
    _notifyChanged();
  }

  // Attempts
  LocalTaskAttempt? getAttempt(String attemptId) {
    return _attempts.where((a) => a.id == attemptId).firstOrNull;
  }
  void recordAttempt(LocalTaskAttempt attempt) {
    _attempts.add(attempt);
    _notifyChanged();
  }
  void saveAttempt(LocalTaskAttempt attempt) {
    final idx = _attempts.indexWhere((a) => a.id == attempt.id);
    if (idx >= 0) {
      _attempts[idx] = attempt;
    } else {
      _attempts.add(attempt);
    }
    _notifyChanged();
  }
  void updateAttemptStatus({required String attemptId, required String status, DateTime? completedAt}) {
    final index = _attempts.indexWhere((attempt) => attempt.id == attemptId);
    if (index < 0) return;
    final existing = _attempts[index];
    _attempts[index] = LocalTaskAttempt(
      id: existing.id,
      taskId: existing.taskId,
      alarmId: existing.alarmId,
      attemptNumber: existing.attemptNumber,
      status: status,
      triggeredAt: existing.triggeredAt,
      completedAt: completedAt ?? existing.completedAt,
    );
    _notifyChanged();
  }
  List<LocalTaskAttempt> getAllAttempts() => List.unmodifiable(_attempts);
  List<LocalTaskAttempt> getAttemptsForTask(String taskId) =>
      _attempts.where((a) => a.taskId == taskId).toList();

  // Proofs
  void recordProof(LocalProof proof) {
    _proofs.add(proof);
    _notifyChanged();
  }
  void saveProof(LocalProof proof) => recordProof(proof);
  List<LocalProof> getProofsForTask(String taskId) =>
      _proofs.where((p) => p.taskId == taskId).toList();
  List<LocalProof> getProofsForAttempt(String attemptId) =>
      _proofs.where((p) => p.attemptId == attemptId).toList();

  // XP & Gamification
  void awardXP({required String taskId, String? attemptId, required int amount, String eventType = 'TASK_COMPLETED'}) {
    // Precise idempotency: keyed by attemptId or unique event key
    final key = attemptId != null ? '$taskId:$attemptId' : taskId;
    final exists = _xpEvents.any((e) => e.taskId == key);
    if (!exists) {
      _xpEvents.add(LocalXPEvent(
        id: const Uuid().v4(),
        eventType: eventType,
        taskId: key,
        amount: amount,
        createdAt: DateTime.now(),
      ));
      _notifyChanged();
    }
  }

  int getTotalXP() => _xpEvents.fold(0, (sum, e) => sum + e.amount);

  // Streak Engine
  void updateStreak() {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    if (_streak.lastCompletedDate == todayStr) return;

    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
    int newStreak = 1;
    if (_streak.lastCompletedDate == yesterday) {
      newStreak = _streak.currentStreak + 1;
    }

    _streak = LocalStreak(
      currentStreak: newStreak,
      longestStreak: newStreak > _streak.longestStreak ? newStreak : _streak.longestStreak,
      lastCompletedDate: todayStr,
    );
    _notifyChanged();
  }

  LocalStreak getStreak() => _streak;

  Set<String> getUnlockedAchievements() => Set.unmodifiable(_unlockedAchievements);
  void unlockAchievement(String code) {
    if (_unlockedAchievements.add(code)) {
      _notifyChanged();
    }
  }

  int getGraceTokens() => _graceTokens;
  bool useGraceToken() {
    if (_graceTokens > 0) {
      _graceTokens--;
      _notifyChanged();
      return true;
    }
    return false;
  }
  void addGraceToken() {
    if (_graceTokens < 3) {
      _graceTokens++;
      _notifyChanged();
    }
  }

  // Health records. These local-first records are the source for Home summaries.
  int getWaterGoal() => _waterGoal;
  void setWaterGoal(int milliliters) {
    if (milliliters > 0) {
      _waterGoal = milliliters;
      _notifyChanged();
    }
  }

  void addWater({required int milliliters, DateTime? recordedAt}) {
    if (milliliters <= 0) throw ArgumentError.value(milliliters, 'milliliters', 'must be positive');
    _waterEntries.add(LocalWaterEntry(
      id: const Uuid().v4(),
      milliliters: milliliters,
      recordedAt: recordedAt ?? DateTime.now(),
    ));
    _notifyChanged();
  }

  void removeWaterEntry(String id) {
    _waterEntries.removeWhere((entry) => entry.id == id);
    _notifyChanged();
  }

  void addMeal({required String type, String? notes, DateTime? recordedAt}) {
    const allowedTypes = {'breakfast', 'lunch', 'snack', 'dinner'};
    if (!allowedTypes.contains(type)) throw ArgumentError.value(type, 'type', 'must be a supported meal type');
    _mealEntries.add(LocalMealEntry(
      id: const Uuid().v4(),
      type: type,
      notes: notes,
      recordedAt: recordedAt ?? DateTime.now(),
    ));
    _notifyChanged();
  }

  void updateMealEntry(LocalMealEntry entry) {
    final idx = _mealEntries.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      _mealEntries[idx] = entry;
      _notifyChanged();
    }
  }

  void deleteMealEntry(String id) {
    _mealEntries.removeWhere((e) => e.id == id);
    _notifyChanged();
  }

  LocalNapEntry startNap({DateTime? startedAt}) {
    final existing = _napEntries.where((entry) => entry.isRunning).toList();
    if (existing.isNotEmpty) return existing.last;
    final entry = LocalNapEntry(id: const Uuid().v4(), startedAt: startedAt ?? DateTime.now());
    _napEntries.add(entry);
    _notifyChanged();
    return entry;
  }

  void stopNap({DateTime? endedAt}) {
    final index = _napEntries.lastIndexWhere((entry) => entry.isRunning);
    if (index < 0) return;
    final active = _napEntries[index];
    _napEntries[index] = LocalNapEntry(
      id: active.id,
      startedAt: active.startedAt,
      endedAt: endedAt ?? DateTime.now(),
    );
    _notifyChanged();
  }

  List<LocalWaterEntry> getWaterEntriesForDay(DateTime day) => _waterEntries.where((entry) => _sameDay(entry.recordedAt, day)).toList();
  List<LocalMealEntry> getMealEntriesForDay(DateTime day) => _mealEntries.where((entry) => _sameDay(entry.recordedAt, day)).toList();
  List<LocalNapEntry> getNapEntriesForDay(DateTime day) => _napEntries.where((entry) => _sameDay(entry.startedAt, day)).toList();

  List<LocalWaterEntry> getAllWaterEntries() => List.unmodifiable(_waterEntries);
  List<LocalMealEntry> getAllMealEntries() => List.unmodifiable(_mealEntries);
  List<LocalNapEntry> getAllNapEntries() => List.unmodifiable(_napEntries);

  // Phase 16 Health Logs & 7-Day Visual Progress Aggregations
  void recordHealthLog(LocalHealthLog log) {
    _healthLogs.add(log);
    _notifyChanged();
  }

  List<LocalHealthLog> getAllHealthLogs() => List.unmodifiable(_healthLogs);

  List<LocalHealthLog> getTodayHealthLogs() {
    final now = DateTime.now();
    return _healthLogs.where((l) => _sameDay(l.recordedAt, now)).toList();
  }

  double getTodayWaterLiters() {
    final todayLogs = getTodayHealthLogs().where((l) => l.type == 'WATER');
    if (todayLogs.isNotEmpty) {
      final totalMl = todayLogs.fold<double>(0.0, (sum, l) => sum + (l.unit == 'L' ? l.amount * 1000 : l.amount));
      return totalMl / 1000.0;
    }
    final now = DateTime.now();
    final waterEntries = getWaterEntriesForDay(now);
    final totalMl = waterEntries.fold<int>(0, (sum, e) => sum + e.milliliters);
    return totalMl / 1000.0;
  }

  int getTodayMealCount() {
    final todayMealLogs = getTodayHealthLogs().where((l) => l.type == 'MEAL');
    if (todayMealLogs.isNotEmpty) {
      return todayMealLogs.length;
    }
    final now = DateTime.now();
    return getMealEntriesForDay(now).length;
  }

  int getTodayNapMinutes() {
    final todayNapLogs = getTodayHealthLogs().where((l) => l.type == 'NAP');
    if (todayNapLogs.isNotEmpty) {
      return todayNapLogs.fold<int>(0, (sum, l) => sum + (l.durationMinutes ?? l.amount.toInt()));
    }
    final now = DateTime.now();
    final napEntries = getNapEntriesForDay(now);
    return napEntries.fold<int>(0, (sum, e) => sum + e.durationMinutes);
  }

  Map<String, int> getDailyCompletions() {
    final result = <String, int>{};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dateKey = '${day.year}-${day.month.toString().padLeft(2, "0")}-${day.day.toString().padLeft(2, "0")}';
      final completedCount = _attempts.where((a) => a.status == 'COMPLETED' && _sameDay(a.triggeredAt, day)).length;
      result[dateKey] = completedCount;
    }
    return result;
  }

  Map<String, double> getDailyWater() {
    final result = <String, double>{};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dateKey = '${day.year}-${day.month.toString().padLeft(2, "0")}-${day.day.toString().padLeft(2, "0")}';
      final waterEntries = getWaterEntriesForDay(day);
      final healthWater = _healthLogs.where((l) => l.type == 'WATER' && _sameDay(l.recordedAt, day));
      double totalLiters = 0.0;
      if (healthWater.isNotEmpty) {
        totalLiters = healthWater.fold<double>(0.0, (sum, l) => sum + (l.unit == 'L' ? l.amount : l.amount / 1000.0));
      } else {
        totalLiters = waterEntries.fold<int>(0, (sum, e) => sum + e.milliliters) / 1000.0;
      }
      result[dateKey] = totalLiters;
    }
    return result;
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  // Feedback
  void addFeedback(LocalFeedback fb) {
    _feedbackList.add(fb);
    _notifyChanged();
  }
  List<LocalFeedback> getAllFeedback() => List.unmodifiable(_feedbackList);

  // Settings Accessors
  Map<String, dynamic> getPreferences() => Map.unmodifiable(_preferences);
  void setPreferences(Map<String, dynamic> prefs) {
    _preferences = Map.from(prefs);
    _notifyChanged();
  }

  Map<String, dynamic> getNotificationSettings() => Map.unmodifiable(_notificationSettings);
  void setNotificationSettings(Map<String, dynamic> notifs) {
    _notificationSettings = Map.from(notifs);
    _notifyChanged();
  }

  Map<String, dynamic> getAppearanceSettings() => Map.unmodifiable(_appearanceSettings);
  void setAppearanceSettings(Map<String, dynamic> app) {
    _appearanceSettings = Map.from(app);
    _notifyChanged();
  }

  Map<String, dynamic> getPrivacySettings() => Map.unmodifiable(_privacySettings);
  void setPrivacySettings(Map<String, dynamic> priv) {
    _privacySettings = Map.from(priv);
    _notifyChanged();
  }

  Map<String, dynamic> getSecuritySettings() => Map.unmodifiable(_securitySettings);
  void setSecuritySettings(Map<String, dynamic> sec) {
    _securitySettings = Map.from(sec);
    _notifyChanged();
  }

  // Data & Storage
  Map<String, int> getStorageBreakdown() {
    return {
      'tasks': _tasks.length * 150 + _attempts.length * 80,
      'health': _waterEntries.length * 40 + _mealEntries.length * 60 + _napEntries.length * 50,
      'progress': _xpEvents.length * 30 + 120,
      'profile': 250,
    };
  }

  String exportAllDataAsJson() {
    final user = getOrCreateProfile();
    final buffer = StringBuffer();
    buffer.writeln('{');
    buffer.writeln('  "version": "1.0.0",');
    buffer.writeln('  "exportedAt": "${DateTime.now().toIso8601String()}",');
    buffer.writeln('  "user": {"displayName": "${user.displayName}", "bio": "${user.bio}"},');
    buffer.writeln('  "tasksCount": ${_tasks.length},');
    buffer.writeln('  "attemptsCount": ${_attempts.length},');
    buffer.writeln('  "waterEntriesCount": ${_waterEntries.length},');
    buffer.writeln('  "mealEntriesCount": ${_mealEntries.length},');
    buffer.writeln('  "napEntriesCount": ${_napEntries.length},');
    buffer.writeln('  "streak": {"current": ${_streak.currentStreak}, "longest": ${_streak.longestStreak}}');
    buffer.writeln('}');
    return buffer.toString();
  }

  // Event Ledger
  void recordEvent({
    required String eventType,
    required String entityId,
    Map<String, dynamic> metadata = const {},
  }) {
    _eventLogs.add(LocalEventLog(
      id: const Uuid().v4(),
      eventType: eventType,
      entityId: entityId,
      timestamp: DateTime.now(),
      metadata: metadata,
    ));
    _notifyChanged();
  }

  List<LocalEventLog> getRecentEvents({int limit = 50}) {
    return _eventLogs.reversed.take(limit).toList();
  }

  // Reset MVP
  void resetAllData() {
    _currentUser = null;
    _tasks.clear();
    _alarms.clear();
    _attempts.clear();
    _proofs.clear();
    _xpEvents.clear();
    _waterEntries.clear();
    _mealEntries.clear();
    _napEntries.clear();
    _eventLogs.clear();
    _streak = LocalStreak();
    _feedbackList.clear();
    initializeDefaultTemplates();
    _notifyChanged();
  }
}
