import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/services/router.dart';
import '../../../cleaner/data/storage_repository.dart';
import '../../../subscription/presentation/screens/paywall_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      markOnboardingSeen();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const _ScanScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final pages = <_OnboardingPage>[
      _OnboardingPage(
        icon: Icons.favorite_border,
        title: t.onboarding1Title,
        description: t.onboarding1Desc,
        color: AppColors.primary,
      ),
      _OnboardingPage(
        icon: Icons.cleaning_services_outlined,
        title: t.onboarding2Title,
        description: t.onboarding2Desc,
        color: AppColors.secondary,
      ),
      _OnboardingPage(
        icon: Icons.bolt_outlined,
        title: t.onboarding3Title,
        description: t.onboarding3Desc,
        color: AppColors.tertiary,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () {
                    markOnboardingSeen();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const _ScanScreen()),
                    );
                  },
                  child: Text(
                    t.skip,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? AppColors.primary
                          : Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(
                    _currentPage == pages.length - 1
                        ? t.startScanButton
                        : t.next,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: color),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _ScanScreen extends StatefulWidget {
  const _ScanScreen();

  @override
  State<_ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<_ScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _taskIndex = 0;
  int _totalTasks = 6;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _controller.forward();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.addListener(_updateTask);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToResult();
      }
    });
    _performRealOptimization();
  }

  Future<void> _performRealOptimization() async {
    try {
      final repo = StorageRepository();
      await repo.clearAppCache();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'last_optimize_time', DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(
          'last_free_clean_time', DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool('free_clean_used', true);
    } catch (e) {
      debugPrint('Onboarding optimization error: $e');
    }
  }

  void _updateTask() {
    final newIndex = (_controller.value * _totalTasks).floor();
    if (newIndex != _taskIndex && newIndex < _totalTasks) {
      setState(() {
        _taskIndex = newIndex;
      });
    }
  }

  void _navigateToResult() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const _ScanResultScreen()),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_updateTask);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final tasks = [
      t.analyzingBattery,
      t.scanningStorage,
      t.checkingPhotos,
      t.searchingLargeFiles,
      t.evaluatingPerformance,
      t.calculatingHealthScore,
    ];
    _totalTasks = tasks.length;
    final currentTask = tasks[_taskIndex.clamp(0, tasks.length - 1)];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _controller.value,
                      strokeWidth: 8,
                      backgroundColor:
                          Theme.of(context).dividerColor.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      '${(_controller.value * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                t.scanningYourDevice,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  currentTask,
                  key: ValueKey(currentTask),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                t.scanTakesSeconds,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanResultScreen extends StatelessWidget {
  const _ScanResultScreen();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: AppColors.success, size: 56),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(t.optimizationComplete,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.md),
              Text(
                t.weeklyFreeCleanAvailable,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.5),
              ),
              const SizedBox(height: AppSpacing.xl),
              _ResultCard(
                  icon: Icons.cached,
                  label: t.cache,
                  value: '✓',
                  color: AppColors.primary),
              const SizedBox(height: 12),
              _ResultCard(
                  icon: Icons.storage,
                  label: t.storage,
                  value: '✓',
                  color: AppColors.secondary),
              const SizedBox(height: 12),
              _ResultCard(
                  icon: Icons.battery_std,
                  label: t.batteryHealth,
                  value: '✓',
                  color: AppColors.success),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const PaywallScreen(),
                          fullscreenDialog: true),
                    );
                    if (context.mounted) context.go('/dashboard');
                  },
                  child: Text(t.upgradeToPlusShort),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/dashboard'),
                child: Text(t.continueForFree,
                    style:
                        const TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ResultCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
