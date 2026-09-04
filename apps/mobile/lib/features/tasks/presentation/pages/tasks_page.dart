// Habitat Main Tasks Operational Control Center Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../application/task_controller.dart';
import '../../domain/models/task_model.dart';
import '../../domain/services/task_service.dart';
import '../widgets/task_card.dart';
import 'create_task_page.dart';
import 'task_details_page.dart';
import 'task_execution_page.dart';

class TasksPage extends StatefulWidget {
  final TaskController? controller;

  const TasksPage({super.key, this.controller});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late final TaskController _controller;
  bool _internalController = false;

  final List<String> _filters = [
    'ALL',
    'ACTIVE',
    'SCHEDULED',
    'COMPLETED',
    'MISSED',
    'ARCHIVED',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      final db = LocalDatabase.instance;
      _controller = TaskController(
        taskService: TaskService(db),
        database: db,
      );
      _internalController = true;
    }
    _controller.load();
  }

  @override
  void dispose() {
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final tasks = _controller.tasks;

        return Scaffold(
          backgroundColor: HabitatTheme.background,
          appBar: AppBar(
            title: const Text('DISCIPLINE TASKS'),
            backgroundColor: HabitatTheme.background,
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: HabitatTheme.growthGreen),
                tooltip: 'Create Task',
                onPressed: _openCreateTask,
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _controller.activeFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          selectedColor: HabitatTheme.growthGreen,
                          backgroundColor: HabitatTheme.surfacePrimary,
                          labelStyle: TextStyle(
                            fontFamily: HabitatTheme.fontHeading,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color:
                                isSelected ? HabitatTheme.forest : Colors.white,
                          ),
                          onSelected: (_) => _controller.setFilter(filter),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),

                // 2. Tasks List or Empty State
                Expanded(
                  child: tasks.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return TaskCard(
                              task: task,
                              onTap: () => _openTaskDetails(task),
                              onStart: () => _startTask(task),
                              onTogglePause: () =>
                                  task.status == TaskStatus.paused
                                      ? _controller.resumeTask(task.id)
                                      : _controller.pauseTask(task.id),
                              onArchive: () => _controller.archiveTask(task.id),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: HabitatTheme.growthGreen,
            foregroundColor: HabitatTheme.forest,
            icon: const Icon(Icons.add),
            label: const Text(
              'CREATE TASK',
              style: TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            onPressed: _openCreateTask,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.checklist_rtl,
                size: 56, color: HabitatTheme.youngLeaf),
            const SizedBox(height: 16),
            Text(
              'NO ${_controller.activeFilter} TASKS',
              style: const TextStyle(
                fontFamily: HabitatTheme.fontHeading,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Create a task and schedule your daily wake-up protocol.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: HabitatTheme.fontBody,
                fontSize: 13,
                color: HabitatTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openCreateTask,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create First Task'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HabitatTheme.growthGreen,
                foregroundColor: HabitatTheme.forest,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateTask() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateTaskPage()),
    );
  }

  void _openTaskDetails(TaskModel task) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskDetailsPage(task: task)),
    );
  }

  void _startTask(TaskModel task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskExecutionPage(
          taskId: task.id,
          taskTitle: task.title,
          proofType: task.action.type.name.toUpperCase(),
        ),
      ),
    );
  }
}
