// Habitat Nap Tracker Card Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';
import '../../domain/models/nap_entry.dart';

class NapCard extends StatelessWidget {
  final NapSummaryModel nap;
  final String? runningTimer;
  final VoidCallback onToggleNap;
  final VoidCallback? onOpenDetails;

  const NapCard({
    super.key,
    required this.nap,
    this.runningTimer,
    required this.onToggleNap,
    this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HabitatTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: nap.isRunning
              ? const Color(0xFF7209B7)
              : const Color(0xFF7209B7).withOpacity(0.3),
          width: nap.isRunning ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7209B7).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bedtime,
                        color: Color(0xFF7209B7), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'REST & RECOVERY NAP',
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (onOpenDetails != null)
                IconButton(
                  icon: const Icon(Icons.chevron_right,
                      size: 18, color: Color(0xFF7209B7)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onOpenDetails,
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Duration / Active Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nap.isRunning
                        ? (runningTimer ?? 'Running...')
                        : nap.formattedDuration,
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: nap.isRunning
                          ? const Color(0xFF7209B7)
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nap.isRunning
                        ? 'Nap session in progress'
                        : '${nap.todayNaps.length} session${nap.todayNaps.length == 1 ? '' : 's'} today',
                    style: const TextStyle(
                      fontFamily: HabitatTheme.fontBody,
                      fontSize: 12,
                      color: HabitatTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: onToggleNap,
                icon: Icon(nap.isRunning ? Icons.stop : Icons.play_arrow,
                    size: 18),
                label: Text(
                  nap.isRunning ? 'END NAP' : 'START NAP',
                  style: const TextStyle(
                    fontFamily: HabitatTheme.fontHeading,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: nap.isRunning
                      ? Colors.redAccent
                      : const Color(0xFF7209B7),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
