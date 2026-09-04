// Habitat Home Page - Complete UI/UX Vertical Slice Implementation
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../application/home_controller.dart';
import '../../domain/models/home_state_model.dart';
import '../../domain/services/home_service.dart';
import '../widgets/current_action_card.dart';
import '../widgets/health_summary.dart';
import '../widgets/home_header.dart';
import '../widgets/progress_summary.dart';
import '../widgets/quick_actions.dart';
import '../widgets/streak_summary.dart';
import '../widgets/today_summary.dart';
import '../widgets/upcoming_tasks.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onOpenTasks;
  final VoidCallback? onOpenHealth;
  final VoidCallback? onOpenProgress;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenNotifications;
  final HomeController? controller;

  const HomePage({
    super.key,
    this.onOpenTasks,
    this.onOpenHealth,
    this.onOpenProgress,
    this.onOpenProfile,
    this.onOpenNotifications,
    this.controller,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _controller;
  bool _internalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      final db = LocalDatabase.instance;
      _controller = HomeController(
        service: HomeService(db),
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
        final status = _controller.status;

        if (status == HomeLoadStatus.loading ||
            status == HomeLoadStatus.initial) {
          return const Scaffold(
            backgroundColor: HabitatTheme.background,
            body: Center(
              child: CircularProgressIndicator(
                color: HabitatTheme.growthGreen,
              ),
            ),
          );
        }

        if (status == HomeLoadStatus.error || _controller.model == null) {
          return Scaffold(
            backgroundColor: HabitatTheme.background,
            body: Center(
              child: Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        size: 48,
                        color: HabitatTheme.youngLeaf,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _controller.errorMessage ?? 'Home is unavailable.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: HabitatTheme.fontHeading,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _controller.load,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HabitatTheme.growthGreen,
                          foregroundColor: HabitatTheme.forest,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final model = _controller.model!;

        if (status == HomeLoadStatus.empty) {
          return _buildEmptyHomeScaffold(model);
        }

        return _HomeDashboardView(
          model: model,
          onRefresh: () async => _controller.refresh(),
          onOpenTasks: widget.onOpenTasks,
          onOpenHealth: widget.onOpenHealth,
          onOpenProgress: widget.onOpenProgress,
          onOpenProfile: widget.onOpenProfile,
          onOpenNotifications: widget.onOpenNotifications,
          onLogWater: () => _controller.logWater(250),
          onLogMeal: _controller.logMeal,
          onToggleNap: _controller.toggleNap,
          onCreateFirstTask: _controller.createFirstTask,
          onStartAction: (action) => _openAction(action),
        );
      },
    );
  }

  Widget _buildEmptyHomeScaffold(HomeStateModel model) {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHeader(
                user: model.user,
                notifications: model.notifications,
                onOpenNotifications: widget.onOpenNotifications,
                onOpenProfile: widget.onOpenProfile,
              ),
              const Spacer(),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: HabitatTheme.surfacePrimary,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: HabitatTheme.surfaceBorder),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.spa,
                        size: 64,
                        color: HabitatTheme.growthGreen,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'WELCOME TO HABITAT',
                        style: TextStyle(
                          fontFamily: HabitatTheme.fontHeading,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create your first daily discipline\nand start building your routine.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: HabitatTheme.fontBody,
                          fontSize: 13,
                          color: HabitatTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _controller.createFirstTask,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(
                            'Create First Task',
                            style: TextStyle(
                              fontFamily: HabitatTheme.fontHeading,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HabitatTheme.growthGreen,
                            foregroundColor: HabitatTheme.forest,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAction(CurrentAction action) async {
    final attemptId = _controller.startAction(action.taskId);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HomeActionExecutionPage(
          action: action,
          onComplete: () {
            _controller.completeAction(attemptId, action.taskId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✓ Completed ${action.title}! +25 XP awarded.',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                backgroundColor: HabitatTheme.surfacePrimary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeDashboardView extends StatelessWidget {
  final HomeStateModel model;
  final Future<void> Function() onRefresh;
  final VoidCallback? onOpenTasks;
  final VoidCallback? onOpenHealth;
  final VoidCallback? onOpenProgress;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenNotifications;
  final VoidCallback onLogWater;
  final VoidCallback onLogMeal;
  final VoidCallback onToggleNap;
  final VoidCallback onCreateFirstTask;
  final ValueChanged<CurrentAction> onStartAction;

  const _HomeDashboardView({
    required this.model,
    required this.onRefresh,
    required this.onOpenTasks,
    required this.onOpenHealth,
    required this.onOpenProgress,
    required this.onOpenProfile,
    required this.onOpenNotifications,
    required this.onLogWater,
    required this.onLogMeal,
    required this.onToggleNap,
    required this.onCreateFirstTask,
    required this.onStartAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: onRefresh,
          color: HabitatTheme.growthGreen,
          backgroundColor: HabitatTheme.surfacePrimary,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 840;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                children: [
                  // 1. Home Header
                  HomeHeader(
                    user: model.user,
                    notifications: model.notifications,
                    onOpenNotifications: onOpenNotifications,
                    onOpenProfile: onOpenProfile,
                  ),
                  const SizedBox(height: 20),

                  // 2. Responsive Dashboard Body
                  if (isWide) _buildWideLayout() else _buildMobileLayout(),

                  const SizedBox(height: 28),

                  // 3. Calm Brand Motto Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: HabitatTheme.surfacePrimary,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: HabitatTheme.surfaceBorder,
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.eco,
                            size: 14,
                            color: HabitatTheme.growthGreen,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'YOUR HABITAT. YOUR ACTIONS. YOUR GROWTH.',
                            style: TextStyle(
                              fontFamily: HabitatTheme.fontHeading,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: HabitatTheme.youngLeaf,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Mobile Single-Column Flow
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // 01 — CURRENT ACTION (Hero)
        CurrentActionCard(
          action: model.currentAction,
          onStart: onStartAction,
          onOpenTasks: onOpenTasks,
          onCreateFirstTask: onCreateFirstTask,
        ),
        const SizedBox(height: 16),

        // 02 — TODAY'S OVERVIEW
        TodaySummaryCard(
          summary: model.dailyProgress,
          onOpenTasks: onOpenTasks,
        ),
        const SizedBox(height: 16),

        // 03 — UPCOMING TASKS
        UpcomingTasksCard(
          tasks: model.upcomingTasks,
          onOpenTasks: onOpenTasks,
        ),
        const SizedBox(height: 16),

        // 04 — DAILY PROGRESS
        ProgressSummaryCard(
          summary: model.dailyProgress,
          streak: model.streak,
          onOpenProgress: onOpenProgress,
        ),
        const SizedBox(height: 16),

        // 05 — HEALTH SNAPSHOT
        HealthSummaryCard(
          summary: model.health,
          onOpenHealth: onOpenHealth,
        ),
        const SizedBox(height: 16),

        // 06 — STREAK SNAPSHOT
        StreakCard(
          summary: model.streak,
          onOpenProgress: onOpenProgress,
        ),
        const SizedBox(height: 16),

        // 07 — QUICK ACTIONS
        QuickActionBar(
          onLogWater: onLogWater,
          onLogMeal: onLogMeal,
          onToggleNap: onToggleNap,
          onAddTask: onOpenTasks,
          napRunning: model.health.napRunning,
        ),
      ],
    );
  }

  // Wide Multi-Column Flow (Web / Tablet)
  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column (Hero Action & Quick Actions & Health)
        Expanded(
          flex: 5,
          child: Column(
            children: [
              CurrentActionCard(
                action: model.currentAction,
                onStart: onStartAction,
                onOpenTasks: onOpenTasks,
                onCreateFirstTask: onCreateFirstTask,
              ),
              const SizedBox(height: 16),
              TodaySummaryCard(
                summary: model.dailyProgress,
                onOpenTasks: onOpenTasks,
              ),
              const SizedBox(height: 16),
              QuickActionBar(
                onLogWater: onLogWater,
                onLogMeal: onLogMeal,
                onToggleNap: onToggleNap,
                onAddTask: onOpenTasks,
                napRunning: model.health.napRunning,
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),

        // Right Column (Upcoming, Progress, Health, Streak)
        Expanded(
          flex: 5,
          child: Column(
            children: [
              UpcomingTasksCard(
                tasks: model.upcomingTasks,
                onOpenTasks: onOpenTasks,
              ),
              const SizedBox(height: 16),
              ProgressSummaryCard(
                summary: model.dailyProgress,
                streak: model.streak,
                onOpenProgress: onOpenProgress,
              ),
              const SizedBox(height: 16),
              HealthSummaryCard(
                summary: model.health,
                onOpenHealth: onOpenHealth,
              ),
              const SizedBox(height: 16),
              StreakCard(
                summary: model.streak,
                onOpenProgress: onOpenProgress,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HomeActionExecutionPage extends StatelessWidget {
  final CurrentAction action;
  final VoidCallback onComplete;

  const HomeActionExecutionPage({
    super.key,
    required this.action,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('EXECUTE DISCIPLINE'),
        backgroundColor: HabitatTheme.background,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Tag
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: HabitatTheme.habitatGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  action.category,
                  style: const TextStyle(
                    fontFamily: HabitatTheme.fontHeading,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: HabitatTheme.growthGreen,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Instruction
              Text(
                action.title,
                style: const TextStyle(
                  fontFamily: HabitatTheme.fontHeading,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                action.detail,
                style: const TextStyle(
                  fontFamily: HabitatTheme.fontBody,
                  fontSize: 14,
                  color: HabitatTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Proof Requirement Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HabitatTheme.surfacePrimary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: HabitatTheme.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: HabitatTheme.habitatGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        action.taskType == 'VIDEO'
                            ? Icons.videocam_outlined
                            : Icons.camera_alt_outlined,
                        color: HabitatTheme.growthGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${action.taskType} VERIFICATION',
                          style: const TextStyle(
                            fontFamily: HabitatTheme.fontHeading,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Anti-cheat proof validation active',
                          style: TextStyle(
                            fontFamily: HabitatTheme.fontBody,
                            fontSize: 11,
                            color: HabitatTheme.youngLeaf,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Primary Complete CTA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    onComplete();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.check_circle, size: 20),
                  label: const Text(
                    'COMPLETE DISCIPLINE',
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HabitatTheme.growthGreen,
                    foregroundColor: HabitatTheme.forest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
