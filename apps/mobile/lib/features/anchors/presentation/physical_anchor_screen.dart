// Physical NFC / QR Hardware Anchors Screen
import 'package:flutter/material.dart';
import '../../../core/theme/habitat_theme.dart';

class PhysicalAnchorScreen extends StatefulWidget {
  const PhysicalAnchorScreen({super.key});

  @override
  State<PhysicalAnchorScreen> createState() => _PhysicalAnchorScreenState();
}

class _PhysicalAnchorScreenState extends State<PhysicalAnchorScreen> {
  final List<Map<String, dynamic>> _anchors = [
    {
      'name': 'Bathroom Sink Tag',
      'type': 'NFC_TAG',
      'location': 'Master Bathroom Sink',
      'icon': Icons.nfc,
      'status': 'ACTIVE',
    },
    {
      'name': 'Kitchen Counter QR Sticker',
      'type': 'ROTATING_QR',
      'location': 'Kitchen Island Counter',
      'icon': Icons.qr_code_scanner,
      'status': 'ACTIVE',
    },
  ];

  void _simulateNfcTap(String name, String location) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HabitatTheme.surfacePrimary,
        title: const Row(
          children: [
            Icon(Icons.check_circle,
                color: HabitatTheme.emeraldVictory, size: 28),
            SizedBox(width: 10),
            Text('HARDWARE ANCHOR VERIFIED',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
            'Cryptographic HMAC nonce verified at "$location".\n\nPhysical presence confirmed. Mission Completed! +50 XP'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CONFIRM WAKEUP',
                style: TextStyle(
                    color: HabitatTheme.amberFocus,
                    fontWeight: FontWeight.bold)),
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
        title: const Text('PHYSICAL HARDWARE ANCHORS'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Anti-Cheat Guarantee Banner
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: HabitatTheme.surfacePrimary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: HabitatTheme.emeraldVictory.withOpacity(0.4)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_user,
                          color: HabitatTheme.emeraldVictory, size: 24),
                      SizedBox(width: 10),
                      Text('ZERO-CHEAT PHYSICAL PROOF',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Physical anchors require you to stand up and physically tap an NFC tag or scan a rotating cryptographic QR code located away from your bed.',
                    style: TextStyle(
                        color: HabitatTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Paired Hardware Anchors List
            const Text('PAIRED HARDWARE LOCATIONS',
                style: TextStyle(
                    color: HabitatTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: 12),

            ..._anchors.map((anchor) {
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
                        color: HabitatTheme.amberFocus.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(anchor['icon'] as IconData,
                          color: HabitatTheme.amberFocus, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(anchor['name'] as String,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
                          Text(anchor['location'] as String,
                              style: const TextStyle(
                                  color: HabitatTheme.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HabitatTheme.amberFocus,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _simulateNfcTap(anchor['name'] as String,
                          anchor['location'] as String),
                      child: const Text('TAP SCAN',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 11)),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // 3. Pair New Hardware Anchor Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('PAIR NEW NFC / QR ANCHOR',
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
                            'Hold NFC tag near phone to pair new anchor...')),
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
