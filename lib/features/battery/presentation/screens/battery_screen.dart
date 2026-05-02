import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oxyn_card.dart';
import '../../../../platform/native_platform_channel.dart';
import '../../domain/battery_info.dart';
import '../../domain/battery_provider.dart';

class BatteryScreen extends ConsumerWidget {
  const BatteryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final batteryAsync = ref.watch(batteryInfoProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.battery)),
      body: batteryAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.danger, size: 48),
              const SizedBox(height: 12),
              Text(t.error(e.toString()),
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(batteryInfoProvider.notifier).refresh(),
                child: Text(t.tryAgain),
              ),
            ],
          ),
        ),
        data: (info) => RefreshIndicator(
          onRefresh: () => ref.read(batteryInfoProvider.notifier).refresh(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.screenPadding,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.md),
                _BatteryHealthBar(info: info),
                const SizedBox(height: AppSpacing.md),
                _BatteryInfoGrid(info: info),
                const SizedBox(height: AppSpacing.md),
                _ChargeAlarmCard(ref: ref),
                const SizedBox(height: AppSpacing.md),
                _BatteryReportButton(info: info),
                const SizedBox(height: AppSpacing.md),
                _EnergyConsumersCard(info: info),
                const SizedBox(height: AppSpacing.md),
                _NotificationSettingsCard(),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BatteryHealthBar extends StatelessWidget {
  final BatteryInfo info;
  const _BatteryHealthBar({required this.info});

  Color _healthColor(int health) {
    if (health >= 80) return AppColors.success;
    if (health >= 50) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final healthColor = _healthColor(info.healthPercentage);
    final isAndroid = Platform.isAndroid;

    return OxynCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: healthColor, size: 22),
              const SizedBox(width: 8),
              Text(
                isAndroid ? t.estimatedBatteryHealth : t.batteryHealth,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                '%${info.healthPercentage}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: healthColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: info.healthPercentage / 100,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(healthColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HealthDataTile(
                  icon: Icons.timer_outlined,
                  label: t.estimatedRemainingLabel,
                  value: info.isCharging ? t.charging : info.remainingText,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HealthDataTile(
                  icon: Icons.thermostat,
                  label: t.batteryTemperatureLabel,
                  value: info.temperatureText,
                  color: info.isOverheating
                      ? AppColors.danger
                      : AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.batteryHealthExplain,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      height: 1.3,
                    ),
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

class _HealthDataTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HealthDataTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BatteryInfoGrid extends StatelessWidget {
  final BatteryInfo info;
  const _BatteryInfoGrid({required this.info});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isAndroid = Platform.isAndroid;

    return Row(
      children: [
        Expanded(
          child: _InfoTile(
            icon: Icons.battery_std,
            iconColor: info.isLow ? AppColors.danger : AppColors.success,
            value: info.levelText,
            label: t.chargeLevelLabel,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoTile(
            icon: isAndroid ? Icons.screen_lock_portrait : Icons.loop,
            iconColor: AppColors.primary,
            value: isAndroid
                ? info.screenOnTime
                : (info.cycleCount > 0 ? '${info.cycleCount}' : '—'),
            label: isAndroid ? t.screenOnTimeLabel : t.cycle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoTile(
            icon: info.isCharging ? Icons.bolt : Icons.power_off,
            iconColor:
                info.isCharging ? AppColors.success : AppColors.textTertiary,
            value: info.isCharging ? t.yes : t.no,
            label: t.charging,
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return OxynCard(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ChargeAlarmCard extends StatelessWidget {
  final WidgetRef ref;
  const _ChargeAlarmCard({required this.ref});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final enabled = ref.watch(chargeAlarmEnabledProvider);
    final percent = ref.watch(chargeAlarmPercentProvider);

    return OxynCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.alarm,
                    color: AppColors.warning, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.chargeAlarm,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      t.notifyAt('%$percent'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: (v) =>
                    ref.read(chargeAlarmEnabledProvider.notifier).toggle(v),
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Text(
                  '%20',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textTertiary),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.surfaceLight,
                      thumbColor: AppColors.primary,
                      overlayColor:
                          AppColors.primary.withValues(alpha: 0.15),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: percent.toDouble(),
                      min: 20,
                      max: 100,
                      divisions: 16,
                      label: '%$percent',
                      onChanged: (v) => ref
                          .read(chargeAlarmPercentProvider.notifier)
                          .set(v.round()),
                    ),
                  ),
                ),
                const Text(
                  '%100',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              t.chargeAlarmHint,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EnergyConsumersCard extends StatelessWidget {
  final BatteryInfo info;
  const _EnergyConsumersCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return OxynCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.energyConsumers,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showInfoPopup(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline,
                      size: 16, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await NativePlatformChannel.openBatterySettings();
              },
              icon: const Icon(Icons.battery_saver, size: 18),
              label: Text(t.goToBatterySettings),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                foregroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoPopup(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline,
                color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(t.energyConsumers, style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          '${t.batterySecurityNote} ${t.batterySettingsHint}',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.ok),
          ),
        ],
      ),
    );
  }
}

class _NotificationSettingsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return OxynCard(
      onTap: () async {
        await NativePlatformChannel.openNotificationSettings();
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_active,
                color: AppColors.secondary, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.manageNotifications,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.notificationsDrainBattery,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _BatteryReportButton extends StatefulWidget {
  final BatteryInfo info;
  const _BatteryReportButton({required this.info});

  @override
  State<_BatteryReportButton> createState() => _BatteryReportButtonState();
}

class _BatteryReportButtonState extends State<_BatteryReportButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  bool _showReport = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _generateReport(AppLocalizations t) {
    final lines = <String>[];

    if (widget.info.healthPercentage >= 80) {
      lines.add(t.reportContentGood(widget.info.healthPercentage));
    } else if (widget.info.healthPercentage >= 60) {
      lines.add(t.reportContentMedium(widget.info.healthPercentage));
    } else {
      lines.add(t.reportContentBad(widget.info.healthPercentage));
    }

    if (widget.info.temperature > 40) {
      lines.add(t.reportTempHigh(widget.info.temperatureText));
    } else if (widget.info.temperature > 35) {
      lines.add(t.reportTempWarm(widget.info.temperatureText));
    } else {
      lines.add(t.reportTempNormal(widget.info.temperatureText));
    }

    if (widget.info.level < 20) {
      lines.add(t.reportLevelLow(widget.info.level));
    }

    lines.add(t.reportLifeTip);

    return lines.join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (_showReport) {
      return OxynCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.assignment,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  t.batteryReportTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _generateReport(t),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => setState(() => _showReport = false),
              icon: const Icon(Icons.close, size: 16),
              label: Text(t.close),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final glowAlpha = 0.15 + (_pulseCtrl.value * 0.2);
        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: glowAlpha),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _showReport = true),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment,
                      color: AppColors.background, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    t.batteryReportTitle,
                    style: const TextStyle(
                      color: AppColors.background,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
