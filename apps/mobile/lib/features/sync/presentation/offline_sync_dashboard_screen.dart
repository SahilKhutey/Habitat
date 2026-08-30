// Offline Queue Inspector & Multi-Device Sync Screen
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import '../data/sync_queue_service.dart';

class OfflineSyncDashboardScreen extends StatelessWidget {
  const OfflineSyncDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pending = SyncQueueService.pendingItems;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('OFFLINE SYNC & MESH'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sync Now',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Flushing offline queue to server...')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadii.radiusLarge,
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldVictory.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_done, color: AppColors.emeraldVictory, size: 32),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('SYNC ENGINE ACTIVE', style: AppTypography.titleSmall),
                        SizedBox(height: 2),
                        Text(
                          'Local queue persists offline proofs and flushes automatically when connectivity restores.',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            const Text('PENDING OFFLINE QUEUE', style: AppTypography.labelSmall),
            const SizedBox(height: AppSpacing.md),

            if (pending.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppRadii.radiusLarge,
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.check_circle_outline, color: AppColors.emeraldVictory, size: 40),
                    SizedBox(height: AppSpacing.sm),
                    Text('All events synced with cloud', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 2),
                    Text('0 items waiting in local SQLite queue', style: AppTypography.bodySmall),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pending.length,
                itemBuilder: (context, index) {
                  final item = pending[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: AppRadii.radiusMedium,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.type, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            Text(item.idempotencyKey, style: AppTypography.bodySmall),
                          ],
                        ),
                        const Icon(Icons.hourglass_top, color: AppColors.amberFocus, size: 20),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
