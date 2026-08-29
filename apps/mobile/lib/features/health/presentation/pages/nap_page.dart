// Habitat Dedicated Nap Session HUD Screen
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../../../database/local_database.dart';
import '../../application/nap_controller.dart';
import '../../domain/repositories/health_repository.dart';
import '../../domain/services/nap_service.dart';
import '../widgets/nap_timer.dart';

class NapPage extends StatefulWidget {
  final NapController? controller;

  const NapPage({super.key, this.controller});

  @override
  State<NapPage> createState() => _NapPageState();
}

class _NapPageState extends State<NapPage> {
  late final NapController _controller;
  bool _internalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      final db = LocalDatabase.instance;
      _controller = NapController(
        napService: NapService(HealthRepository(db)),
        database: db,
      );
      _internalController = true;
    }
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
        final nap = _controller.summary;

        return Scaffold(
          backgroundColor: HabitatTheme.background,
          appBar: AppBar(
            title: const Text('REST & RECOVERY NAP'),
            backgroundColor: HabitatTheme.background,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Centerpiece Timer Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    decoration: BoxDecoration(
                      color: HabitatTheme.surfacePrimary,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: nap.isRunning
                            ? const Color(0xFF7209B7)
                            : HabitatTheme.surfaceBorder,
                        width: nap.isRunning ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        NapTimer(
                          formattedTime: _controller.formattedTimer,
                          isRunning: nap.isRunning,
                        ),
                        const SizedBox(height: 28),

                        SizedBox(
                          width: 200,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (nap.isRunning) {
                                _controller.stopNap();
                              } else {
                                _controller.startNap();
                              }
                            },
                            icon: Icon(nap.isRunning ? Icons.stop : Icons.play_arrow),
                            label: Text(
                              nap.isRunning ? 'END REST SESSION' : 'START NAP SESSION',
                              style: const TextStyle(
                                fontFamily: HabitatTheme.fontHeading,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: nap.isRunning ? Colors.redAccent : const Color(0xFF7209B7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Today's Nap History
                  const Text(
                    "TODAY'S REST SESSIONS",
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: HabitatTheme.youngLeaf,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: nap.todayNaps.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: HabitatTheme.surfacePrimary,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: HabitatTheme.surfaceBorder),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'No rest sessions recorded today.',
                              style: TextStyle(color: HabitatTheme.textSecondary, fontSize: 13),
                            ),
                          )
                        : ListView.builder(
                            itemCount: nap.todayNaps.length,
                            itemBuilder: (context, index) {
                              final session = nap.todayNaps[index];
                              final startStr = '${session.startedAt.hour.toString().padLeft(2, '0')}:${session.startedAt.minute.toString().padLeft(2, '0')}';
                              final endStr = session.endedAt != null
                                  ? '${session.endedAt!.hour.toString().padLeft(2, '0')}:${session.endedAt!.minute.toString().padLeft(2, '0')}'
                                  : 'Now';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: HabitatTheme.surfacePrimary,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: HabitatTheme.surfaceBorder),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF7209B7).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.bedtime, color: Color(0xFF7209B7), size: 18),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              session.isRunning
                                                  ? 'Session Active'
                                                  : '${session.durationMinutes} Minutes Rest',
                                              style: const TextStyle(
                                                fontFamily: HabitatTheme.fontHeading,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              '$startStr - $endStr',
                                              style: const TextStyle(
                                                fontFamily: HabitatTheme.fontBody,
                                                fontSize: 12,
                                                color: HabitatTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (session.isRunning)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7209B7).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFF7209B7)),
                                        ),
                                        child: const Text(
                                          'ACTIVE',
                                          style: TextStyle(
                                            color: Color(0xFF7209B7),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
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
      },
    );
  }
}
