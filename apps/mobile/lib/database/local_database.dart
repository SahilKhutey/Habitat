// Phase 19 Local-First SQLite Database Engine & Data Access Objects
import 'dart:async';
import 'package:uuid/uuid.dart';

class LocalUser {
  final String id;
  final String displayName;
  final String timezone;
  final DateTime createdAt;

  LocalUser({
    required this.id,
    required this.displayName,
    required this.timezone,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'displayName': displayName,
    'timezone': timezone,
    'createdAt': createdAt.toIso8601String(),
  };

  factory LocalUser.fromMap(Map<String, dynamic> map) => LocalUser(
    id: map['id'],
    displayName: map['displayName'],
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
  LocalStreak _streak = LocalStreak();
  final List<LocalFeedback> _feedbackList = [];

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

  // Tasks & Alarms
  List<LocalTask> getAllTasks() => _tasks.values.toList();
  LocalTask? getTask(String id) => _tasks[id];
  void saveTask(LocalTask task) => _tasks[task.id] = task;

  List<LocalAlarm> getAllAlarms() => _alarms.values.toList();
  void saveAlarm(LocalAlarm alarm) => _alarms[alarm.id] = alarm;

  // Attempts
  void recordAttempt(LocalTaskAttempt attempt) => _attempts.add(attempt);
  List<LocalTaskAttempt> getAttemptsForTask(String taskId) =>
      _attempts.where((a) => a.taskId == taskId).toList();

  // Proofs
  void recordProof(LocalProof proof) => _proofs.add(proof);
  List<LocalProof> getProofsForTask(String taskId) =>
      _proofs.where((p) => p.taskId == taskId).toList();

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
  }

  LocalStreak getStreak() => _streak;

  // Feedback
  void addFeedback(LocalFeedback fb) => _feedbackList.add(fb);
  List<LocalFeedback> getAllFeedback() => List.unmodifiable(_feedbackList);

  // Reset MVP
  void resetAllData() {
    _currentUser = null;
    _tasks.clear();
    _alarms.clear();
    _attempts.clear();
    _proofs.clear();
    _xpEvents.clear();
    _streak = LocalStreak();
    _feedbackList.clear();
    initializeDefaultTemplates();
  }
}
