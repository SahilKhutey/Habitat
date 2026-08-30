// Task Detail & Lifecycle Management Screen
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.task['status'] as String? ?? 'ACTIVE';
  }

  void _togglePause() {
    setState(() {
      _status = _status == 'ACTIVE' ? 'PAUSED' : 'ACTIVE';
    });
    AppFeedback.showToast(context, message: 'Task status updated to $_status');
  }

  void _archiveTask() {
    AppDialog.show(
      context,
      title: 'ARCHIVE TASK?',
      content: 'Archiving removes this task from active alarm scheduling. All past completed missions and XP will be preserved forever.',
      confirmLabel: 'ARCHIVE',
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() => _status = 'ARCHIVED');
        AppFeedback.showToast(context, message: 'Task archived. Historical data preserved.');
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('TASK PROTOCOL'),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'Archive Task',
            onPressed: _archiveTask,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MissionStatusBadge(status: _status),
                Text(
                  '+${widget.task['xpReward'] ?? 30} XP REWARD',
                  style: const TextStyle(color: AppColors.emeraldVictory, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(widget.task['name'] as String? ?? 'Task Title', style: AppTypography.displayMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.task['description'] as String? ?? 'Execute strict repetitions upon alarm firing.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Rules Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TASK RULES & PROOF SPECIFICATION', style: AppTypography.labelMedium),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Proof Evidence:', style: AppTypography.bodySmall),
                      Text(widget.task['proofType'] as String? ?? 'VIDEO', style: AppTypography.titleSmall),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Difficulty Rating:', style: AppTypography.bodySmall),
                      Text('Level ${widget.task['difficulty'] ?? 2} / 5', style: AppTypography.titleSmall),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated Duration:', style: AppTypography.bodySmall),
                      const Text('60 Seconds', style: AppTypography.titleSmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Action Buttons
            AppButton.outline(
              label: _status == 'ACTIVE' ? 'PAUSE TASK SCHEDULING' : 'RESUME TASK SCHEDULING',
              icon: _status == 'ACTIVE' ? Icons.pause : Icons.play_arrow,
              onPressed: _togglePause,
            ),
          ],
        ),
      ),
    );
  }
}
