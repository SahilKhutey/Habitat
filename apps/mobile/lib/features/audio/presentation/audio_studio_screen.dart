// Psychoacoustic Audio Studio & Hardware Siren Test Bench
import 'package:flutter/material.dart';
import '../../../core/theme/habitat_theme.dart';

class AudioStudioScreen extends StatefulWidget {
  const AudioStudioScreen({super.key});

  @override
  State<AudioStudioScreen> createState() => _AudioStudioScreenState();
}

class _AudioStudioScreenState extends State<AudioStudioScreen> {
  int _selectedProfileIndex = 0;
  bool _isPlayingTest = false;

  final List<Map<String, dynamic>> _profiles = [
    {
      'name': 'Spartan War Siren',
      'baseHz': 880,
      'binauralHz': 40.0,
      'waveType': 'GAMMA (40 Hz)',
      'escalation': 'EXPONENTIAL',
      'desc':
          'High-frequency oscillating dissonance designed for immediate prefrontal cortex ignition.',
    },
    {
      'name': 'Gamma 40Hz Prefrontal Ignition',
      'baseHz': 432,
      'binauralHz': 40.0,
      'waveType': 'GAMMA (40 Hz)',
      'escalation': 'STROBE_PULSE',
      'desc':
          'Alternating strobe pulses entraining 40Hz neural synchrony to instantly break sleep inertia.',
    },
    {
      'name': 'Sub-Bass Kinetic Shockwave',
      'baseHz': 120,
      'binauralHz': 25.0,
      'waveType': 'BETA (25 Hz)',
      'escalation': 'EXPONENTIAL',
      'desc':
          'Deep visceral vibration paired with rapid ascending frequency sweeps.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _profiles[_selectedProfileIndex];

    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('PSYCHOACOUSTIC STUDIO'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Oscillating Waveform Header
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: HabitatTheme.crimsonAlert.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.graphic_eq,
                              color: HabitatTheme.crimsonAlert, size: 22),
                          SizedBox(width: 8),
                          Text('SYNTHESIZER OSCILLATOR',
                              style: TextStyle(
                                  color: HabitatTheme.crimsonAlert,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2)),
                        ],
                      ),
                      Chip(
                        backgroundColor: const Color(0xFF261414),
                        label: Text(selected['waveType'] as String,
                            style: const TextStyle(
                                color: HabitatTheme.crimsonAlert,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    selected['name'] as String,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selected['desc'] as String,
                    style: const TextStyle(
                        color: HabitatTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4),
                  ),
                  const SizedBox(height: 18),

                  // Technical Frequency Specs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSpecBadge(
                          'BASE CARRIER', '${selected['baseHz']} Hz'),
                      _buildSpecBadge(
                          'BINAURAL BEAT', '${selected['binauralHz']} Hz'),
                      _buildSpecBadge(
                          'ESCALATION', selected['escalation'] as String),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Siren Test Player Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: Icon(_isPlayingTest ? Icons.stop : Icons.play_arrow,
                          color: Colors.white),
                      label: Text(
                        _isPlayingTest
                            ? 'STOP SIREN TEST'
                            : 'TEST SIREN ESCALATION (70dB -> 100dB)',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 1),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HabitatTheme.crimsonAlert,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() => _isPlayingTest = !_isPlayingTest);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 2. Siren Profiles Selection
            const Text('PSYCHOACOUSTIC SOUND PRESETS',
                style: TextStyle(
                    color: HabitatTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: 12),

            ..._profiles.asMap().entries.map((entry) {
              final idx = entry.key;
              final profile = entry.value;
              final isSelected = idx == _selectedProfileIndex;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? HabitatTheme.surfaceSecondary
                      : HabitatTheme.surfacePrimary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? HabitatTheme.amberFocus
                        : HabitatTheme.surfaceBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: () => setState(() => _selectedProfileIndex = idx),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected
                            ? HabitatTheme.amberFocus
                            : HabitatTheme.textMuted,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile['name'] as String,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                                '${profile['baseHz']} Hz • ${profile['waveType']}',
                                style: const TextStyle(
                                    color: HabitatTheme.textMuted,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: HabitatTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: HabitatTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
