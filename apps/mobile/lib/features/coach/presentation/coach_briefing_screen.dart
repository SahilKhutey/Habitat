// Autonomous AI Habit Coach Briefing & Behavioral Adaptation Screen
import 'package:flutter/material.dart';
import '../../../core/theme/habitat_theme.dart';

class CoachBriefingScreen extends StatefulWidget {
  const CoachBriefingScreen({super.key});

  @override
  State<CoachBriefingScreen> createState() => _CoachBriefingScreenState();
}

class _CoachBriefingScreenState extends State<CoachBriefingScreen> {
  bool _isPlayingAudio = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('AI DISCIPLINE COACH'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tactical Morning Briefing Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: HabitatTheme.amberFocus.withOpacity(0.4),
                    width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.psychology,
                              color: HabitatTheme.amberFocus, size: 22),
                          SizedBox(width: 8),
                          Text('TACTICAL DAILY BRIEFING',
                              style: TextStyle(
                                  color: HabitatTheme.amberFocus,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: const Color(0xFF262214),
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('DAY 13',
                            style: TextStyle(
                                color: HabitatTheme.amberFocus,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Day 13: Momentum & Autonomy Milestone',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Good morning, Alex. Your sleep recovery is rated at 88%. Your wake-up resistance over recent missions is 1.8 minutes, putting your autonomy in the 92nd percentile.',
                    style: TextStyle(
                        color: HabitatTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: HabitatTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt,
                            color: HabitatTheme.amberFocus, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Protocol: Execute 10 push-ups on Attempt #1 to secure the +50% Instant Action XP multiplier.',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Audio Briefing Player Simulation
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      icon: Icon(
                          _isPlayingAudio ? Icons.pause : Icons.volume_up,
                          color: Colors.black,
                          size: 18),
                      label: Text(
                        _isPlayingAudio
                            ? 'PAUSE VOICE BRIEFING'
                            : 'PLAY 30s VOICE BRIEFING',
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 1),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HabitatTheme.amberFocus,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() => _isPlayingAudio = !_isPlayingAudio);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Behavioral Adaptation Insights
            const Text('PERSONALIZED BEHAVIORAL ADAPTATIONS',
                style: TextStyle(
                    color: HabitatTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: 12),

            _buildAdaptationCard(
              icon: Icons.wb_sunny_outlined,
              title: 'Light Pre-Conditioning',
              desc:
                  'Sunlight exposure within 5 minutes of waking reduces your afternoon fatigue by 34%.',
            ),
            _buildAdaptationCard(
              icon: Icons.access_time_filled,
              title: 'Resistance Friction Point',
              desc:
                  'Wednesdays show a 2.8m average resistance. AI coach recommends shifting bedtime 15m earlier on Tuesdays.',
            ),
            _buildAdaptationCard(
              icon: Icons.shield,
              title: 'Grace Vault Status',
              desc:
                  '1 Grace Token is locked in your vault. Maintain streak for 2 more days to unlock Grace Token #2.',
            ),

            const SizedBox(height: 24),

            // 3. Autonomous Schedule Tuning Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.auto_fix_high, color: Colors.white),
                label: const Text('AUTO-TUNE HABIT SCHEDULE',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HabitatTheme.surfacePrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: HabitatTheme.surfaceBorder),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'AI Coach optimized wake-up triggers for circadian synchronization.')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdaptationCard(
      {required IconData icon, required String title, required String desc}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HabitatTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HabitatTheme.surfaceBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: HabitatTheme.amberFocus, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc,
                    style: const TextStyle(
                        color: HabitatTheme.textSecondary,
                        fontSize: 12,
                        height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
