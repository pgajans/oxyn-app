import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/oxyn_card.dart';
import '../../../subscription/domain/subscription_provider.dart';

/// Hold-to-charge battery experience.
///
/// Press and hold: a lightning bolt grows inside the battery while it fills
/// from 0 → 100% over [_holdDuration]. At 100% a thunder strike flashes the
/// screen with a heavy haptic + zap sound and shows "Battery checked".
///
/// Deliberately makes **no health promises** (no "battery repaired/extended")
/// to stay within store policy — it only reports that a check was performed.
///
/// Free users get one check per 24h; premium users are unlimited.
class BatteryCheckButton extends ConsumerStatefulWidget {
  const BatteryCheckButton({super.key});

  @override
  ConsumerState<BatteryCheckButton> createState() => _BatteryCheckButtonState();
}

class _BatteryCheckButtonState extends ConsumerState<BatteryCheckButton>
    with TickerProviderStateMixin {
  static const _holdDuration = Duration(seconds: 10);
  static const _lastCheckKey = 'battery_check_last_ms';
  static const _cooldown = Duration(hours: 24);

  late final AnimationController _fillCtrl;
  late final AnimationController _flashCtrl;
  late final AnimationController _waveCtrl;

  bool _holding = false;
  bool _completed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _fillCtrl = AnimationController(vsync: this, duration: _holdDuration)
      ..addStatusListener(_onFillStatus);
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _fillCtrl.dispose();
    _flashCtrl.dispose();
    _waveCtrl.dispose();
    feedback.stopLoop();
    super.dispose();
  }

  void _onFillStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_completed) {
      _onComplete();
    }
  }

  Future<bool> _canCheck() async {
    if (ref.read(isPremiumProvider)) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(_lastCheckKey);
      if (last == null) return true;
      final elapsed = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(last));
      return elapsed >= _cooldown;
    } catch (_) {
      return true;
    }
  }

  Future<void> _markUsed() async {
    if (ref.read(isPremiumProvider)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  Future<void> _onPointerDown() async {
    if (_busy || _holding) return;
    if (_completed) {
      // allow starting a fresh check
      setState(() => _completed = false);
      _fillCtrl.value = 0;
    }
    _busy = true;
    final allowed = await _canCheck();
    _busy = false;
    if (!mounted) return;
    if (!allowed) {
      _showLockedSheet();
      return;
    }
    setState(() => _holding = true);
    feedback.tap();
    feedback.startLoop();
    _fillCtrl.forward();
  }

  void _onPointerUp() {
    if (!_holding || _completed) return;
    setState(() => _holding = false);
    feedback.stopLoop();
    // drain back down for a satisfying "release" feel
    _fillCtrl.animateBack(
      0,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeIn,
    );
  }

  Future<void> _onComplete() async {
    setState(() {
      _holding = false;
      _completed = true;
    });
    feedback.stopLoop();
    feedback.strike();
    _flashCtrl.forward(from: 0);
    await _markUsed();
    // Double thunder rumble
    await Future.delayed(const Duration(milliseconds: 130));
    if (mounted) feedback.strike();
  }

  void _showLockedSheet() {
    final t = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
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
                color: Theme.of(ctx).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.bolt, color: AppColors.tertiary, size: 48),
            const SizedBox(height: 16),
            Text(
              t.batteryCheckLockedTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              t.batteryCheckLockedDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  feedback.tap();
                  Navigator.pop(ctx);
                  context.push('/paywall');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tertiary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(t.upgradeToPremiumShort),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                t.giveUp,
                style: const TextStyle(color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return OxynCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          Text(
            t.batteryCheckTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          Listener(
            onPointerDown: (_) => _onPointerDown(),
            onPointerUp: (_) => _onPointerUp(),
            onPointerCancel: (_) => _onPointerUp(),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 160,
              height: 260,
              child: AnimatedBuilder(
                animation: Listenable.merge([_fillCtrl, _flashCtrl, _waveCtrl]),
                builder: (context, _) {
                  final fill = _fillCtrl.value;
                  final flash = _flashCtrl.value;
                  // scale pulse on strike
                  final strikeScale = 1 + (math.sin(flash * math.pi) * 0.06);
                  return Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // glow behind battery
                      if (flash > 0)
                        Container(
                          width: 200,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(
                                  alpha: 0.5 * (1 - flash),
                                ),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      Transform.scale(
                        scale: strikeScale,
                        child: CustomPaint(
                          size: const Size(160, 260),
                          painter: _BatteryPainter(
                            fill: fill,
                            wavePhase: _waveCtrl.value * 2 * math.pi,
                            strike: flash,
                          ),
                        ),
                      ),
                      // percentage
                      Positioned(
                        bottom: 84,
                        child: Text(
                          '${(fill * 100).round()}%',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: fill > 0.5
                                ? AppColors.background
                                : AppColors.textPrimary,
                            shadows: const [
                              Shadow(blurRadius: 8, color: Colors.black45),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _completed
                ? Column(
                    key: const ValueKey('done'),
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppColors.success, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            t.batteryCheckDone,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t.batteryCheckDoneDesc,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                : Text(
                    _holding
                        ? t.batteryCheckReleaseEarly
                        : t.batteryCheckHoldHint,
                    key: ValueKey(_holding ? 'holding' : 'idle'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _holding
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BatteryPainter extends CustomPainter {
  final double fill; // 0..1
  final double wavePhase;
  final double strike; // 0..1 flash progress

  _BatteryPainter({
    required this.fill,
    required this.wavePhase,
    required this.strike,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final termW = w * 0.34;
    final termH = h * 0.045;
    final bodyTop = termH;
    final bodyRadius = Radius.circular(w * 0.16);

    final bodyRect = RRect.fromLTRBR(0, bodyTop, w, h, bodyRadius);
    final innerRect = RRect.fromLTRBR(
      6,
      bodyTop + 6,
      w - 6,
      h - 6,
      Radius.circular(w * 0.13),
    );

    // Terminal (top nub)
    final termRect = RRect.fromLTRBAndCorners(
      w / 2 - termW / 2,
      0,
      w / 2 + termW / 2,
      termH + 2,
      topLeft: Radius.circular(w * 0.05),
      topRight: Radius.circular(w * 0.05),
    );
    canvas.drawRRect(
      termRect,
      Paint()..color = AppColors.primary.withValues(alpha: 0.9),
    );

    // Inner background
    canvas.drawRRect(
      innerRect,
      Paint()..color = AppColors.surfaceLight,
    );

    // Fill (liquid) from bottom up with a wavy crest
    if (fill > 0) {
      canvas.save();
      canvas.clipRRect(innerRect);
      final iLeft = innerRect.left;
      final iRight = innerRect.right;
      final iBottom = innerRect.bottom;
      final iTop = innerRect.top;
      final fillHeight = (iBottom - iTop) * fill;
      final fillTop = iBottom - fillHeight;
      final amp = (fill > 0.98) ? 0.0 : 4.0;

      final path = Path()..moveTo(iLeft, iBottom);
      path.lineTo(iLeft, fillTop);
      const steps = 24;
      for (int i = 0; i <= steps; i++) {
        final x = iLeft + (iRight - iLeft) * (i / steps);
        final y = fillTop +
            math.sin((i / steps) * 2 * math.pi * 1.6 + wavePhase) * amp;
        path.lineTo(x, y);
      }
      path.lineTo(iRight, iBottom);
      path.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.success,
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ).createShader(Rect.fromLTRB(iLeft, fillTop, iRight, iBottom));
      canvas.drawPath(path, fillPaint);
      canvas.restore();
    }

    // Lightning bolt (grows with fill, blazes on strike)
    final boltVisible = (fill * 0.9 + strike * 0.6).clamp(0.0, 1.0);
    if (boltVisible > 0.02) {
      final boltScale = 0.55 + fill * 0.45 + strike * 0.15;
      final bolt = _boltPath(Offset(w / 2, h / 2 + termH / 2), h * 0.34 * boltScale);
      // glow
      canvas.drawPath(
        bolt,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.55 * boltVisible)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      // core
      canvas.drawPath(
        bolt,
        Paint()
          ..color = Color.lerp(
            const Color(0xFFFFF176),
            Colors.white,
            strike,
          )!
              .withValues(alpha: (0.85 + strike * 0.15).clamp(0.0, 1.0)),
      );
    }

    // Body border on top
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Color.lerp(
          AppColors.primary,
          Colors.white,
          strike,
        )!,
    );

    // Screen flash overlay (a quick white veil that fades out)
    if (strike > 0) {
      final veil = math.sin(strike * math.pi); // 0→1→0
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: 0.4 * veil),
      );
    }
  }

  /// Classic lightning bolt centered on [center] with total height [h].
  Path _boltPath(Offset center, double h) {
    final unit = h / 2;
    // points relative to center, normalized to [-1,1] roughly
    final pts = <Offset>[
      const Offset(0.15, -1.0),
      const Offset(-0.45, 0.12),
      const Offset(-0.02, 0.12),
      const Offset(-0.18, 1.0),
      const Offset(0.5, -0.22),
      const Offset(0.05, -0.22),
      const Offset(0.42, -1.0),
    ];
    final path = Path();
    for (int i = 0; i < pts.length; i++) {
      final p = Offset(
        center.dx + pts[i].dx * unit,
        center.dy + pts[i].dy * unit,
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_BatteryPainter old) =>
      old.fill != fill || old.wavePhase != wavePhase || old.strike != strike;
}
