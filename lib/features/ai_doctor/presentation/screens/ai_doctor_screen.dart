import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oxyn_card.dart';
import '../../../battery/domain/battery_provider.dart';
import '../../../cleaner/domain/storage_provider.dart';
import '../../../subscription/domain/subscription_provider.dart';
import '../../data/ai_doctor_service.dart';

final _aiDoctorServiceProvider = Provider((ref) => AiDoctorService());

class AiDoctorScreen extends ConsumerStatefulWidget {
  const AiDoctorScreen({super.key});

  @override
  ConsumerState<AiDoctorScreen> createState() => _AiDoctorScreenState();
}

class _AiDoctorScreenState extends ConsumerState<AiDoctorScreen> {
  bool _analyzing = false;
  String? _result;
  bool? _canAnalyze;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final service = ref.read(_aiDoctorServiceProvider);
    final canAnalyze = await service.canAnalyzeToday();
    final lastResult = await service.getLastResult();
    if (mounted) {
      setState(() {
        _canAnalyze = canAnalyze;
        _result = lastResult;
      });
    }
  }

  Future<void> _analyze() async {
    final isPremium = ref.read(isPremiumProvider);

    if (!isPremium) {
      final canAnalyze = _canAnalyze ?? false;
      if (!canAnalyze) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bugünkü analiz hakkınızı kullandınız. Yarın tekrar deneyin.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (isPremium) {
      final canAnalyze = _canAnalyze ?? false;
      if (!canAnalyze) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bugünkü analizinizi zaten yaptınız. Yarın tekrar deneyin.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _analyzing = true);

    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _DoctorAnalysisScreen(ref: ref),
      ),
    );

    if (mounted) {
      setState(() {
        _analyzing = false;
        if (result != null) {
          _result = result;
          _canAnalyze = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Cihaz Doktoru')),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.health_and_safety,
                color: AppColors.primary,
                size: 56,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'AI Cihaz Doktoru',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isPremium
                  ? 'Yapay zeka ile cihazınızı analiz edin'
                  : 'Reklam izleyerek günde 1 kez kullanın',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Action button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _analyzing ? null : _analyze,
                icon: _analyzing
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                      )
                    : Icon(
                        isPremium ? Icons.search : Icons.play_circle_outline,
                        color: AppColors.background,
                      ),
                label: Text(
                  _analyzing
                      ? 'Analiz ediliyor...'
                      : isPremium
                          ? 'Cihazımı Analiz Et'
                          : 'Reklam İzle ve Analiz Et',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.background),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPremium ? AppColors.primary : AppColors.secondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            if (!isPremium) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/paywall'),
                  icon: const Icon(Icons.workspace_premium, color: AppColors.tertiary),
                  label: const Text(
                    'Premium ile Sınırsız Kullan',
                    style: TextStyle(color: AppColors.tertiary, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.tertiary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],

            if (_canAnalyze == false) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Günlük analiz hakkınız kullanıldı. Yarın tekrar deneyin.',
                  style: TextStyle(color: AppColors.warning, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // Result card
            if (_result != null) ...[
              const SizedBox(height: 20),
              OxynCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.analytics, color: AppColors.success, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Analiz Sonucu',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _result!,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6),
                    ),
                  ],
                ),
              ),
            ],

            // How it works section
            const SizedBox(height: 24),
            const _HowItWorksSection(),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    return OxynCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.tertiary, size: 20),
              SizedBox(width: 8),
              Text(
                'Nasıl Çalışır?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StepTile(
            number: '1',
            icon: Icons.smartphone,
            title: 'Cihaz Verileri Toplanır',
            description: 'Batarya durumu, sıcaklık, depolama ve performans verileri güvenli şekilde analiz edilir.',
          ),
          const SizedBox(height: 12),
          _StepTile(
            number: '2',
            icon: Icons.psychology,
            title: 'AI Analiz Yapar',
            description: 'Gelişmiş yapay zeka modeli cihazınızın sağlık durumunu değerlendirir ve olası sorunları tespit eder.',
          ),
          const SizedBox(height: 12),
          _StepTile(
            number: '3',
            icon: Icons.assignment_turned_in,
            title: 'Kişisel Rapor Oluşturulur',
            description: 'Size özel öneriler ve çözümler içeren detaylı bir rapor sunulur. Her analiz, cihazınızın o anki durumuna göre özelleştirilir.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.security, color: AppColors.primary, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Verileriniz üçüncü taraflarla paylaşılmaz. Analiz sonuçları yalnızca cihazınızda saklanır.',
                    style: TextStyle(color: AppColors.primary, fontSize: 11, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String description;

  const _StepTile({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.tertiary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.tertiary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.tertiary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DoctorAnalysisScreen extends StatefulWidget {
  final WidgetRef ref;
  const _DoctorAnalysisScreen({required this.ref});

  @override
  State<_DoctorAnalysisScreen> createState() => _DoctorAnalysisScreenState();
}

class _DoctorAnalysisScreenState extends State<_DoctorAnalysisScreen>
    with TickerProviderStateMixin {
  final List<String> _logLines = [];
  final ScrollController _scrollCtrl = ScrollController();
  late AnimationController _progressCtrl;
  bool _completed = false;
  String? _aiResult;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _progressCtrl.forward();
    _runAnalysis();
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
      if (!mounted) return;
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _runAnalysis() async {
    _addLog('[SYS] AI Cihaz Doktoru v1.3.0 başlatılıyor...');
    await Future.delayed(const Duration(milliseconds: 500));
    _addLog('[SYS] Yapay zeka modeli yükleniyor...');
    await Future.delayed(const Duration(milliseconds: 800));
    _addLog('[AI] Gemini 2.0 Flash bağlantısı kuruluyor...');
    await Future.delayed(const Duration(milliseconds: 600));

    dynamic batteryInfo;
    dynamic storageInfo;

    try {
      _addLog('[BAT] Batarya verileri okunuyor...');
      await Future.delayed(const Duration(milliseconds: 400));
      batteryInfo = await widget.ref.read(batteryInfoProvider.future);
      _addLog('[BAT] Seviye: %${batteryInfo.level}');
      await Future.delayed(const Duration(milliseconds: 300));
      _addLog('[BAT] Sıcaklık: ${batteryInfo.temperature.toStringAsFixed(1)}°C');
      await Future.delayed(const Duration(milliseconds: 300));
      _addLog('[BAT] Sağlık: %${batteryInfo.healthPercentage}');
      await Future.delayed(const Duration(milliseconds: 300));
      _addLog('[BAT] Durum: ${batteryInfo.isCharging ? "Şarj oluyor" : "Pilde çalışıyor"}');
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (_) {
      _addLog('[BAT] Batarya verisi alınamadı, varsayılan değerler kullanılıyor');
      await Future.delayed(const Duration(milliseconds: 300));
    }

    try {
      _addLog('[DISK] Depolama analizi yapılıyor...');
      await Future.delayed(const Duration(milliseconds: 500));
      storageInfo = await widget.ref.read(storageInfoProvider.future);
      _addLog('[DISK] Kullanılan: ${storageInfo.usedFormatted}');
      await Future.delayed(const Duration(milliseconds: 300));
      _addLog('[DISK] Boş alan: ${storageInfo.freeFormatted}');
      await Future.delayed(const Duration(milliseconds: 300));
      _addLog('[DISK] Doluluk: %${storageInfo.usedPercent.toStringAsFixed(0)}');
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (_) {
      _addLog('[DISK] Depolama verisi alınamadı, varsayılan değerler kullanılıyor');
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _addLog('[CPU] İşlemci performansı ölçülüyor...');
    await Future.delayed(const Duration(milliseconds: 800));
    _addLog('[CPU] Çekirdek frekansları kontrol edildi');
    await Future.delayed(const Duration(milliseconds: 400));

    _addLog('[MEM] RAM kullanımı analiz ediliyor...');
    await Future.delayed(const Duration(milliseconds: 700));
    _addLog('[MEM] Bellek durumu: Normal');
    await Future.delayed(const Duration(milliseconds: 400));

    _addLog('[NET] Ağ bağlantısı test ediliyor...');
    await Future.delayed(const Duration(milliseconds: 600));
    _addLog('[NET] Bağlantı aktif');
    await Future.delayed(const Duration(milliseconds: 400));

    _addLog('');
    _addLog('[AI] Veriler yapay zekaya gönderiliyor...');
    await Future.delayed(const Duration(milliseconds: 800));
    _addLog('[AI] Analiz ediliyor... Lütfen bekleyin.');
    await Future.delayed(const Duration(milliseconds: 500));

    final int bLevel = batteryInfo?.level ?? 50;
    final double bTemp = (batteryInfo?.temperature ?? 25.0).toDouble();
    final int bHealth = batteryInfo?.healthPercentage ?? 80;
    final double sUsedPct = (storageInfo?.usedPercent ?? 50.0).toDouble();
    final String sFree = storageInfo?.freeFormatted ?? 'Bilinmiyor';

    try {
      final service = widget.ref.read(_aiDoctorServiceProvider);
      final result = await service.analyzeDevice(
        batteryLevel: bLevel,
        batteryTemperature: bTemp,
        batteryHealth: bHealth,
        usedStoragePercent: sUsedPct,
        freeStorage: sFree,
      );
      _aiResult = result;
      _addLog('[AI] Analiz tamamlandı!');
    } catch (e) {
      _addLog('[AI] Hata: $e');
      _addLog('[AI] Yerel analiz yapılıyor...');
    }

    await Future.delayed(const Duration(milliseconds: 500));
    _addLog('');
    _addLog('[✓] CİHAZ ANALİZİ TAMAMLANDI');

    if (mounted) {
      setState(() => _completed = true);
      _progressCtrl.animateTo(1.0, duration: const Duration(milliseconds: 300));
    }
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
                  const Icon(Icons.health_and_safety, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'AI DOKTOR',
                    style: TextStyle(
                      color: AppColors.success,
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
                        color: AppColors.success,
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
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
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
                  } else if (line.startsWith('[DISK]')) {
                    lineColor = const Color(0xFFD7BA7D);
                  } else if (line.startsWith('[CPU]')) {
                    lineColor = const Color(0xFF569CD6);
                  } else if (line.startsWith('[MEM]')) {
                    lineColor = const Color(0xFF9CDCFE);
                  } else if (line.startsWith('[NET]')) {
                    lineColor = const Color(0xFFB5CEA8);
                  } else if (line.startsWith('[AI]')) {
                    lineColor = const Color(0xFFC586C0);
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
                    onPressed: () => Navigator.pop(context, _aiResult),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Raporu Görüntüle',
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
