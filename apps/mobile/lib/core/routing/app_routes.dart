// Habitat Centralized Route Definitions & Deep-Linking Architecture
abstract final class AppRoutes {
  static const String home = '/';
  
  // Tasks Domain
  static const String tasks = '/tasks';
  static const String taskCreate = '/tasks/create';
  static const String taskDetail = '/tasks/:id';
  static const String taskAction = '/tasks/:id/action';

  // Alarms Domain
  static const String alarms = '/alarms';
  static const String alarmCreate = '/alarms/create';
  static const String alarmDetail = '/alarms/:id';
  static const String alarmRinging = '/alarms/:id/ringing';

  // Health Domain
  static const String health = '/health';
  static const String healthWater = '/health/water';
  static const String healthMeals = '/health/meals';
  static const String healthNaps = '/health/naps';
  static const String healthHistory = '/health/history';

  // Progress Domain
  static const String progress = '/progress';
  static const String progressStreak = '/progress/streak';
  static const String progressAchievements = '/progress/achievements';
  static const String progressHistory = '/progress/history';

  // Profile & Settings Domain
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String profilePreferences = '/profile/preferences';
  static const String profileNotifications = '/profile/notifications';
  static const String profileAppearance = '/profile/appearance';
  static const String profilePrivacy = '/profile/privacy';
  static const String profileSecurity = '/profile/security';
  static const String profilePermissions = '/profile/permissions';
  static const String profileDataStorage = '/profile/data-storage';
  static const String profileHelp = '/profile/help';
  static const String profileAbout = '/profile/about';
}
