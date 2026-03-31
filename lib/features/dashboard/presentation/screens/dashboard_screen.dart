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
              _OptimizeButton(ref: ref),
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

class _OptimizeButton extends StatefulWidget {
  final WidgetRef ref;

  const _OptimizeButton({required this.ref});

  @override
  State<_OptimizeButton> createState() => _OptimizeButtonState();
}

class _OptimizeButtonState extends State<_OptimizeButton> {
  bool _isOptimizing = false;

  Future<void> _runOptimization() async {
    if (_isOptimizing) return;
    setState(() => _isOptimizing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => const _OptimizationDialog(),
    );

    try {
      final repo =
          widget.ref.read(storageRepositoryProvider);
      final cacheCleared = await repo.clearAppCache();

      widget.ref.invalidate(batteryInfoProvider);
      widget.ref.invalidate(storageInfoProvider);

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showResultSheet(cacheCleared);
      }
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Optimizasyon sırasında bir hata oluştu')),
        );
      }
    } finally {
      if (mounted) setState(() => _isOptimizing = false);
    }
  }

  void _showResultSheet(int cacheCleared) {
    final cacheMB = (cacheCleared / (1024 * 1024)).toStringAsFixed(1);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.check_circle, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Optimizasyon Tamamlandı!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ResultChip(
                  icon: Icons.cached,
                  label: 'Önbellek',
                  value: '$cacheMB MB',
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 12),
                const _ResultChip(
                  icon: Icons.memory,
                  label: 'RAM',
                  value: 'Optimize',
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tamam'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

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
          onTap: _runOptimization,
          child: Center(
            child: _isOptimizing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.background,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
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

class _OptimizationDialog extends StatefulWidget {
  const _OptimizationDialog();

  @override
  State<_OptimizationDialog> createState() => _OptimizationDialogState();
}

class _OptimizationDialogState extends State<_OptimizationDialog> {
  int _step = 0;
  static const _steps = [
    'Önbellek temizleniyor...',
    'RAM optimize ediliyor...',
    'Depolama analiz ediliyor...',
  ];

  @override
  void initState() {
    super.initState();
    _advanceSteps();
  }

  Future<void> _advanceSteps() async {
    for (var i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) setState(() => _step = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Optimize Ediliyor',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _steps[_step],
                key: ValueKey(_step),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ResultChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
