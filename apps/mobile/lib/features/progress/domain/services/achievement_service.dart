// Habitat Declarative Achievement Evaluation Service
import '../models/achievement_model.dart';
import '../repositories/progress_repository.dart';

class AchievementService {
  final ProgressRepository _repository;

  static const List<Map<String, dynamic>> _definitions = [
    {
      'id': 'ach-1',
      'code': 'FIRST_STEP',
      'name': 'First Victory',
      'description': 'Completed your very first discipline commitment',
      'category': AchievementCategory.tasks,
      'iconName': 'emoji_events',
      'xpReward': 50,
      'reqType': 'TASK_COUNT',
      'target': 1,
    },
    {
      'id': 'ach-2',
      'code': 'IRON_MOMENTUM',
      'name': 'Iron Momentum',
      'description': 'Maintained a 7-day unbroken discipline streak',
      'category': AchievementCategory.streaks,
      'iconName': 'local_fire_department',
      'xpReward': 150,
      'reqType': 'STREAK',
      'target': 7,
    },
    {
      'id': 'ach-3',
      'code': 'CONSISTENCY_MASTER',
      'name': 'Consistency Master',
      'description': 'Achieved 30 consecutive days of discipline execution',
      'category': AchievementCategory.streaks,
      'iconName': 'military_tech',
      'xpReward': 500,
      'reqType': 'STREAK',
      'target': 30,
    },
    {
      'id': 'ach-4',
      'code': 'CENTURION',
      'name': 'Centurion of Habit',
      'description': 'Completed 100 discipline actions successfully',
      'category': AchievementCategory.tasks,
      'iconName': 'stars',
      'xpReward': 300,
      'reqType': 'TASK_COUNT',
      'target': 100,
    },
    {
      'id': 'ach-5',
      'code': 'SPEED_DEMON',
      'name': 'Dawn Sovereign',
      'description': 'Executed a task with +50% Instant Action Speed Bonus',
      'category': AchievementCategory.speed,
      'iconName': 'bolt',
      'xpReward': 100,
      'reqType': 'SPEED',
      'target': 1,
    },
    {
      'id': 'ach-6',
      'code': 'HYDRATION_HERO',
      'name': 'Hydration Hero',
      'description': 'Logged your first water intake entry',
      'category': AchievementCategory.health,
      'iconName': 'water_drop',
      'xpReward': 50,
      'reqType': 'HEALTH_WATER',
      'target': 1,
    },
    {
      'id': 'ach-7',
      'code': 'REST_RECOVERY',
      'name': 'Rest & Recovery',
      'description': 'Completed a restorative recovery nap session',
      'category': AchievementCategory.health,
      'iconName': 'bedtime',
      'xpReward': 50,
      'reqType': 'HEALTH_NAP',
      'target': 1,
    },
  ];

  AchievementService(this._repository);

  List<AchievementModel> getAllAchievements() {
    final unlockedCodes = _repository.getUnlockedAchievements();
    final allAttempts = _repository.getAllAttempts();
    final completedCount =
        allAttempts.where((a) => a.status == 'COMPLETED').length;
    final streak = _repository.getStreak();

    return _definitions.map((def) {
      final code = def['code'] as String;
      final isUnlocked = unlockedCodes.contains(code);
      final reqType = def['reqType'] as String;
      final target = def['target'] as int;

      double progress = 0.0;
      if (reqType == 'TASK_COUNT') {
        progress = (completedCount / target).clamp(0.0, 1.0);
      } else if (reqType == 'STREAK') {
        progress = (streak.currentStreak / target).clamp(0.0, 1.0);
      } else if (isUnlocked) {
        progress = 1.0;
      }

      return AchievementModel(
        id: def['id'] as String,
        code: code,
        name: def['name'] as String,
        description: def['description'] as String,
        category: def['category'] as AchievementCategory,
        iconName: def['iconName'] as String,
        xpReward: def['xpReward'] as int,
        isUnlocked: isUnlocked,
        progressPercent: isUnlocked ? 1.0 : progress,
      );
    }).toList();
  }

  void evaluateAndUnlock() {
    final unlocked = _repository.getUnlockedAchievements();
    final allAttempts = _repository.getAllAttempts();
    final completedCount =
        allAttempts.where((a) => a.status == 'COMPLETED').length;
    final streak = _repository.getStreak();

    for (final def in _definitions) {
      final code = def['code'] as String;
      if (unlocked.contains(code)) continue;

      final reqType = def['reqType'] as String;
      final target = def['target'] as int;
      bool qualifies = false;

      if (reqType == 'TASK_COUNT' && completedCount >= target) qualifies = true;
      if (reqType == 'STREAK' && streak.currentStreak >= target)
        qualifies = true;

      if (qualifies) {
        _repository.unlockAchievement(code);
        final reward = def['xpReward'] as int;
        _repository.awardXp(reward, 'Achievement Unlocked: ${def['name']}');
      }
    }
  }
}
