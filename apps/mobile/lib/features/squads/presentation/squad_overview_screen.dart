// Social Discipline Squad Overview & Group Accountability Screen
import 'package:flutter/material.dart';
import '../../../core/theme/habitat_theme.dart';

class SquadOverviewScreen extends StatefulWidget {
  const SquadOverviewScreen({super.key});

  @override
  State<SquadOverviewScreen> createState() => _SquadOverviewScreenState();
}

class _SquadOverviewScreenState extends State<SquadOverviewScreen> {
  final List<Map<String, dynamic>> _members = [
    {
      'name': 'Alex Mercer (You)',
      'role': 'CAPTAIN',
      'status': 'COMPLETED',
      'time': '07:02 AM (1.2m resistance)',
      'streak': 12,
    },
    {
      'name': 'David Goggins',
      'role': 'WARRIOR',
      'status': 'COMPLETED',
      'time': '06:00 AM (0.5m resistance)',
      'streak': 48,
    },
    {
      'name': 'Sarah Connor',
      'role': 'WARRIOR',
      'status': 'COMPLETED',
      'time': '07:15 AM (2.1m resistance)',
      'streak': 19,
    },
    {
      'name': 'Marcus Vance',
      'role': 'WARRIOR',
      'status': 'SIREN_ACTIVE',
      'time': 'Alarm ringing for 4 mins',
      'streak': 8,
    },
  ];

  final List<String> _feed = [
    '⚡ You sent an urgent Wakeup Nudge to Marcus Vance!',
    '✅ Sarah Connor completed "Morning Sunlight" (+75 XP)',
    '🔥 David Goggins completed "100 Push-Ups" in 45s (+120 XP)',
    '✅ Alex Mercer completed "Make Your Bed" (+50 XP)',
  ];

  void _nudgeMember(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: HabitatTheme.crimsonAlert,
        content: Text('⚡ Wakeup Nudge dispatched to $name! Collective streak alert fired.'),
      ),
    );
    setState(() {
      _feed.insert(0, '⚡ You sent an urgent Wakeup Nudge to $name!');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('DISCIPLINE SQUAD'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: HabitatTheme.amberFocus),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Squad invite code copied: SPARTA26')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Squad Collective Streak Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: HabitatTheme.crimsonAlert.withOpacity(0.5), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('SPARTAN VANGUARD', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF261818), borderRadius: BorderRadius.circular(8)),
                        child: const Text('CODE: SPARTA26', style: TextStyle(color: HabitatTheme.amberFocus, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Text('🔥 24 DAYS', style: TextStyle(color: HabitatTheme.crimsonAlert, fontSize: 32, fontWeight: FontWeight.w900)),
                      SizedBox(width: 10),
                      Text('COLLECTIVE SQUAD STREAK', style: TextStyle(color: HabitatTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '100% squad completion required daily. If Marcus fails his morning mission, the 24-day collective streak collapses.',
                    style: TextStyle(color: HabitatTheme.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 2. Today's Squad Member Status List
            const Text("TODAY'S WARRIOR ROSTER (3/4 COMPLETED)", style: TextStyle(color: HabitatTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 12),

            ..._members.map((m) {
              final isDone = m['status'] == 'COMPLETED';
              final isSiren = m['status'] == 'SIREN_ACTIVE';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSiren ? HabitatTheme.surfaceSecondary : HabitatTheme.surfacePrimary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSiren ? HabitatTheme.crimsonAlert : HabitatTheme.surfaceBorder,
                    width: isSiren ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDone ? Icons.check_circle : (isSiren ? Icons.alarm_on : Icons.schedule),
                      color: isDone ? HabitatTheme.emeraldVictory : (isSiren ? HabitatTheme.crimsonAlert : HabitatTheme.textMuted),
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(m['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              if (m['role'] == 'CAPTAIN')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: HabitatTheme.amberFocus.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                  child: const Text('CAPTAIN', style: TextStyle(color: HabitatTheme.amberFocus, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(m['time'] as String, style: TextStyle(color: isSiren ? HabitatTheme.crimsonAlert : HabitatTheme.textMuted, fontSize: 12, fontWeight: isSiren ? FontWeight.bold : FontWeight.normal)),
                        ],
                      ),
                    ),
                    if (isSiren)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HabitatTheme.crimsonAlert,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _nudgeMember(m['name'] as String),
                        child: const Text('⚡ NUDGE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                      )
                    else
                      Text('🔥 ${m['streak']}d', style: const TextStyle(color: HabitatTheme.amberFocus, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              );
            }),

            const SizedBox(height: 28),

            // 3. Live Squad Feed
            const Text('SQUAD DISCIPLINE FEED', style: TextStyle(color: HabitatTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HabitatTheme.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _feed.map((event) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(event, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
