// Phase 19 Local-First SQLite Database Engine & Data Access Objects
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final String difficulty;
  final bool requiresPhoto;
  final bool requiresVideo;
  final bool requiresVerification;
  final bool isCompleted;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  LocalTask({
    required this.id,
    required this.title,
    this.description = '',
    required this.category,
    required this.taskType,
    this.difficulty = 'MEDIUM',
    this.requiresPhoto = false,
    this.requiresVideo = false,
    this.requiresVerification = true,
    this.isCompleted = false,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  LocalTask copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? taskType,
    String? difficulty,
    bool? requiresPhoto,
    bool? requiresVideo,
    bool? requiresVerification,
    bool? isCompleted,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocalTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      taskType: taskType ?? this.taskType,
      difficulty: difficulty ?? this.difficulty,
      requiresPhoto: requiresPhoto ?? this.requiresPhoto,
      requiresVideo: requiresVideo ?? this.requiresVideo,
      requiresVerification: requiresVerification ?? this.requiresVerification,
      isCompleted: isCompleted ?? this.isCompleted,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'taskType': taskType,
    'difficulty': difficulty,
    'requiresPhoto': requiresPhoto ? 1 : 0,
    'requiresVideo': requiresVideo ? 1 : 0,
    'requiresVerification': requiresVerification ? 1 : 0,
    'isCompleted': isCompleted ? 1 : 0,
    'active': active ? 1 : 0,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory LocalTask.fromMap(Map<String, dynamic> map) => LocalTask(
    id: map['id'],
    title: map['title'],
    description: map['description'] ?? '',
    category: map['category'] ?? 'HEALTH',
    taskType: map['taskType'] ?? 'PHOTO',
    difficulty: map['difficulty'] ?? 'MEDIUM',
    requiresPhoto: map['requiresPhoto'] == 1 || map['requiresPhoto'] == true,
    requiresVideo: map['requiresVideo'] == 1 || map['requiresVideo'] == true,
    requiresVerification: map['requiresVerification'] == 1 || map['requiresVerification'] == true,
    isCompleted: map['isCompleted'] == 1 || map['isCompleted'] == true,
    active: map['active'] == 1 || map['active'] == true,
    createdAt: DateTime.parse(map['createdAt']),
    updatedAt: DateTime.parse(map['updatedAt']),
  );
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

  Map<String, dynamic> toMap() => {
    'id': id,
    'taskId': taskId,
    'scheduledTime': scheduledTime,
    'enabled': enabled ? 1 : 0,
    'repeatType': repeatType,
    'repeatDays': repeatDays,
    'retryIntervalMinutes': retryIntervalMinutes,
    'maxRetries': maxRetries,
    'nextTrigger': nextTrigger?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory LocalAlarm.fromMap(Map<String, dynamic> map) => LocalAlarm(
    id: map['id'],
    taskId: map['taskId'],
    scheduledTime: map['scheduledTime'],
    enabled: map['enabled'] == 1 || map['enabled'] == true,
    repeatType: map['repeatType'] ?? 'DAILY',
    repeatDays: (map['repeatDays'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? const [1, 2, 3, 4, 5, 6, 7],
    retryIntervalMinutes: (map['retryIntervalMinutes'] as num?)?.toInt() ?? 5,
    maxRetries: (map['maxRetries'] as num?)?.toInt() ?? 6,
    nextTrigger: map['nextTrigger'] != null ? DateTime.parse(map['nextTrigger']) : null,
    createdAt: DateTime.parse(map['createdAt']),
  );
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

  Map<String, dynamic> toMap() => {
    'id': id,
    'taskId': taskId,
    'alarmId': alarmId,
    'attemptNumber': attemptNumber,
    'status': status,
    'triggeredAt': triggeredAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory LocalTaskAttempt.fromMap(Map<String, dynamic> map) => LocalTaskAttempt(
    id: map['id'],
    taskId: map['taskId'],
    alarmId: map['alarmId'],
    attemptNumber: (map['attemptNumber'] as num?)?.toInt() ?? 1,
    status: map['status'] ?? 'SCHEDULED',
    triggeredAt: DateTime.parse(map['triggeredAt']),
    completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
  );
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

  Map<String, dynamic> toMap() => {
    'id': id,
    'taskId': taskId,
    'attemptId': attemptId,
    'type': type,
    'localPath': localPath,
    'durationSeconds': durationSeconds,
    'isVerified': isVerified ? 1 : 0,
    'createdAt': createdAt.toIso8601String(),
  };

  factory LocalProof.fromMap(Map<String, dynamic> map) => LocalProof(
    id: map['id'],
    taskId: map['taskId'],
    attemptId: map['attemptId'],
    type: map['type'],
    localPath: map['localPath'],
    durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
    isVerified: map['isVerified'] == 1 || map['isVerified'] == true,
    createdAt: DateTime.parse(map['createdAt']),
  );
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

  Map<String, dynamic> toMap() => {
    'id': id,
    'eventType': eventType,
    'taskId': taskId,
    'amount': amount,
    'createdAt': createdAt.toIso8601String(),
  };

  factory LocalXPEvent.fromMap(Map<String, dynamic> map) => LocalXPEvent(
    id: map['id'],
    eventType: map['eventType'],
    taskId: map['taskId'],
    amount: (map['amount'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.parse(map['createdAt']),
  );
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

  Map<String, dynamic> toMap() => {
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'lastCompletedDate': lastCompletedDate,
  };

  factory LocalStreak.fromMap(Map<String, dynamic> map) => LocalStreak(
    currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
    longestStreak: (map['longestStreak'] as num?)?.toInt() ?? 0,
    lastCompletedDate: map['lastCompletedDate'] ?? '',
  );
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

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'title': title,
    'message': message,
    'rating': rating,
    'screenshotPath': screenshotPath,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };

  Map<String, dynamic> toJson() => toMap();

  factory LocalFeedback.fromMap(Map<String, dynamic> map) => LocalFeedback(
    id: map['id'],
    type: map['type'],
    title: map['title'],
    message: map['message'],
    rating: (map['rating'] as num?)?.toInt() ?? 5,
    screenshotPath: map['screenshotPath'],
    status: map['status'] ?? 'PENDING',
    createdAt: DateTime.parse(map['createdAt']),
  );
}

class LocalWaterEntry {
  final String id;
  final int milliliters;
  final DateTime recordedAt;

  LocalWaterEntry({required this.id, required this.milliliters, required this.recordedAt});

  Map<String, dynamic> toMap() => {
    'id': id,
    'milliliters': milliliters,
    'recordedAt': recordedAt.toIso8601String(),
  };

  factory LocalWaterEntry.fromMap(Map<String, dynamic> map) => LocalWaterEntry(
    id: map['id'],
    milliliters: (map['milliliters'] as num?)?.toInt() ?? 0,
    recordedAt: DateTime.parse(map['recordedAt']),
  );
}

class LocalMealEntry {
  final String id;
  final String type;
  final DateTime recordedAt;
  final String? notes;

  LocalMealEntry({required this.id, required this.type, required this.recordedAt, this.notes});

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'recordedAt': recordedAt.toIso8601String(),
    'notes': notes,
  };

  factory LocalMealEntry.fromMap(Map<String, dynamic> map) => LocalMealEntry(
    id: map['id'],
    type: map['type'],
    recordedAt: DateTime.parse(map['recordedAt']),
    notes: map['notes'],
  );
}

class LocalNapEntry {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;

  LocalNapEntry({required this.id, required this.startedAt, this.endedAt});

  bool get isRunning => endedAt == null;
  int get durationMinutes => (endedAt ?? DateTime.now()).difference(startedAt).inMinutes;

  Map<String, dynamic> toMap() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
  };

  factory LocalNapEntry.fromMap(Map<String, dynamic> map) => LocalNapEntry(
    id: map['id'],
    startedAt: DateTime.parse(map['startedAt']),
    endedAt: map['endedAt'] != null ? DateTime.parse(map['endedAt']) : null,
  );
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

  Map<String, dynamic> toMap() => {
    'id': id,
    'eventType': eventType,
    'entityId': entityId,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };

  factory LocalEventLog.fromMap(Map<String, dynamic> map) => LocalEventLog(
    id: map['id'],
    eventType: map['eventType'],
    entityId: map['entityId'],
    timestamp: DateTime.parse(map['timestamp']),
    metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
  );
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

  factory LocalHealthLog.fromMap(Map<String, dynamic> map) => LocalHealthLog(
    id: map['id'],
    type: map['type'],
    recordedAt: DateTime.parse(map['recordedAt']),
    amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    unit: map['unit'] ?? '',
    mealType: map['mealType'],
    durationMinutes: (map['durationMinutes'] as num?)?.toInt(),
    note: map['note'] ?? '',
  );
}

class DurableSyncEvent {
  final String id;
  final String idempotencyKey;
  final String eventType;
  final Map<String, dynamic> payload;
  final int retryCount;
  final DateTime? lastAttemptAt;
  final DateTime createdAt;

  DurableSyncEvent({
    required this.id,
    required this.idempotencyKey,
    required this.eventType,
    required this.payload,
    this.retryCount = 0,
    this.lastAttemptAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'idempotencyKey': idempotencyKey,
    'eventType': eventType,
    'payload': payload,
    'retryCount': retryCount,
    'lastAttemptAt': lastAttemptAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory DurableSyncEvent.fromMap(Map<String, dynamic> map) => DurableSyncEvent(
    id: map['id'],
    idempotencyKey: map['idempotencyKey'],
    eventType: map['eventType'],
    payload: Map<String, dynamic>.from(map['payload'] ?? {}),
    retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
    lastAttemptAt: map['lastAttemptAt'] != null ? DateTime.parse(map['lastAttemptAt']) : null,
    createdAt: DateTime.parse(map['createdAt']),
  );
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
  final List<DurableSyncEvent> _syncQueue = [];
  LocalStreak _streak = LocalStreak();
  int _waterGoal = 2000;
  final Set<String> _unlockedAchievements = {'FIRST_STEP'};
  int _graceTokens = 1;

  // Phase 18 Snapshot & Reliability State
  int _schemaVersion = 3;
  int _revision = 1;
  DateTime _lastSavedAt = DateTime.now();
  Timer? _debounceTimer;
  String? _backupSnapshot;
  String? _corruptPayload;

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

  void _notifyChanged({bool immediate = false}) {
    changes.value++;
    _revision++;
    if (immediate) {
      flush();
    } else {
      _scheduleDebouncedSave();
    }
  }

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
    _notifyChanged(immediate: true);
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
    _notifyChanged(immediate: true);
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
    _notifyChanged(immediate: true);
  }

  List<LocalAlarm> getAllAlarms() => _alarms.values.toList();
  void saveAlarm(LocalAlarm alarm) {
    _alarms[alarm.id] = alarm;
    _notifyChanged(immediate: true);
  }

  // Attempts
  LocalTaskAttempt? getAttempt(String attemptId) {
    return _attempts.where((a) => a.id == attemptId).firstOrNull;
  }
  void recordAttempt(LocalTaskAttempt attempt) {
    _attempts.add(attempt);
    _notifyChanged(immediate: true);
  }
  void saveAttempt(LocalTaskAttempt attempt) {
    final idx = _attempts.indexWhere((a) => a.id == attempt.id);
    if (idx >= 0) {
      _attempts[idx] = attempt;
    } else {
      _attempts.add(attempt);
    }
    _notifyChanged(immediate: true);
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
    _notifyChanged(immediate: true);
  }
  List<LocalTaskAttempt> getAllAttempts() => List.unmodifiable(_attempts);
  List<LocalTaskAttempt> getAttemptsForTask(String taskId) =>
      _attempts.where((a) => a.taskId == taskId).toList();

  // Proofs
  void recordProof(LocalProof proof) {
    _proofs.add(proof);
    _notifyChanged(immediate: true);
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
      _notifyChanged(immediate: true);
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
    _notifyChanged(immediate: true);
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
    final data = {
      'version': '1.0.5',
      'exportedAt': DateTime.now().toIso8601String(),
      'user': {'displayName': user.displayName, 'bio': user.bio},
      'tasksCount': _tasks.length,
      'attemptsCount': _attempts.length,
      'waterEntriesCount': _waterEntries.length,
      'mealEntriesCount': _mealEntries.length,
      'napEntriesCount': _napEntries.length,
      'streak': {'current': _streak.currentStreak, 'longest': _streak.longestStreak}
    };
    return jsonEncode(data);
  }

  String exportCompleteStateJson() {
    final payload = {
      'schemaVersion': _schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'revision': _revision,
      'currentUser': _currentUser?.toMap(),
      'tasks': _tasks.values.map((t) => t.toMap()).toList(),
      'alarms': _alarms.values.map((a) => a.toMap()).toList(),
      'attempts': _attempts.map((a) => a.toMap()).toList(),
      'proofs': _proofs.map((p) => p.toMap()).toList(),
      'xpEvents': _xpEvents.map((e) => e.toMap()).toList(),
      'waterEntries': _waterEntries.map((w) => w.toMap()).toList(),
      'mealEntries': _mealEntries.map((m) => m.toMap()).toList(),
      'napEntries': _napEntries.map((n) => n.toMap()).toList(),
      'healthLogs': _healthLogs.map((h) => h.toMap()).toList(),
      'eventLogs': _eventLogs.map((e) => e.toMap()).toList(),
      'feedbackList': _feedbackList.map((f) => f.toMap()).toList(),
      'syncQueue': _syncQueue.map((s) => s.toMap()).toList(),
      'streak': _streak.toMap(),
      'waterGoal': _waterGoal,
      'unlockedAchievements': _unlockedAchievements.toList(),
      'graceTokens': _graceTokens,
      'preferences': _preferences,
      'notificationSettings': _notificationSettings,
      'appearanceSettings': _appearanceSettings,
      'privacySettings': _privacySettings,
      'securitySettings': _securitySettings,
    };
    return jsonEncode(payload);
  }

  Map<String, dynamic> _migrateSchema(Map<String, dynamic> raw) {
    var data = Map<String, dynamic>.from(raw);
    int version = (data['schemaVersion'] as num?)?.toInt() ?? 1;

    // v1 -> v2 migration: ensure repeatDays defaults if absent
    if (version < 2) {
      if (data['alarms'] is List) {
        for (final a in data['alarms']) {
          if (a is Map && a['repeatDays'] == null) {
            a['repeatDays'] = [1, 2, 3, 4, 5, 6, 7];
          }
        }
      }
      version = 2;
    }

    // v2 -> v3 migration: ensure proofs have isVerified default
    if (version < 3) {
      if (data['proofs'] is List) {
        for (final p in data['proofs']) {
          if (p is Map && p['isVerified'] == null) {
            p['isVerified'] = 0;
          }
        }
      }
      version = 3;
    }

    data['schemaVersion'] = _schemaVersion;
    return data;
  }

  void restoreFromStateJson(String jsonStr) {
    if (jsonStr.isEmpty) return;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) return;

      final migrated = _migrateSchema(decoded);

      if (migrated['currentUser'] != null) {
        _currentUser = LocalUser.fromMap(Map<String, dynamic>.from(migrated['currentUser']));
      }

      _tasks.clear();
      if (migrated['tasks'] is List) {
        for (final item in migrated['tasks']) {
          final t = LocalTask.fromMap(Map<String, dynamic>.from(item));
          _tasks[t.id] = t;
        }
      }

      _alarms.clear();
      if (migrated['alarms'] is List) {
        for (final item in migrated['alarms']) {
          final a = LocalAlarm.fromMap(Map<String, dynamic>.from(item));
          _alarms[a.id] = a;
        }
      }

      _attempts.clear();
      if (migrated['attempts'] is List) {
        for (final item in migrated['attempts']) {
          _attempts.add(LocalTaskAttempt.fromMap(Map<String, dynamic>.from(item)));
        }
      }

      _proofs.clear();
      if (migrated['proofs'] is List) {
        for (final item in migrated['proofs']) {
          _proofs.add(LocalProof.fromMap(Map<String, dynamic>.from(item)));
        }
      }

      _xpEvents.clear();
      if (migrated['xpEvents'] is List) {
        for (final item in migrated['xpEvents']) {
          _xpEvents.add(LocalXPEvent.fromMap(Map<String, dynamic>.from(item)));
        }
      }

      _waterEntries.clear();
      if (migrated['waterEntries'] is List) {
        for (final item in migrated['waterEntries']) {
          _waterEntries.add(LocalWaterEntry.fromMap(Map<String, dynamic>.from(item)));
        }
      }

      _mealEntries.clear();
      if (migrated['mealEntries'] is List) {
        for (final item in migrated['mealEntries']) {
          _mealEntries.add(LocalMealEntry.fromMap(Map<String, dynamic>.from(item)));
        }
      }

      _napEntries.clear();
      if (migrated['napEntries'] is List) {
        for (final item in migrated['napEntries']) {
          _napEntries.add(LocalNapEntry.fromMap(Map<String, dynamic>.from(item)));
        }
      }

      _healthLogs.clear();
      if (migrated['healthLogs'] is List) {
        for (final item in migrated['healthLogs']) {
          _healthLogs.add(LocalHealthLog.fromMap(Map<String, dynamic>.from(item)));
        }
      }

      _eventLogs.clear();
      if (migrated['eventLogs'] is List) {
        for (final item in migrated['eventLogs']) {
          _eventLogs.add(LocalEventLog.fromMap(Map<String, dynamic>.from(item)));
        }
      }

      _feedbackList.clear();
      if (migrated['feedbackList'] is List) {
        for (final item in migrated['feedbackList']) {
          _feedbackList.add(LocalFeedback.fromMap(Map<String, dynamic>.from(item)));
        }
      }

      _syncQueue.clear();
      if (migrated['syncQueue'] is List) {
        for (final item in migrated['syncQueue']) {
          _syncQueue.add(DurableSyncEvent.fromMap(Map<String, dynamic>.from(item)));
        }
      }

      if (migrated['streak'] != null) {
        _streak = LocalStreak.fromMap(Map<String, dynamic>.from(migrated['streak']));
      }

      if (migrated['waterGoal'] != null) {
        _waterGoal = (migrated['waterGoal'] as num).toInt();
      }

      if (migrated['unlockedAchievements'] is List) {
        _unlockedAchievements.clear();
        for (final a in migrated['unlockedAchievements']) {
          _unlockedAchievements.add(a.toString());
        }
      }

      if (migrated['graceTokens'] != null) {
        _graceTokens = (migrated['graceTokens'] as num).toInt();
      }

      if (migrated['preferences'] is Map) {
        _preferences = Map<String, dynamic>.from(migrated['preferences']);
      }
      if (migrated['notificationSettings'] is Map) {
        _notificationSettings = Map<String, dynamic>.from(migrated['notificationSettings']);
      }
      if (migrated['appearanceSettings'] is Map) {
        _appearanceSettings = Map<String, dynamic>.from(migrated['appearanceSettings']);
      }
      if (migrated['privacySettings'] is Map) {
        _privacySettings = Map<String, dynamic>.from(migrated['privacySettings']);
      }
      if (migrated['securitySettings'] is Map) {
        _securitySettings = Map<String, dynamic>.from(migrated['securitySettings']);
      }

      _revision = (migrated['revision'] as num?)?.toInt() ?? _revision;
      changes.value++;
    } catch (_) {}
  }

  // Disk Persistence
  Future<void> loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('habitat_local_db_v3');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        restoreFromStateJson(jsonStr);
        return;
      }
    } catch (_) {}

    // If storage was empty or failed, initialize default templates
    if (_tasks.isEmpty) {
      initializeDefaultTemplates();
    }
  }

  Future<void> saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = exportCompleteStateJson();
      await prefs.setString('habitat_local_db_v3', jsonStr);
    } catch (_) {}
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

  // Phase 18 Snapshot Versioning, Reliability & Offline Sync
  int get schemaVersion => _schemaVersion;
  int get revision => _revision;
  DateTime get lastSavedAt => _lastSavedAt;
  List<DurableSyncEvent> get syncQueue => List.unmodifiable(_syncQueue);

  void _scheduleDebouncedSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      flush();
    });
  }

  Future<void> flush() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _lastSavedAt = DateTime.now();

    // 1. Backup previous primary snapshot before replacing
    final previousSnapshot = exportCompleteStateJson();
    _backupSnapshot = previousSnapshot;

    // 2. Persist to disk
    await saveToDisk();
  }

  bool recoverFromBackup() {
    if (_backupSnapshot == null || _backupSnapshot!.isEmpty) return false;
    try {
      restoreFromStateJson(_backupSnapshot!);
      return true;
    } catch (_) {
      return false;
    }
  }

  void enqueueSyncEvent({
    required String eventType,
    required String idempotencyKey,
    required Map<String, dynamic> payload,
  }) {
    final existingIdx = _syncQueue.indexWhere((e) => e.idempotencyKey == idempotencyKey);
    if (existingIdx < 0) {
      _syncQueue.add(DurableSyncEvent(
        id: const Uuid().v4(),
        idempotencyKey: idempotencyKey,
        eventType: eventType,
        payload: payload,
        createdAt: DateTime.now(),
      ));
      _notifyChanged();
    }
  }

  List<DurableSyncEvent> getPendingSyncEvents() => List.unmodifiable(_syncQueue);

  void markSyncEventAcknowledged(String idempotencyKey) {
    _syncQueue.removeWhere((e) => e.idempotencyKey == idempotencyKey);
    _notifyChanged();
  }

  void incrementSyncEventRetry(String idempotencyKey) {
    final idx = _syncQueue.indexWhere((e) => e.idempotencyKey == idempotencyKey);
    if (idx >= 0) {
      final ev = _syncQueue[idx];
      _syncQueue[idx] = DurableSyncEvent(
        id: ev.id,
        idempotencyKey: ev.idempotencyKey,
        eventType: ev.eventType,
        payload: ev.payload,
        retryCount: ev.retryCount + 1,
        lastAttemptAt: DateTime.now(),
        createdAt: ev.createdAt,
      );
      _notifyChanged();
    }
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
    _healthLogs.clear();
    _syncQueue.clear();
    _eventLogs.clear();
    _streak = LocalStreak();
    _feedbackList.clear();
    _revision = 1;
    _lastSavedAt = DateTime.now();
    initializeDefaultTemplates();
    _notifyChanged(immediate: true);
  }
}

