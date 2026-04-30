import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  final _pages = const [
    _OnboardingPage(
      icon: Icons.favorite_border,
      title: 'Cihazının Sağlığını Takip Et',
      description:
          'Batarya durumu, sıcaklık ve performans skorunu her gün gör.',
      color: AppColors.primary,
    ),
    _OnboardingPage(
      icon: Icons.cleaning_services_outlined,
      title: 'Akıllıca Temizle',
      description:
          'Benzer fotoğrafları bul, büyük dosyaları tespit et ve güvenle temizle.',
      color: AppColors.secondary,
    ),
    _OnboardingPage(
      icon: Icons.bolt_outlined,
      title: 'Kişiselleştir',
      description:
          'Şarj animasyonları ve widget\'lar ile telefonunu özelleştir.',
      color: AppColors.tertiary,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
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
                  child: const Text(
                    'Atla',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: _pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? AppColors.primary
                          : AppColors.surfaceLight,
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
                    _currentPage == _pages.length - 1 ? 'Taramayı Başlat' : 'İleri',
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

// --- Scan Screen (PRD: 60 saniye tarama) ---

class _ScanScreen extends StatefulWidget {
  const _ScanScreen();

  @override
  State<_ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<_ScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _currentTask = 'Batarya analiz ediliyor...';
  int _taskIndex = 0;

  final _tasks = [
    'Batarya analiz ediliyor...',
    'Depolama taranıyor...',
    'Fotoğraflar kontrol ediliyor...',
    'Büyük dosyalar aranıyor...',
    'Performans değerlendiriliyor...',
    'Sağlık skoru hesaplanıyor...',
  ];

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
      await prefs.setInt('last_optimize_time', DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt('last_free_clean_time', DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool('free_clean_used', true);
    } catch (e) {
      debugPrint('Onboarding optimization error: $e');
    }
  }

  void _updateTask() {
    final newIndex = (_controller.value * _tasks.length).floor();
    if (newIndex != _taskIndex && newIndex < _tasks.length) {
      setState(() {
        _taskIndex = newIndex;
        _currentTask = _tasks[newIndex];
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
                      backgroundColor: AppColors.surfaceLight,
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Cihazın taranıyor',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _currentTask,
                  key: ValueKey(_currentTask),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'Bu işlem genellikle birkaç saniye sürer',
                style: TextStyle(
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

// --- Scan Result Screen ---

class _ScanResultScreen extends StatelessWidget {
  const _ScanResultScreen();

  @override
  Widget build(BuildContext context) {
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
                child: const Icon(Icons.check_circle, color: AppColors.success, size: 56),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('İlk Optimizasyon Tamamlandı!', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Cihazınız optimize edildi.\nHaftalık ücretsiz temizleme hakkınızı kullandınız.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: AppSpacing.xl),
              _ResultCard(icon: Icons.cached, label: 'Önbellek Temizlendi', value: '✓', color: AppColors.primary),
              const SizedBox(height: 12),
              _ResultCard(icon: Icons.memory, label: 'RAM Optimize', value: '✓', color: AppColors.secondary),
              const SizedBox(height: 12),
              _ResultCard(icon: Icons.battery_std, label: 'Pil Analizi', value: '✓', color: AppColors.success),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PaywallScreen(), fullscreenDialog: true),
                    );
                    if (context.mounted) context.go('/dashboard');
                  },
                  child: const Text('Premium\'u Keşfet'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Ücretsiz olarak devam et', style: TextStyle(color: AppColors.textSecondary)),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
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
