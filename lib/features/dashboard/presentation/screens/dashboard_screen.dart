import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oxyn_card.dart';
import '../../../../core/widgets/score_ring.dart';
import '../../domain/dashboard_provider.dart';
import '../../../battery/domain/battery_provider.dart';
import '../../../cleaner/domain/storage_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(healthScoreProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oxyn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(batteryInfoProvider);
          ref.invalidate(storageInfoProvider);
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              _ScoreSection(score: score),
              const SizedBox(height: AppSpacing.lg),
              _ModuleGrid(ref: ref),
              const SizedBox(height: AppSpacing.lg),
              const _OptimizeButton(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreSection extends StatelessWidget {
  final dynamic score;

  const _ScoreSection({required this.score});

  @override
  Widget build(BuildContext context) {
    return OxynCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Text(
            'Günlük Skor',
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
              score.statusMessage,
              style: TextStyle(
                color: score.isGood ? AppColors.success : AppColors.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  final WidgetRef ref;

  const _ModuleGrid({required this.ref});

  @override
  Widget build(BuildContext context) {
    final batteryAsync = ref.watch(batteryInfoProvider);
    final batteryText = batteryAsync.when(
      loading: () => '...',
      error: (e, s) => '—',
      data: (info) => '%${info.level}',
    );

    final storageAsync = ref.watch(storageInfoProvider);
    final storageText = storageAsync.when(
      loading: () => '...',
      error: (e, s) => '—',
      data: (info) => info.freeFormatted,
    );

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _ModuleCard(
          icon: Icons.battery_std,
          label: 'Batarya',
          value: batteryText,
          color: AppColors.success,
          onTap: () => context.go('/battery'),
        ),
        _ModuleCard(
          icon: Icons.speed,
          label: 'Performans',
          value: 'Detay',
          color: AppColors.primary,
          onTap: () => context.push('/performance'),
        ),
        _ModuleCard(
          icon: Icons.cleaning_services,
          label: 'Temizlik',
          value: storageText,
          color: AppColors.secondary,
          onTap: () => context.go('/cleaner'),
        ),
        _ModuleCard(
          icon: Icons.palette,
          label: 'Stil',
          value: '15 Tema',
          color: AppColors.tertiary,
          onTap: () => context.go('/style'),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OxynCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptimizeButton extends StatelessWidget {
  const _OptimizeButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          onTap: () {
            // TODO: Trigger optimization flow with animation
          },
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt, color: AppColors.background, size: 24),
                SizedBox(width: 8),
                Text(
                  'Optimize Et',
                  style: TextStyle(
                    color: AppColors.background,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
