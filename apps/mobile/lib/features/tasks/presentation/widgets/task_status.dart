// Habitat Standardized Task Status Badge
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/task_model.dart';

class TaskStatusBadge extends StatelessWidget {
  final TaskStatus status;

  const TaskStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      TaskStatus.active => (
          'IN PROGRESS',
          HabitatTheme.growthGreen,
          HabitatTheme.habitatGreen
        ),
      TaskStatus.ready => (
          'READY',
          HabitatTheme.growthGreen,
          HabitatTheme.habitatGreen
        ),
      TaskStatus.completed => (
          'COMPLETED',
          HabitatTheme.youngLeaf,
          HabitatTheme.surfaceSecondary
        ),
      TaskStatus.scheduled => (
          'SCHEDULED',
          HabitatTheme.youngLeaf,
          HabitatTheme.surfaceSecondary
        ),
      TaskStatus.failed || TaskStatus.missed => (
          'MISSED',
          Colors.redAccent,
          Colors.red.withOpacity(0.2)
        ),
      TaskStatus.paused => (
          'PAUSED',
          HabitatTheme.textMuted,
          HabitatTheme.surfaceSecondary
        ),
      TaskStatus.archived => (
          'ARCHIVED',
          HabitatTheme.textMuted,
          HabitatTheme.surfaceSecondary
        ),
      TaskStatus.draft => (
          'DRAFT',
          HabitatTheme.textMuted,
          HabitatTheme.surfaceSecondary
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: HabitatTheme.fontHeading,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}
