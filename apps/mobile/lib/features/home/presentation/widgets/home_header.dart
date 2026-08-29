// Habitat Home Header Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/home_state_model.dart';

class HomeHeader extends StatelessWidget {
  final HomeUserSummary user;
  final NotificationSummary notifications;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenProfile;

  const HomeHeader({
    super.key,
    required this.user,
    required this.notifications,
    this.onOpenNotifications,
    this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        MaterialLocalizations.of(context).formatMediumDate(user.date);

    return Semantics(
      header: true,
      label: '${user.greeting}, ${user.displayName}. $formattedDate',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Date Context
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.greeting},',
                  style: const TextStyle(
                    fontFamily: HabitatTheme.fontBody,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: HabitatTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontFamily: HabitatTheme.fontHeading,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: HabitatTheme.youngLeaf,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontFamily: HabitatTheme.fontBody,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: HabitatTheme.youngLeaf,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Header Quick Actions: Notification & Profile
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Notification Bell with Badge
              Semantics(
                button: true,
                label:
                    'Notifications: ${notifications.enabledAlarmCount} active reminders',
                child: Container(
                  decoration: BoxDecoration(
                    color: HabitatTheme.surfacePrimary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: HabitatTheme.surfaceBorder),
                  ),
                  child: IconButton(
                    icon: Badge(
                      isLabelVisible: notifications.enabledAlarmCount > 0,
                      label: Text(
                        '${notifications.enabledAlarmCount}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: HabitatTheme.forest,
                        ),
                      ),
                      backgroundColor: HabitatTheme.growthGreen,
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: HabitatTheme.growthGreen,
                        size: 22,
                      ),
                    ),
                    tooltip: 'Active Alarms & Reminders',
                    onPressed: onOpenNotifications,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Profile Avatar Shortcut
              Semantics(
                button: true,
                label: 'Open user profile',
                child: Container(
                  decoration: BoxDecoration(
                    color: HabitatTheme.surfacePrimary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: HabitatTheme.surfaceBorder),
                  ),
                  child: IconButton(
                    icon: const CircleAvatar(
                      radius: 13,
                      backgroundColor: HabitatTheme.habitatGreen,
                      child: Icon(
                        Icons.person,
                        color: HabitatTheme.growthGreen,
                        size: 16,
                      ),
                    ),
                    tooltip: 'Profile & Settings',
                    onPressed: onOpenProfile,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
