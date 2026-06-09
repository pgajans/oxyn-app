import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oxyn_card.dart';
import '../../../../core/widgets/score_ring.dart';
import '../../../dashboard/domain/dashboard_provider.dart';
import '../../domain/performance_provider.dart';

class PerformanceScreen extends ConsumerWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final score = ref.watch(healthScoreProvider);
    final deviceAsync = ref.watch(deviceInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.performance),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            OxynCard(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                children: [
                  Text(
                    t.performanceScore,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ScoreRing(score: score.total),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: (score.isGood ? AppColors.success : AppColors.secondary)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _healthStatusText(t, score.statusLevel),
                      style: TextStyle(
                        color: score.isGood ? AppColors.success : AppColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Score breakdown
            Row(
              children: [
                _ScoreBreakdownTile(
                  label: t.battery,
                  score: score.batteryScore,
                  maxScore: 35,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _ScoreBreakdownTile(
                  label: t.storage,
                  score: score.storageScore,
                  maxScore: 40,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _ScoreBreakdownTile(
                  label: t.temperature,
                  score: score.temperatureScore,
                  maxScore: 25,
                  color: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Device Info
            deviceAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (e, _) => OxynCard(
                child: Text('Cihaz bilgisi alınamadı: $e'),
              ),
              data: (device) => OxynCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.deviceInfo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _InfoItem(label: t.model, value: device.model),
                    _InfoItem(label: t.operatingSystem, value: device.osVersion),
                    if (device.totalStorage != '—')
                      _InfoItem(label: t.storage, value: device.totalStorage),
                    if (device.freeStorage != '—')
                      _InfoItem(label: t.freeSpace, value: device.freeStorage),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _ScoreBreakdownTile extends StatelessWidget {
  final String label;
  final int score;
  final int maxScore;
  final Color color;

  const _ScoreBreakdownTile({
    required this.label,
    required this.score,
    required this.maxScore,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OxynCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              '$score/$maxScore',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: score / maxScore,
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _healthStatusText(AppLocalizations t, int level) {
  switch (level) {
    case 0:
      return t.healthStatusHealthy;
    case 1:
      return t.healthStatusGood;
    case 2:
      return t.healthStatusImprovement;
    case 3:
      return t.healthStatusMaintenance;
    default:
      return t.healthStatusUrgent;
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
