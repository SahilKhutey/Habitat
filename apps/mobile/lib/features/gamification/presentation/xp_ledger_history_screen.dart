// Immutable XP Ledger Audit Trail Screen
import 'package:flutter/material.dart';
import '../../../../packages/design_system/lib/design_system.dart';

class XpLedgerHistoryScreen extends StatelessWidget {
  const XpLedgerHistoryScreen({super.key});

  final List<Map<String, dynamic>> _transactions = const [
    {
      'amount': '+45 XP',
      'reason': '10 Morning Push-Ups Completed (Includes +50% Speed Bonus)',
      'time': 'Today, 07:02 AM',
      'isPositive': true,
    },
    {
      'amount': '+100 XP',
      'reason': '7-Day Unbroken Streak Milestone Achieved',
      'time': 'Yesterday, 07:00 AM',
      'isPositive': true,
    },
    {
      'amount': '+20 XP',
      'reason': 'Morning Bed Alignment Verified',
      'time': '2 days ago, 06:45 AM',
      'isPositive': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('IMMUTABLE XP LEDGER'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.xl),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final tx = _transactions[index];
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx['reason'] as String, style: AppTypography.titleSmall),
                        const SizedBox(height: 2),
                        Text(tx['time'] as String, style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  Text(
                    tx['amount'] as String,
                    style: const TextStyle(
                      color: AppColors.emeraldVictory,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
