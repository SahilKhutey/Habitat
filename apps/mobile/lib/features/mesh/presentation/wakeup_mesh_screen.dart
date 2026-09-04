// Multi-Device Wakeup Mesh & Synchronized Telemetry Screen
import 'package:flutter/material.dart';
import '../../../core/theme/habitat_theme.dart';

class WakeupMeshScreen extends StatefulWidget {
  const WakeupMeshScreen({super.key});

  @override
  State<WakeupMeshScreen> createState() => _WakeupMeshScreenState();
}

class _WakeupMeshScreenState extends State<WakeupMeshScreen> {
  bool _isMeshAlarmActive = false;

  final List<Map<String, dynamic>> _devices = [
    {
      'name': 'Pixel 9 Pro (Primary Phone)',
      'type': 'PHONE',
      'icon': Icons.phone_android,
      'isOnline': true,
      'latency': '12ms',
    },
    {
      'name': 'iPad Pro (Bedside Tablet)',
      'type': 'TABLET',
      'icon': Icons.tablet_mac,
      'isOnline': true,
      'latency': '18ms',
    },
    {
      'name': 'Apple Watch Ultra (Wrist Mesh)',
      'type': 'WATCH',
      'icon': Icons.watch,
      'isOnline': true,
      'latency': '24ms',
    },
    {
      'name': 'Chrome Web Command Center',
      'type': 'DESKTOP_WEB',
      'icon': Icons.laptop_mac,
      'isOnline': true,
      'latency': '8ms',
    },
  ];

  void _triggerMeshSiren() {
    setState(() => _isMeshAlarmActive = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: HabitatTheme.crimsonAlert,
        content: Text(
            '🚨 SYNCHRONIZED MESH SIREN DISPATCHED ACROSS ALL 4 DEVICES (85dB)!'),
      ),
    );
  }

  void _disarmMesh() {
    setState(() => _isMeshAlarmActive = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: HabitatTheme.emeraldVictory,
        content: Text(
            '✅ SYNCHRONOUS DISARM BROADCAST! All secondary devices silenced.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      appBar: AppBar(
        title: const Text('WAKEUP MESH TOPOLOGY'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Mesh Topology Banner
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isMeshAlarmActive
                      ? HabitatTheme.crimsonAlert
                      : HabitatTheme.amberFocus.withOpacity(0.4),
                  width: _isMeshAlarmActive ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.hub,
                              color: _isMeshAlarmActive
                                  ? HabitatTheme.crimsonAlert
                                  : HabitatTheme.amberFocus,
                              size: 22),
                          const SizedBox(width: 8),
                          Text(
                            _isMeshAlarmActive
                                ? 'MESH SIREN ACTIVE (4 NODES)'
                                : '4 MESH NODES ONLINE',
                            style: TextStyle(
                              color: _isMeshAlarmActive
                                  ? HabitatTheme.crimsonAlert
                                  : HabitatTheme.amberFocus,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: const Color(0xFF1E2820),
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('SYNCED',
                            style: TextStyle(
                                color: HabitatTheme.emeraldVictory,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Distributed Wakeup Mesh',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'When 07:00 arrives, sirens fire simultaneously across your phone, tablet, smartwatch, and desktop. Verifying proof on any single device synchronously silences all other mesh nodes.',
                    style: TextStyle(
                        color: HabitatTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  // Trigger/Disarm Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: Icon(
                          _isMeshAlarmActive
                              ? Icons.volume_off
                              : Icons.wifi_tethering,
                          color: Colors.black),
                      label: Text(
                        _isMeshAlarmActive
                            ? 'DISARM ALL MESH NODES'
                            : 'TRIGGER SYNCHRONIZED MESH SIREN',
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 1),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isMeshAlarmActive
                            ? HabitatTheme.emeraldVictory
                            : HabitatTheme.amberFocus,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed:
                          _isMeshAlarmActive ? _disarmMesh : _triggerMeshSiren,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 2. Connected Nodes List
            const Text('CONNECTED HARDWARE NODES',
                style: TextStyle(
                    color: HabitatTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: 12),

            ..._devices.map((device) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HabitatTheme.surfacePrimary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: HabitatTheme.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C24),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(device['icon'] as IconData,
                          color: HabitatTheme.amberFocus, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(device['name'] as String,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                      color: HabitatTheme.emeraldVictory,
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text('Online • Latency: ${device['latency']}',
                                  style: const TextStyle(
                                      color: HabitatTheme.textMuted,
                                      fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_isMeshAlarmActive)
                      const Text('🚨 RINGING',
                          style: TextStyle(
                              color: HabitatTheme.crimsonAlert,
                              fontWeight: FontWeight.bold,
                              fontSize: 11))
                    else
                      const Text('READY',
                          style: TextStyle(
                              color: HabitatTheme.emeraldVictory,
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // 3. Register New Device CTA
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_to_queue, color: Colors.white70),
                label: const Text('ENROLL NEW HARDWARE MESH NODE',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: HabitatTheme.surfaceBorder),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Scan QR code on secondary device to join mesh topology.')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
