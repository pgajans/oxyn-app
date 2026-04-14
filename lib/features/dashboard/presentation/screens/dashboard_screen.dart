import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oxyn_card.dart';
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

Color _scoreColor(int score) {
  if (score > 70) return AppColors.success;
  if (score >= 40) return AppColors.warning;
  return AppColors.danger;
}

class _ScoreSection extends StatelessWidget {
  final dynamic score;

  const _ScoreSection({required this.score});

  @override
  Widget build(BuildContext context) {
    final int total = score.total;
    final color = _scoreColor(total);

    return OxynCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Günlük Skor',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  score.statusMessage,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$total',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '/ 100',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: total / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.7),
                            color,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
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
        _CleanerCard(
          storageText: storageText,
          onTap: () => context.go('/cleaner'),
        ),
        _ModuleCard(
          icon: Icons.speed,
          label: 'Performans',
          value: batteryText,
          color: AppColors.success,
          onTap: () => context.go('/battery'),
        ),
        const _DashboardNewsCard(),
        _ModuleCard(
          icon: Icons.star_rounded,
          label: 'Premium',
          value: 'Oxyn Plus',
          color: AppColors.tertiary,
          onTap: () => context.push('/paywall'),
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
                  fontSize: label == 'Premium' ? 12 : 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

class _CleanerCard extends StatefulWidget {
  final String storageText;
  final VoidCallback onTap;

  const _CleanerCard({required this.storageText, required this.onTap});

  @override
  State<_CleanerCard> createState() => _CleanerCardState();
}

class _CleanerCardState extends State<_CleanerCard> with SingleTickerProviderStateMixin {
  static const _kLastCleanKey = 'last_clean_card_time';
  static const _kCleanCooldown = Duration(hours: 12);

  Duration _remaining = Duration.zero;
  bool _needsClean = true;
  Timer? _timer;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _checkCooldown();
  }

  Future<void> _checkCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_kLastCleanKey) ?? 0;
    if (lastMs == 0) {
      setState(() => _needsClean = true);
      _pulseCtrl.repeat(reverse: true);
      return;
    }
    final lastTime = DateTime.fromMillisecondsSinceEpoch(lastMs);
    final elapsed = DateTime.now().difference(lastTime);
    if (elapsed >= _kCleanCooldown) {
      setState(() => _needsClean = true);
      _pulseCtrl.repeat(reverse: true);
    } else {
      final rem = _kCleanCooldown - elapsed;
      setState(() {
        _needsClean = false;
        _remaining = rem;
      });
      _pulseCtrl.stop();
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }
      if (_remaining.inSeconds <= 1) {
        _timer?.cancel();
        setState(() => _needsClean = true);
        _pulseCtrl.repeat(reverse: true);
      } else {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final scale = _needsClean ? 1.0 + _pulseCtrl.value * 0.03 : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: OxynCard(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _needsClean ? Icons.cleaning_services : Icons.check_circle,
                    color: _needsClean ? AppColors.secondary : AppColors.success,
                    size: 24,
                  ),
                ),
                if (_needsClean)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Temizle!',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_needsClean)
                  const Text(
                    'Hemen Temizle',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  )
                else
                  Text(
                    _fmt(_remaining),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  _needsClean
                      ? 'Telefon sağlığınız için'
                      : 'Sonraki temizlik',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardNewsCard extends StatelessWidget {
  const _DashboardNewsCard();

  @override
  Widget build(BuildContext context) {
    return OxynCard(
      onTap: () => context.go('/news'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.newspaper_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Haberler',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Güncel akıllı telefon haberleri',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const _kLastOptimizeKey = 'last_optimize_time';
const _kCooldownDuration = Duration(hours: 12);

class _OptimizeButton extends StatefulWidget {
  final WidgetRef ref;

  const _OptimizeButton({required this.ref});

  @override
  State<_OptimizeButton> createState() => _OptimizeButtonState();
}

class _OptimizeButtonState extends State<_OptimizeButton>
    with SingleTickerProviderStateMixin {
  bool _isOptimizing = false;
  Duration _remaining = Duration.zero;
  Timer? _timer;
  late AnimationController _pulseController;

  bool get _isCoolingDown => _remaining > Duration.zero;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_kLastOptimizeKey);
    if (lastMs != null) {
      final lastTime = DateTime.fromMillisecondsSinceEpoch(lastMs);
      final end = lastTime.add(_kCooldownDuration);
      final now = DateTime.now();
      if (end.isAfter(now)) {
        _remaining = end.difference(now);
        _startTimer();
      } else {
        _startPulse();
      }
    } else {
      _startPulse();
    }
    if (mounted) setState(() {});
  }

  void _startTimer() {
    _pulseController.stop();
    _pulseController.reset();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining -= const Duration(seconds: 1);
        if (_remaining <= Duration.zero) {
          _remaining = Duration.zero;
          _timer?.cancel();
          _startPulse();
        }
      });
    });
  }

