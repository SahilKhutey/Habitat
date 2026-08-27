// Iron Fortress App Lockdown, Distraction Shield & Discipline Bond Staking Screen
import 'package:flutter/material.dart';
import '../../../core/theme/habitat_theme.dart';

class IronFortressScreen extends StatefulWidget {
  const IronFortressScreen({super.key});

  @override
  State<IronFortressScreen> createState() => _IronFortressScreenState();
}

class _IronFortressScreenState extends State<IronFortressScreen> {
  bool _shieldEnabled = true;
  int _selectedBondXp = 250;

  final List<String> _blockedApps = [
    'Instagram (com.instagram.android)',
    'TikTok (com.zhiliaoapp.musically)',
    'YouTube (com.google.android.youtube)',
    'X / Twitter (com.twitter.android)',
    'Reddit (com.reddit.frontpage)',
  ];

  void _stakeBond() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HabitatTheme.surfacePrimary,
        title: const Row(
          children: [
            Icon(Icons.lock, color: HabitatTheme.amberFocus, size: 24),
            SizedBox(width: 8),
            Text('DISCIPLINE BOND STAKED', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '$_selectedBondXp XP locked in escrow.\n\n• If you execute Attempt #1: +${(_selectedBondXp * 1.5).round()} XP payout (+50% bonus).\n• If you snooze or fail: -$_selectedBondXp XP burned forever.',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('HONOR COMMITMENT', style: TextStyle(color: HabitatTheme.amberFocus, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _requestEmergencyBypass() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HabitatTheme.surfacePrimary,
        title: const Text('⚠️ EMERGENCY OS BYPASS', style: TextStyle(color: HabitatTheme.crimsonAlert, fontWeight: FontWeight.bold)),
        content: const Text(
          'Emergency unlock will unblock apps for 15 minutes. This action will be permanently recorded in your public Discipline Audit Ledger.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('CANCEL', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: HabitatTheme.crimsonAlert),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Emergency bypass granted for 15m. Logged to ledger.')),
              );
            },
            child: const Text('UNLOCK FOR 15M', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('IRON FORTRESS LOCKDOWN'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Fortress Status Banner
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: HabitatTheme.amberFocus.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('🛡️ DISTRACTION SHIELD', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      Switch(
                        value: _shieldEnabled,
                        activeColor: HabitatTheme.amberFocus,
                        onChanged: (val) => setState(() => _shieldEnabled = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'When morning alarm fires, all social media and entertainment apps enter OS quarantine until all tasks are verified.',
                    style: TextStyle(color: HabitatTheme.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Discipline Bond Escrow Staking
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: HabitatTheme.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('STAKE DISCIPLINE BOND', style: TextStyle(color: HabitatTheme.amberFocus, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  const Text(
                    'Put skin in the game. Stake your XP on tomorrow’s wakeup. Win +50% on instant action; lose it all on snooze.',
                    style: TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [100, 250, 500].map((amount) {
                      final isSelected = amount == _selectedBondXp;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isSelected ? HabitatTheme.amberFocus : Colors.transparent,
                              foregroundColor: isSelected ? Colors.black : Colors.white,
                              side: BorderSide(color: isSelected ? HabitatTheme.amberFocus : HabitatTheme.surfaceBorder),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => setState(() => _selectedBondXp = amount),
                            child: Text('$amount XP', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HabitatTheme.amberFocus,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _stakeBond,
                      child: Text('STAKE $_selectedBondXp XP BOND', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Blocked Apps List
            const Text('QUARANTINED APPS (5 BLOCKED)', style: TextStyle(color: HabitatTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 10),

            ..._blockedApps.map((app) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: HabitatTheme.surfacePrimary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HabitatTheme.surfaceBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.block, color: HabitatTheme.crimsonAlert, size: 20),
                    const SizedBox(width: 12),
                    Text(app, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // 4. Emergency Bypass Button
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.warning_amber, color: HabitatTheme.crimsonAlert, size: 18),
                label: const Text('REQUEST AUDITED EMERGENCY BYPASS', style: TextStyle(color: HabitatTheme.crimsonAlert, fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: _requestEmergencyBypass,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
