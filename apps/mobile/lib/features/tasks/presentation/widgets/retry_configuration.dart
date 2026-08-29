// Habitat Retry Rules Configuration Component
import 'package:flutter/material.dart';
import '../../../../core/theme/habitat_theme.dart';

class RetryConfiguration extends StatelessWidget {
  final bool retryEnabled;
  final int retryIntervalMinutes;
  final int maxAttempts;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onIntervalChanged;
  final ValueChanged<int> onMaxAttemptsChanged;

  const RetryConfiguration({
    super.key,
    required this.retryEnabled,
    required this.retryIntervalMinutes,
    required this.maxAttempts,
    required this.onEnabledChanged,
    required this.onIntervalChanged,
    required this.onMaxAttemptsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enable Retry Switch
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HabitatTheme.surfacePrimary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HabitatTheme.surfaceBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '5-MINUTE ESCALATION RETRY',
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontHeading,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Re-arms louder alarm if verification fails.',
                    style: TextStyle(
                      fontFamily: HabitatTheme.fontBody,
                      fontSize: 11,
                      color: HabitatTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Switch(
                value: retryEnabled,
                activeColor: HabitatTheme.growthGreen,
                onChanged: onEnabledChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (retryEnabled) ...[
          // Max Retries Selector
          const Text(
            'MAXIMUM ESCALATION ATTEMPTS',
            style: TextStyle(
              fontFamily: HabitatTheme.fontHeading,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: HabitatTheme.youngLeaf,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [2, 3, 5].map((count) {
              final isSelected = maxAttempts == count;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => onMaxAttemptsChanged(count),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? HabitatTheme.habitatGreen : HabitatTheme.surfacePrimary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? HabitatTheme.growthGreen : HabitatTheme.surfaceBorder,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$count Attempts',
                        style: TextStyle(
                          fontFamily: HabitatTheme.fontHeading,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : HabitatTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