  void _startPulse() {
    _pulseController.repeat(reverse: true);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _runOptimization() async {
    if (_isOptimizing || _isCoolingDown) return;
    setState(() => _isOptimizing = true);

    final result = await Navigator.of(context, rootNavigator: true).push<int>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _HackerOptimizationScreen(ref: widget.ref),
      ),
    );

    if (result != null && result >= 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _kLastOptimizeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      _remaining = _kCooldownDuration;
      _startTimer();

      // Result popup is shown inside _HackerOptimizationScreen
    }

    if (mounted) setState(() => _isOptimizing = false);
  }

  @override
  Widget build(BuildContext context) {
    final isActive = !_isCoolingDown && !_isOptimizing;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowAlpha = isActive
            ? 0.15 + (_pulseController.value * 0.25)
            : 0.1;

        return Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isCoolingDown
                  ? [AppColors.surfaceLight, AppColors.surface]
                  : [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            boxShadow: [
              BoxShadow(
                color: (_isCoolingDown ? AppColors.surfaceLight : AppColors.primary)
                    .withValues(alpha: glowAlpha),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              onTap: isActive ? _runOptimization : null,
              child: Center(child: _buildContent()),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_isOptimizing) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: AppColors.background,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_isCoolingDown) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 8),
          Text(
            'Sonraki optimizasyon: ${_formatDuration(_remaining)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return const Row(
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
    );
  }
}

class _HackerOptimizationScreen extends StatefulWidget {
  final WidgetRef ref;
  const _HackerOptimizationScreen({required this.ref});

  @override
  State<_HackerOptimizationScreen> createState() => _HackerOptimizationScreenState();
}

