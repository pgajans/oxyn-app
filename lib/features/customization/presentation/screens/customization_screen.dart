import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oxyn_card.dart';
import '../../../subscription/domain/subscription_provider.dart';

// --- Animation data model ---

class ChargingAnimation {
  final String name;
  final IconData icon;
  final Color color;
  final bool isPremium;

  const ChargingAnimation({
    required this.name,
    required this.icon,
    required this.color,
    this.isPremium = false,
  });
}

const _animations = [
  ChargingAnimation(name: 'Neon Pulse', icon: Icons.bolt, color: AppColors.primary),
  ChargingAnimation(name: 'Kalp Ritmi', icon: Icons.favorite, color: AppColors.danger),
  ChargingAnimation(name: 'Minimalist', icon: Icons.circle_outlined, color: AppColors.textPrimary),
  ChargingAnimation(name: 'Futuristik', icon: Icons.rocket_launch, color: AppColors.tertiary, isPremium: true),
  ChargingAnimation(name: 'Aurora', icon: Icons.auto_awesome, color: AppColors.success, isPremium: true),
  ChargingAnimation(name: 'Galaksi', icon: Icons.stars, color: AppColors.secondary, isPremium: true),
];

// --- Providers with persistence ---

final selectedAnimationProvider =
    AsyncNotifierProvider<SelectedAnimationNotifier, int>(
  SelectedAnimationNotifier.new,
);

class SelectedAnimationNotifier extends AsyncNotifier<int> {
  static const _key = 'selected_animation';

  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }

  Future<void> set(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, value);
    state = AsyncValue.data(value);
  }
}

final selectedWidgetStyleProvider =
    AsyncNotifierProvider<SelectedWidgetStyleNotifier, int>(
  SelectedWidgetStyleNotifier.new,
);

class SelectedWidgetStyleNotifier extends AsyncNotifier<int> {
  static const _key = 'selected_widget_style';

  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }

  Future<void> set(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, value);
    state = AsyncValue.data(value);
  }
}

// --- Screen ---

