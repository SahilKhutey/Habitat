// Habitat Operational Alarms Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../application/alarm_controller.dart';
import '../../domain/services/alarm_service.dart';
import '../widgets/alarm_card.dart';
import 'create_task_page.dart';

class AlarmPage extends StatefulWidget {
  final AlarmController? controller;

  const AlarmPage({super.key, this.controller});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  late final AlarmController _controller;
  bool _internalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      final db = LocalDatabase.instance;
      _controller = AlarmController(
        alarmService: AlarmService(db),
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
        final alarms = _controller.alarms;
        final db = LocalDatabase.instance;

        return Scaffold(
          backgroundColor: HabitatTheme.background,
          appBar: AppBar(
            title: const Text('WAKE-UP PROTOCOLS'),
            backgroundColor: HabitatTheme.background,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Next Alarm Countdown Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: HabitatTheme.surfacePrimary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: HabitatTheme.growthGreen.withOpacity(0.5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.timer_outlined, color: HabitatTheme.growthGreen, size: 32),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ACTIVE WAKE-UP ENGINE',
                                style: TextStyle(
                                  fontFamily: HabitatTheme.fontHeading,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: HabitatTheme.youngLeaf,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Exact OS Alarms & 5-Min Escalation Armed',
                                style: TextStyle(
                                  fontFamily: HabitatTheme.fontHeading,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'ACTIVE ALARM COMMITMENTS',
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: HabitatTheme.youngLeaf,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (alarms.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: HabitatTheme.surfacePrimary,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: HabitatTheme.surfaceBorder),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'No wake-up alarms configured.',
                        style: TextStyle(color: HabitatTheme.textSecondary),
                      ),
                    )
                  else
                    ...alarms.map((alarm) {
                      final task = db.getTask(alarm.taskId);
                      return AlarmCard(
                        alarm: alarm,
                        taskTitle: task?.title ?? 'Discipline Task',
                        onToggle: (val) => _controller.toggleAlarm(alarm.id, val),
                      );
                    }),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: HabitatTheme.growthGreen,
            foregroundColor: HabitatTheme.forest,
            icon: const Icon(Icons.add_alarm),
            label: const Text(
              'SET NEW ALARM',
              style: TextStyle(fontFamily: HabitatTheme.fontHeading, fontWeight: FontWeight.w800),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateTaskPage()),
              );
            },
          ),
        );
      },
    );
  }
}
