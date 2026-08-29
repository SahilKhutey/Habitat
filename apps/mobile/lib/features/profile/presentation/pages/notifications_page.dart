// Habitat Notification Settings Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../domain/models/notification_settings.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/services/settings_service.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final SettingsService _settingsService;
  late NotificationSettingsModel _notifications;

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService(ProfileRepository(LocalDatabase.instance));
    _notifications = _settingsService.getNotificationSettings();
  }

  void _update(NotificationSettingsModel updated) {
    setState(() => _notifications = updated);
    _settingsService.updateNotificationSettings(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('NOTIFICATIONS'),
        backgroundColor: HabitatTheme.background,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SettingsSection(
              title: 'HABITAT ALERTS',
              children: [
                SettingsTile(
                  icon: Icons.checklist_outlined,
                  title: 'Task Reminders',
                  subtitle: 'Scheduled cue reminders before alarm triggers',
                  toggleValue: _notifications.taskRemindersEnabled,
                  onToggleChanged: (val) => _update(_notifications.copyWith(taskRemindersEnabled: val)),
                ),
                SettingsTile(
                  icon: Icons.alarm_on_outlined,
                  title: 'Alarm Notifications',
                  subtitle: 'High-priority discipline alarm notifications',
                  toggleValue: _notifications.alarmNotificationsEnabled,
                  onToggleChanged: (val) => _update(_notifications.copyWith(alarmNotificationsEnabled: val)),
                ),
                SettingsTile(
                  icon: Icons.trending_up,
                  title: 'Daily Progress Updates',
                  subtitle: 'Evening reflection and completion summary',
                  toggleValue: _notifications.progressUpdatesEnabled,
                  onToggleChanged: (val) => _update(_notifications.copyWith(progressUpdatesEnabled: val)),
                ),
                SettingsTile(
                  icon: Icons.emoji_events_outlined,
                  title: 'Achievement Alerts',
                  subtitle: 'Instant toast when milestone rewards unlock',
                  toggleValue: _notifications.achievementAlertsEnabled,
                  onToggleChanged: (val) => _update(_notifications.copyWith(achievementAlertsEnabled: val)),
                ),
              ],
            ),
            SettingsSection(
              title: 'QUIET HOURS',
              children: [
                SettingsTile(
                  icon: Icons.bedtime_outlined,
                  title: 'Enable Quiet Hours',
                  subtitle: _notifications.quietHoursEnabled
                      ? '${_notifications.quietHoursStart} - ${_notifications.quietHoursEnd}'
                      : 'Disabled',
                  toggleValue: _notifications.quietHoursEnabled,
                  onToggleChanged: (val) => _update(_notifications.copyWith(quietHoursEnabled: val)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
