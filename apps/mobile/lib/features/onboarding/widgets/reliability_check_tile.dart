// Interactive Reliability Check Tile for Alarm Onboarding (Milestone C2/C3)
import 'package:flutter/material.dart';
import '../../alarms/domain/alarm_health_models.dart';

class ReliabilityCheckTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final DiagnosticStatus status;
  final VoidCallback? onFix;
  final String fixButtonText;

  const ReliabilityCheckTile({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.status,
    this.onFix,
    this.fixButtonText = 'Fix in Settings',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isConfirmed = status == DiagnosticStatus.confirmed;
    final isRecommended = status == DiagnosticStatus.actionRecommended;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16181D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConfirmed
              ? const Color(0xFF10B981).withOpacity(0.3)
              : (isRecommended ? const Color(0xFFF59E0B).withOpacity(0.4) : const Color(0xFF2A2E39)),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isConfirmed
                      ? const Color(0xFF10B981).withOpacity(0.15)
                      : const Color(0xFFF59E0B).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isConfirmed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isConfirmed)
                const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 22)
              else
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 22),
            ],
          ),
          if (!isConfirmed && onFix != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onFix,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF59E0B),
                  side: const BorderSide(color: Color(0xFFF59E0B)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text(
                  fixButtonText,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
