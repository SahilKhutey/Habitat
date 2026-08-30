// Tactical Daily Planner & Routine Timeline Screen
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class PlannerScreen extends StatelessWidget {
  final String dateTitle;
  final bool isRestDay;
  final List<Map<String, dynamic>> routines;
  final List<Map<String, dynamic>> missions;
  final List<Map<String, dynamic>> conflicts;

  const PlannerScreen({
    super.key,
    this.dateTitle = 'Thursday, Aug 27',
    this.isRestDay = false,
    this.routines = const [
      {
        'id': 'routine-morning-1',
        'name': 'Morning Discipline',
        'time': '07:00',
        'tasks': ['Wake-up photo', 'Brush teeth', '10 Pushups', 'Outside photo']
      },
      {
        'id': 'routine-study-1',
        'name': 'Deep Work Protocol',
        'time': '10:00',
        'tasks': ['25-minute focus session']
      },
      {
        'id': 'routine-evening-1',
        'name': 'Evening Reset',
        'time': '21:30',
        'tasks': ['Room reset', 'Prepare tomorrow']
      }
    ],
    this.missions = const [
      {'time': '07:00', 'name': 'Morning Sunlight Photo', 'status': 'COMPLETED'},
      {'time': '07:05', 'name': 'Hydration 500ml', 'status': 'COMPLETED'},
      {'time': '07:10', 'name': '10 Push-Ups Video', 'status': 'PENDING'},
      {'time': '10:00', 'name': 'Deep Focus Block', 'status': 'PENDING'},
    ],
    this.conflicts = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E11),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'TACTICAL PLANNER',
          style: AppTypography.titleSmall.copyWith(letterSpacing: 2.0),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TODAY', style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text(dateTitle, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (isRestDay)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cyanDiscovery.withOpacity(0.2),
                        borderRadius: AppRadii.radiusMedium,
                        border: Border.all(color: AppColors.cyanDiscovery),
                      ),
                      child: const Text('REST DAY', style: TextStyle(color: AppColors.cyanDiscovery, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Timeline List
              Expanded(
                child: ListView.separated(
                  itemCount: routines.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
                  itemBuilder: (context, index) {
                    final r = routines[index];
                    final tasks = (r['tasks'] as List<dynamic>?) ?? [];

                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15181E),
                        borderRadius: AppRadii.radiusLarge,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(r['time'] as String, style: const TextStyle(color: AppColors.amberFocus, fontWeight: FontWeight.bold, fontSize: 14)),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(r['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 8),
                          ...tasks.map((t) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: AppColors.emeraldVictory, size: 16),
                                    const SizedBox(width: 8),
                                    Text(t.toString(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