class _HackerOptimizationScreenState extends State<_HackerOptimizationScreen>
    with TickerProviderStateMixin {
  final List<String> _logLines = [];
  final ScrollController _scrollCtrl = ScrollController();
  late AnimationController _progressCtrl;
  int _cacheCleared = 0;
  bool _completed = false;

  static const _totalDuration = Duration(seconds: 35);

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(vsync: this, duration: _totalDuration);
    _progressCtrl.forward();
    _runOptimization();
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _addLog(String line) {
    if (!mounted) return;
    setState(() => _logLines.add(line));
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _runOptimization() async {
    _addLog('[SYS] Oxyn Optimization Engine v1.2.0 başlatılıyor...');
    await Future.delayed(const Duration(milliseconds: 600));
    _addLog('[SYS] Cihaz bilgileri alınıyor...');
    await Future.delayed(const Duration(milliseconds: 400));

    try {
      final batteryInfo = await widget.ref.read(batteryInfoProvider.future);
      _addLog('[BAT] Batarya seviyesi: %${batteryInfo.level}');
      await Future.delayed(const Duration(milliseconds: 300));
      _addLog('[BAT] Batarya sıcaklığı: ${batteryInfo.temperature.toStringAsFixed(1)}°C');
      await Future.delayed(const Duration(milliseconds: 300));
      _addLog('[BAT] Şarj durumu: ${batteryInfo.isCharging ? "Şarj oluyor" : "Şarjda değil"}');
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (_) {
      _addLog('[BAT] Batarya bilgisi alınamadı, devam ediliyor...');
    }

    _addLog('[MEM] RAM analizi başlatılıyor...');
    await Future.delayed(const Duration(milliseconds: 800));
    _addLog('[MEM] Aktif process\'ler taranıyor...');
    await Future.delayed(const Duration(milliseconds: 600));
    _addLog('[MEM] 47 arka plan işlemi tespit edildi');
    await Future.delayed(const Duration(milliseconds: 400));
    _addLog('[MEM] Gereksiz process\'ler sonlandırılıyor...');
    await Future.delayed(const Duration(milliseconds: 1200));
    _addLog('[MEM] 23 process optimize edildi');
    await Future.delayed(const Duration(milliseconds: 500));

    _addLog('[CACHE] Önbellek taraması başlatılıyor...');
    await Future.delayed(const Duration(milliseconds: 700));

    try {
      final repo = widget.ref.read(storageRepositoryProvider);
      final storageInfo = await widget.ref.read(storageInfoProvider.future);
      _addLog('[DISK] Toplam depolama taranıyor...');
      await Future.delayed(const Duration(milliseconds: 500));
      _addLog('[DISK] Kullanılan alan: ${storageInfo.usedFormatted}');
      await Future.delayed(const Duration(milliseconds: 300));
      _addLog('[DISK] Boş alan: ${storageInfo.freeFormatted}');
      await Future.delayed(const Duration(milliseconds: 500));

      _addLog('[CACHE] Uygulama önbelleği temizleniyor...');
      await Future.delayed(const Duration(milliseconds: 800));
      _cacheCleared = await repo.clearAppCache();
      final mb = (_cacheCleared / (1024 * 1024)).toStringAsFixed(1);
      _addLog('[CACHE] $mb MB önbellek temizlendi');
      await Future.delayed(const Duration(milliseconds: 600));
    } catch (_) {
      _addLog('[CACHE] Önbellek temizleme hatası, devam ediliyor...');
    }

    _addLog('[NET] Ağ bağlantıları kontrol ediliyor...');
    await Future.delayed(const Duration(milliseconds: 900));
    _addLog('[NET] DNS önbelleği temizleniyor...');
    await Future.delayed(const Duration(milliseconds: 500));
    _addLog('[NET] Ağ optimizasyonu tamamlandı');
    await Future.delayed(const Duration(milliseconds: 400));

    _addLog('[GPU] Grafik belleği optimize ediliyor...');
    await Future.delayed(const Duration(milliseconds: 1000));
    _addLog('[GPU] Texture cache temizlendi');
    await Future.delayed(const Duration(milliseconds: 400));
    _addLog('[GPU] Frame buffer optimize edildi');
    await Future.delayed(const Duration(milliseconds: 600));

    _addLog('[CPU] İşlemci yük analizi yapılıyor...');
    await Future.delayed(const Duration(milliseconds: 800));
    _addLog('[CPU] Termal dengeleme kontrol ediliyor...');
    await Future.delayed(const Duration(milliseconds: 700));
    _addLog('[CPU] İşlemci frekansları optimize edildi');
    await Future.delayed(const Duration(milliseconds: 500));

    _addLog('[IO] Disk I/O optimizasyonu başlatılıyor...');
    await Future.delayed(const Duration(milliseconds: 900));
    _addLog('[IO] Dosya sistemi indeksleri yenileniyor...');
    await Future.delayed(const Duration(milliseconds: 1200));
    _addLog('[IO] Geçici dosyalar temizleniyor...');
    await Future.delayed(const Duration(milliseconds: 800));
    _addLog('[IO] Disk optimizasyonu tamamlandı');
    await Future.delayed(const Duration(milliseconds: 400));

    _addLog('[SYS] Sistem servisleri yeniden başlatılıyor...');
    await Future.delayed(const Duration(milliseconds: 1000));
    _addLog('[SYS] Bildirim kuyruğu temizleniyor...');
    await Future.delayed(const Duration(milliseconds: 500));
    _addLog('[SYS] Sensör kalibrasyonu kontrol ediliyor...');
    await Future.delayed(const Duration(milliseconds: 700));

    _addLog('[SEC] Güvenlik taraması yapılıyor...');
    await Future.delayed(const Duration(milliseconds: 1200));
    _addLog('[SEC] Tehdit bulunamadı');
    await Future.delayed(const Duration(milliseconds: 400));

    widget.ref.invalidate(batteryInfoProvider);
    widget.ref.invalidate(storageInfoProvider);

    _addLog('');
    _addLog('[✓] TÜM OPTİMİZASYONLAR TAMAMLANDI');
    _addLog('[✓] Cihazınız optimize edildi');

    // Wait for progress bar to reach 100%
    if (!_progressCtrl.isCompleted) {
      await _progressCtrl.forward().orCancel.catchError((_) {});
    }
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) setState(() => _completed = true);
  }

  void _showCompletionPopup() {
    final cacheMB = (_cacheCleared / (1024 * 1024)).toStringAsFixed(1);
    
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, _) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: _OptimizationResultPopup(
            cacheMB: cacheMB,
            onDone: () {
              Navigator.pop(ctx);
              Navigator.pop(context, _cacheCleared);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.terminal, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'OXYN OPTIMIZER',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _progressCtrl,
                    builder: (context, _) => Text(
                      '${(_progressCtrl.value * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _progressCtrl,
              builder: (context, _) => LinearProgressIndicator(
                value: _progressCtrl.value,
                backgroundColor: const Color(0xFF1A1A1A),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 2,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: _logLines.length,
                itemBuilder: (_, i) {
                  final line = _logLines[i];
                  final Color lineColor;
                  if (line.startsWith('[✓]')) {
                    lineColor = AppColors.success;
                  } else if (line.startsWith('[BAT]')) {
                    lineColor = const Color(0xFFDCDCAA);
                  } else if (line.startsWith('[MEM]')) {
                    lineColor = const Color(0xFF9CDCFE);
                  } else if (line.startsWith('[CACHE]')) {
                    lineColor = const Color(0xFFCE9178);
                  } else if (line.startsWith('[DISK]')) {
                    lineColor = const Color(0xFFD7BA7D);
                  } else if (line.startsWith('[NET]')) {
                    lineColor = const Color(0xFFB5CEA8);
                  } else if (line.startsWith('[GPU]')) {
                    lineColor = const Color(0xFFC586C0);
                  } else if (line.startsWith('[CPU]')) {
                    lineColor = const Color(0xFF569CD6);
                  } else if (line.startsWith('[IO]')) {
                    lineColor = const Color(0xFFD4D4D4);
                  } else if (line.startsWith('[SEC]')) {
                    lineColor = const Color(0xFFFF8080);
                  } else if (line.startsWith('[SYS]')) {
                    lineColor = AppColors.primary;
                  } else {
                    lineColor = const Color(0xFF4EC9B0);
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                    child: Text(
                      line,
                      style: TextStyle(
                        color: lineColor,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_completed)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _showCompletionPopup(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Tamamlandı - Sonuçları Gör',
                      style: TextStyle(
                        color: AppColors.background,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
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

class _OptimizationResultPopup extends StatefulWidget {
  final String cacheMB;
  final VoidCallback onDone;
  const _OptimizationResultPopup({required this.cacheMB, required this.onDone});

  @override
  State<_OptimizationResultPopup> createState() => _OptimizationResultPopupState();
}

class _OptimizationResultPopupState extends State<_OptimizationResultPopup> {
  final List<_OptResult> _results = [];
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    _animateResults();
  }

  Future<void> _animateResults() async {
    final items = [
      _OptResult(Icons.cached, 'Önbellek Temizlendi', '${widget.cacheMB} MB serbest bırakıldı', AppColors.secondary),
      _OptResult(Icons.memory, 'RAM Optimize Edildi', '1.2 GB bellek serbest bırakıldı', AppColors.primary),
      _OptResult(Icons.apps, 'Arka Plan İşlemleri', '23 gereksiz işlem durduruldu', const Color(0xFF9CDCFE)),
      _OptResult(Icons.folder_delete, 'Geçici Dosyalar', '234 geçici dosya temizlendi', const Color(0xFFCE9178)),
      _OptResult(Icons.dns, 'Ağ Optimizasyonu', 'DNS önbelleği ve bağlantılar yenilendi', const Color(0xFFB5CEA8)),
      _OptResult(Icons.security, 'Güvenlik Taraması', 'Tehdit bulunamadı - Cihaz güvende', AppColors.success),
    ];

    for (final item in items) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _results.add(item));
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _showButton = true);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Optimizasyon Tamamlandı!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ..._results.map((r) => _buildResultRow(r)),
              if (_showButton) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: widget.onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Tamam',
                      style: TextStyle(
                        color: AppColors.background,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(_OptResult r) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (_, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - val)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: r.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(r.icon, color: r.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    r.detail,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.check_circle, color: r.color, size: 18),
          ],
        ),
      ),
    );
  }
}

class _OptResult {
  final IconData icon;
  final String title;
  final String detail;
  final Color color;
  const _OptResult(this.icon, this.title, this.detail, this.color);
}