class CustomizationScreen extends ConsumerWidget {
  const CustomizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final selectedAsync = ref.watch(selectedAnimationProvider);
    final selectedIndex = selectedAsync.value ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(t.style)),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text(
              t.chargingAnimations,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _animations.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 12),
                itemBuilder: (context, index) => _AnimationCard(
                  index: index,
                  animation: _animations[index],
                  isSelected: selectedIndex == index,
                  ref: ref,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              t.widgets,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            _WidgetStyleGrid(ref: ref),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _AnimationCard extends StatelessWidget {
  final int index;
  final ChargingAnimation animation;
  final bool isSelected;
  final WidgetRef ref;

  const _AnimationCard({
    required this.index,
    required this.animation,
    required this.isSelected,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);

    return SizedBox(
      width: 140,
      child: OxynCard(
        onTap: () {
          if (animation.isPremium && !isPremium) {
            context.push('/paywall');
            return;
          }
          ref.read(selectedAnimationProvider.notifier).set(index);
          _showAnimationPreview(context);
        },
        padding: EdgeInsets.zero,
        color: isSelected
            ? animation.color.withValues(alpha: 0.08)
            : null,
        child: Stack(
          children: [
            Container(
              width: 140,
              height: 200,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(AppSpacing.cardRadius),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    animation.color.withValues(alpha: 0.3),
                    AppColors.surface,
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MiniAnimationPreview(
                    index: index,
                    color: animation.color,
                    icon: animation.icon,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    animation.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.active,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (animation.isPremium && !isPremium)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 12, color: AppColors.tertiary),
                      SizedBox(width: 2),
                      Text(
                        'Plus',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAnimationPreview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AnimationPreviewSheet(
        index: index,
        animation: animation,
      ),
    );
  }
}

// --- Mini preview for card thumbnails ---

class _MiniAnimationPreview extends StatefulWidget {
  final int index;
  final Color color;
  final IconData icon;

  const _MiniAnimationPreview({
    required this.index,
    required this.color,
    required this.icon,
  });

  @override
  State<_MiniAnimationPreview> createState() => _MiniAnimationPreviewState();
}

class _MiniAnimationPreviewState extends State<_MiniAnimationPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return CustomPaint(
            painter: _MiniPainter(widget.index, widget.color, _ctrl.value),
            child: Center(
              child: Icon(widget.icon, color: widget.color, size: 28),
            ),
          );
        },
      ),
    );
  }
}

class _MiniPainter extends CustomPainter {
  final int index;
  final Color color;
  final double progress;

  _MiniPainter(this.index, this.color, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    switch (index) {
      case 0: // Neon Pulse
        final pulse = 0.6 + 0.4 * sin(progress * 2 * pi);
        canvas.drawCircle(
          center,
          radius * pulse,
          Paint()
            ..color = color.withValues(alpha: 0.2 * pulse)
            ..style = PaintingStyle.fill,
        );
        break;
      case 1: // Kalp Ritmi
        final beat = sin(progress * 4 * pi).abs();
        canvas.drawCircle(
          center,
          radius * (0.7 + 0.3 * beat),
          Paint()
            ..color = color.withValues(alpha: 0.15 + 0.15 * beat)
            ..style = PaintingStyle.fill,
        );
        break;
      case 2: // Minimalist
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = color.withValues(alpha: 0.1)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        final sweepAngle = progress * 2 * pi;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -pi / 2,
          sweepAngle,
          false,
          Paint()
            ..color = color.withValues(alpha: 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
        break;
      case 3: // Futuristik
        for (int i = 0; i < 3; i++) {
          final r = radius * (0.5 + i * 0.2);
          final angle = progress * 2 * pi + i * pi / 3;
          canvas.save();
          canvas.translate(center.dx, center.dy);
          canvas.rotate(angle * (i.isEven ? 1 : -1));
          canvas.translate(-center.dx, -center.dy);
          canvas.drawCircle(
            center,
            r,
            Paint()
              ..color = color.withValues(alpha: 0.15)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
          canvas.restore();
        }
        break;
      case 4: // Aurora
        for (int i = 0; i < 5; i++) {
          final wave = sin(progress * 2 * pi + i * 0.5);
          canvas.drawCircle(
            Offset(center.dx + wave * 8, center.dy + i * 3 - 6),
            radius * 0.6,
            Paint()
              ..color = color.withValues(alpha: 0.06)
              ..style = PaintingStyle.fill,
          );
        }
        break;
      case 5: // Galaksi
        for (int i = 0; i < 4; i++) {
          final angle = progress * 2 * pi + i * pi / 2;
          final x = center.dx + cos(angle) * radius * 0.6;
          final y = center.dy + sin(angle) * radius * 0.6;
          canvas.drawCircle(
            Offset(x, y),
            3,
            Paint()
              ..color = color.withValues(alpha: 0.4 + 0.3 * sin(progress * 4 * pi + i))
              ..style = PaintingStyle.fill,
          );
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _MiniPainter old) => old.progress != progress;
}

// --- Full preview sheet ---

class _AnimationPreviewSheet extends StatefulWidget {
  final int index;
  final ChargingAnimation animation;

  const _AnimationPreviewSheet({
    required this.index,
    required this.animation,
  });

  @override
  State<_AnimationPreviewSheet> createState() => _AnimationPreviewSheetState();
}

class _AnimationPreviewSheetState extends State<_AnimationPreviewSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          Text(
            widget.animation.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            width: 180,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                return CustomPaint(
                  painter: _FullAnimationPainter(
                    widget.index,
                    widget.animation.color,
                    _ctrl.value,
                  ),
                  child: Center(
                    child: Icon(
                      widget.animation.icon,
                      color: widget.animation.color,
                      size: 56,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Bu animasyon şarj sırasında gösterilecek',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _FullAnimationPainter extends CustomPainter {
  final int index;
  final Color color;
  final double t;

  _FullAnimationPainter(this.index, this.color, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    switch (index) {
      case 0: _paintNeonPulse(canvas, center, radius);
      case 1: _paintHeartbeat(canvas, center, radius);
      case 2: _paintMinimalist(canvas, center, radius);
      case 3: _paintFuturistic(canvas, center, radius);
      case 4: _paintAurora(canvas, center, radius);
      case 5: _paintGalaxy(canvas, center, radius);
    }
  }

  void _paintNeonPulse(Canvas canvas, Offset center, double radius) {
    for (int i = 0; i < 4; i++) {
      final phase = (t + i * 0.25) % 1.0;
      final r = radius * phase;
      final alpha = (1 - phase) * 0.4;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - phase),
      );
    }
    final glow = 0.5 + 0.5 * sin(t * 2 * pi);
    canvas.drawCircle(
      center,
      radius * 0.35,
      Paint()
        ..color = color.withValues(alpha: 0.1 + 0.15 * glow)
        ..style = PaintingStyle.fill,
    );
  }

  void _paintHeartbeat(Canvas canvas, Offset center, double radius) {
    final beat1 = _heartbeatCurve((t * 2) % 1.0);
    final beat2 = _heartbeatCurve((t * 2 + 0.5) % 1.0);

    canvas.drawCircle(
      center,
      radius * (0.5 + 0.3 * beat1),
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      radius * (0.3 + 0.2 * beat2),
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );

    // EKG line
    final path = Path();
    final cy = center.dy + radius * 0.6;
    path.moveTo(center.dx - radius, cy);
    for (double x = -1.0; x <= 1.0; x += 0.02) {
      final px = center.dx + x * radius;
      final phase = (x + 1.0) / 2.0;
      final shifted = (phase - t) % 1.0;
      double y = 0;
      if (shifted > 0.4 && shifted < 0.45) {
        y = -30 * sin((shifted - 0.4) / 0.05 * pi);
      } else if (shifted > 0.45 && shifted < 0.5) {
        y = 15 * sin((shifted - 0.45) / 0.05 * pi);
      }
      path.lineTo(px, cy + y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  double _heartbeatCurve(double t) {
    if (t < 0.1) return t / 0.1;
    if (t < 0.2) return 1.0 - (t - 0.1) / 0.1;
    return 0;
  }

  void _paintMinimalist(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final sweep = t * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweep,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    final pct = '${(t * 100).toInt()}%';
    final tp = TextPainter(
      text: TextSpan(
        text: pct,
        style: TextStyle(
          color: color.withValues(alpha: 0.4),
          fontSize: 16,
          fontWeight: FontWeight.w300,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy + radius * 0.3));
  }

  void _paintFuturistic(Canvas canvas, Offset center, double radius) {
    for (int i = 0; i < 3; i++) {
      final r = radius * (0.4 + i * 0.25);
      final speed = (i + 1) * (i.isEven ? 1 : -1);
      final startAngle = t * 2 * pi * speed;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        startAngle,
        pi * 0.8,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.3 - i * 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 - i * 0.5
          ..strokeCap = StrokeCap.round,
      );

      final dotAngle = startAngle + pi * 0.8;
      canvas.drawCircle(
        Offset(center.dx + cos(dotAngle) * r, center.dy + sin(dotAngle) * r),
        3,
        Paint()..color = color.withValues(alpha: 0.6),
      );
    }
  }

  void _paintAurora(Canvas canvas, Offset center, double radius) {
    final colors = [
      color,
      HSLColor.fromColor(color).withHue((HSLColor.fromColor(color).hue + 40) % 360).toColor(),
      HSLColor.fromColor(color).withHue((HSLColor.fromColor(color).hue + 80) % 360).toColor(),
    ];

    for (int layer = 0; layer < 3; layer++) {
      final path = Path();
      final yBase = center.dy - radius * 0.3 + layer * radius * 0.3;
      path.moveTo(center.dx - radius, yBase);

      for (double x = -1.0; x <= 1.0; x += 0.04) {
        final px = center.dx + x * radius;
        final wave = sin(x * 3 + t * 2 * pi + layer * 0.8) * radius * 0.15;
        path.lineTo(px, yBase + wave);
      }
      path.lineTo(center.dx + radius, center.dy + radius);
      path.lineTo(center.dx - radius, center.dy + radius);
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..color = colors[layer].withValues(alpha: 0.08)
          ..style = PaintingStyle.fill,
      );
      
      // Top edge glow
      final edgePath = Path();
      edgePath.moveTo(center.dx - radius, yBase);
      for (double x = -1.0; x <= 1.0; x += 0.04) {
        final px = center.dx + x * radius;
        final wave = sin(x * 3 + t * 2 * pi + layer * 0.8) * radius * 0.15;
        edgePath.lineTo(px, yBase + wave);
      }
      canvas.drawPath(
        edgePath,
        Paint()
          ..color = colors[layer].withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _paintGalaxy(Canvas canvas, Offset center, double radius) {
    // Spiral arms
    for (int arm = 0; arm < 2; arm++) {
      final armOffset = arm * pi;
      final path = Path();
      bool first = true;
      for (double a = 0; a < 4 * pi; a += 0.1) {
        final r = radius * 0.1 + (a / (4 * pi)) * radius * 0.8;
        final angle = a + t * 2 * pi + armOffset;
        final x = center.dx + cos(angle) * r;
        final y = center.dy + sin(angle) * r;
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    // Stars
    final rng = [0.3, 0.5, 0.7, 0.85, 0.4, 0.65, 0.9, 0.2];
    final angles = [0.5, 1.3, 2.1, 3.0, 3.8, 4.6, 5.4, 6.1];
    for (int i = 0; i < 8; i++) {
      final r = radius * rng[i];
      final angle = angles[i] + t * 2 * pi * 0.3;
      final twinkle = (sin(t * 8 * pi + i * 1.5) + 1) / 2;
      canvas.drawCircle(
        Offset(center.dx + cos(angle) * r, center.dy + sin(angle) * r),
        1.5 + twinkle * 2,
        Paint()..color = color.withValues(alpha: 0.3 + 0.4 * twinkle),
      );
    }

    // Center glow
    canvas.drawCircle(
      center,
      radius * 0.12,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(covariant _FullAnimationPainter old) => old.t != t;
}

// --- Widget Styles ---

class _WidgetStyleGrid extends StatelessWidget {
  final WidgetRef ref;

  const _WidgetStyleGrid({required this.ref});

  @override
  Widget build(BuildContext context) {
    final selectedAsync = ref.watch(selectedWidgetStyleProvider);
    final selectedStyle = selectedAsync.value ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _WidgetPreview(
          name: 'Dairesel',
          icon: Icons.donut_large,
          index: 0,
          isActive: selectedStyle == 0,
          ref: ref,
        ),
        _WidgetPreview(
          name: 'Minimalist',
          icon: Icons.crop_square,
          index: 1,
          isActive: selectedStyle == 1,
          ref: ref,
        ),
        _WidgetPreview(
          name: 'Detaylı',
          icon: Icons.dashboard,
          index: 2,
          isActive: selectedStyle == 2,
          ref: ref,
        ),
      ],
    );
  }
}

class _WidgetPreview extends StatelessWidget {
  final String name;
  final IconData icon;
  final int index;
  final bool isActive;
  final WidgetRef ref;

  const _WidgetPreview({
    required this.name,
    required this.icon,
    required this.index,
    required this.isActive,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return OxynCard(
      onTap: () {
        ref.read(selectedWidgetStyleProvider.notifier).set(index);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name widget stili seçildi'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      color: isActive ? AppColors.primary.withValues(alpha: 0.1) : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                color:
                    isActive ? AppColors.primary : AppColors.textSecondary,
                size: 28,
              ),
              if (isActive)
                Positioned(
                  right: -12,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        size: 10, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(
              color:
                  isActive ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
