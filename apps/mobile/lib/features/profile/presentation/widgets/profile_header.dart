// Habitat Profile Header Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/user_profile.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfileModel user;
  final VoidCallback? onEdit;

  const ProfileHeader({
    super.key,
    required this.user,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HabitatTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: HabitatTheme.surfaceBorder),
      ),
      child: Row(
        children: [
          // User Avatar
          CircleAvatar(
            radius: 32,
            backgroundColor: HabitatTheme.habitatGreen,
            child: const Icon(Icons.person, color: HabitatTheme.growthGreen, size: 36),
          ),
          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontFamily: HabitatTheme.fontHeading,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.bio,
                  style: const TextStyle(
                    fontFamily: HabitatTheme.fontBody,
                    fontSize: 12,
                    color: HabitatTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: HabitatTheme.habitatGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Discipline Level: ${user.disciplineLevel}',
                    style: const TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: HabitatTheme.growthGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: HabitatTheme.growthGreen, size: 20),
              tooltip: 'Edit Profile',
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }
}
