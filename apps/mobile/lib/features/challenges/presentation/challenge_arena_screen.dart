// Discipline Challenge Arena & Global Tournaments Screen
import 'package:flutter/material.dart';
import '../../../core/theme/habitat_theme.dart';

import '../../../database/local_database.dart';

class ChallengeArenaScreen extends StatefulWidget {
  const ChallengeArenaScreen({super.key});

  @override
  State<ChallengeArenaScreen> createState() => _ChallengeArenaScreenState();
}

class _ChallengeArenaScreenState extends State<ChallengeArenaScreen> {
  late final LocalDatabase _database;
  late final LocalUser _user;
  late final LocalStreak _streak;
  late int _completedDays;
  final int _totalDays = 14;

  @override
  void initState() {
    super.initState();
    _database = LocalDatabase.instance;
    _user = _database.getOrCreateProfile();
    _streak = _database.getStreak();
    _completedDays = _streak.currentStreak > 14 ? 14 : _streak.currentStreak;
  }

  List<Map<String, dynamic>> _getLeaderboard() {
    return [
      {
        'rank': 1,
        'name': 'Squad Lead',
        'days': '14/14',
        'resistance': '0.4m',
        'isPodium': true,
      },
      {
        'rank': 2,
        'name': '${_user.displayName} (You)',
        'days': '$_completedDays/14',
        'resistance': '1.2m',
        'isPodium': true,
      },
      {
        'rank': 3,
        'name': 'Vanguard Officer',
        'days': '9/14',
        'resistance': '1.5m',
        'isPodium': true,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('DISCIPLINE ARENA'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Featured Challenge Tournament Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: HabitatTheme.amberFocus.withOpacity(0.5),
                    width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('🏆 14-DAY MORNING ORDER',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xFF262214),
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('SEASON 1',
                            style: TextStyle(
                                color: HabitatTheme.amberFocus,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Execute Make Bed & Morning Sunlight every day for 14 consecutive days. Maintain average wake-up resistance under 2.0 minutes.',
                    style: TextStyle(
                        color: HabitatTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.military_tech,
                          color: HabitatTheme.amberFocus, size: 20),
                      SizedBox(width: 6),
                      Text('+500 XP PRIZE • MORNING SOVEREIGN TROPHY',
                          style: TextStyle(
                              color: HabitatTheme.amberFocus,
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 14-Day Check-in Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_totalDays, (index) {
                      final dayNum = index + 1;
                      final isDone = dayNum <= _completedDays;
                      final isCurrent = dayNum == _completedDays + 1;

                      return Container(
                        width: 18,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDone
                              ? HabitatTheme.emeraldVictory
                              : (isCurrent
                                  ? HabitatTheme.amberFocus
                                  : const Color(0xFF1E1E26)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$dayNum',
                          style: TextStyle(
                            color: isDone || isCurrent
                                ? Colors.black
                                : Colors.white38,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 2. Tournament Leaderboard
            const Text('TOURNAMENT PODIUM & LEADERBOARD',
                style: TextStyle(
                    color: HabitatTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: 12),

            ..._getLeaderboard().map((player) {
              final rank = player['rank'] as int;
              Color rankColor = HabitatTheme.textMuted;
              if (rank == 1) rankColor = const Color(0xFFFFD700); // Gold
              if (rank == 2) rankColor = const Color(0xFFC0C0C0); // Silver
              if (rank == 3) rankColor = const Color(0xFFCD7F32); // Bronze

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: HabitatTheme.surfacePrimary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: rank <= 3
                          ? rankColor.withOpacity(0.3)
                          : HabitatTheme.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: rank <= 3
                            ? rankColor.withOpacity(0.15)
                            : const Color(0xFF1E1E26),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                            color: rank <= 3 ? rankColor : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(player['name'] as String,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          Text('Resistance: ${player['resistance']}',
                              style: const TextStyle(
                                  color: HabitatTheme.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF191922),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        player['days'] as String,
                        style: const TextStyle(
                            color: HabitatTheme.amberFocus,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
