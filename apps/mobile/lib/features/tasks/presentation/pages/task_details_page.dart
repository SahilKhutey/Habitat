// Habitat Task Details Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../domain/models/task_model.dart';
import '../../domain/services/task_service.dart';
import '../widgets/task_status.dart';
import 'task_execution_page.dart';

class TaskDetailsPage extends StatefulWidget {
  final TaskModel task;

  const TaskDetailsPage({super.key, required this.task});

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  late TaskModel _task;
  late final TaskService _taskService;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _taskService = TaskService(LocalDatabase.instance);
  }

  void _togglePause() {
    if (_task.status == TaskStatus.paused) {
      _taskService.resumeTask(_task.id);
      setState(() => _task = _task.copyWith(status: TaskStatus.ready, active: true));
    } else {
      _taskService.pauseTask(_task.id);
      setState(() => _task = _task.copyWith(status: TaskStatus.paused, active: false));
    }
  }

  void _archiveTask() {
    _taskService.archiveTask(_task.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task archived. Historical logs preserved.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _task.status == TaskStatus.ready || _task.status == TaskStatus.active;
    final isCompleted = _task.status == TaskStatus.completed;

    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('DISCIPLINE SPECIFICATION'),
        backgroundColor: HabitatTheme.background,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: HabitatTheme.surfacePrimary,
            onSelected: (val) {
              if (val == 'pause') _togglePause();
              if (val == 'archive') _archiveTask();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'pause',
                child: Text(_task.status == TaskStatus.paused ? 'Resume Task' : 'Pause Task'),
              ),
              const PopupMenuItem(
                value: 'archive',
                child: Text('Archive Task'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Status & XP Reward Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TaskStatusBadge(status: _task.status),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: HabitatTheme.growthGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${_task.baseXp} XP REWARD',
                      style: const TextStyle(
                        fontFamily: HabitatTheme.fontHeading,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: HabitatTheme.growthGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 2. Title & Description
              Text(
                _task.title,
                style: const TextStyle(
                  fontFamily: HabitatTheme.fontHeading,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (_task.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _task.description,
                  style: const TextStyle(
                    fontFamily: HabitatTheme.fontBody,
                    fontSize: 13,
                    color: HabitatTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // 3. Schedule & Alarm Specification Card
              _buildSpecCard(
                title: 'SCHEDULE & REMINDER',
                icon: Icons.access_time,
                items: [
                  _buildSpecRow('Trigger Time', _task.schedule.timeOfDay),
                  _buildSpecRow('Recurrence', _task.schedule.recurrenceDisplayName),
                  _buildSpecRow(
                    'Alarm State',
                    _task.alarm != null && _task.alarm!.isEnabled ? 'Armed (Native Wake-up)' : 'Disabled',
                    valueColor: _task.alarm != null && _task.alarm!.isEnabled ? HabitatTheme.growthGreen : HabitatTheme.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 4. Action & Proof Evidence Card
              _buildSpecCard(
                title: 'ACTION & PROOF EVIDENCE',
                icon: Icons.shield_outlined,
                items: [
                  _buildSpecRow('Action Type', _task.action.typeDisplayName),
                  _buildSpecRow('Instruction', _task.action.instruction),
                  _buildSpecRow('Verification', 'Anti-Cheat Camera Validation Active'),
                ],
              ),
              const SizedBox(height: 14),

              // 5. 5-Minute Escalation Retry Card
              _buildSpecCard(
                title: 'ESCALATION RETRY PROTOCOL',
                icon: Icons.replay,
                items: [
                  _buildSpecRow('Escalation Interval', '${_task.retryRules.retryIntervalMinutes} Minutes'),
                  _buildSpecRow('Max Retries', '${_task.retryRules.maxAttempts} Attempts'),
                  _buildSpecRow('Policy on Max Fail', 'Mark Missed & Record History'),
                ],
              ),
              const SizedBox(height: 28),

              // 6. Dominant Primary CTA
              if (isReady)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TaskExecutionPage(
                            taskId: _task.id,
                            taskTitle: _task.title,
                            proofType: _task.action.type.name.toUpperCase(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: const Text(
                      'START DISCIPLINE ACTION',
                      style: TextStyle(
                        fontFamily: HabitatTheme.fontHeading,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HabitatTheme.growthGreen,
                      foregroundColor: HabitatTheme.forest,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                )
              else if (isCompleted)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: HabitatTheme.surfacePrimary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: HabitatTheme.growthGreen.withOpacity(0.4)),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '✓ Completed For Today',
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontWeight: FontWeight.w700,
                      color: HabitatTheme.growthGreen,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecCard({
    required String title,
    required IconData icon,
    required List<Widget> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HabitatTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HabitatTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: HabitatTheme.youngLeaf),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: HabitatTheme.fontHeading,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: HabitatTheme.youngLeaf,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: HabitatTheme.fontBody,
              fontSize: 12,
              color: HabitatTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: valueColor ?? Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
