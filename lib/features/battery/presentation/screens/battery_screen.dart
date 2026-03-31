import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final batteryAsync = ref.watch(batteryInfoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Batarya')),
      body: batteryAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
              const SizedBox(height: 12),
              Text('Hata: $e',
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(batteryInfoProvider.notifier).refresh(),
                child: const Text('Tekrar Dene'),
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
                _BatteryLevelCard(info: info),
                const SizedBox(height: AppSpacing.md),
                _BatteryInfoGrid(info: info),
                const SizedBox(height: AppSpacing.md),
                _ChargeAlarmCard(ref: ref),
                const SizedBox(height: AppSpacing.md),
                _EnergyConsumersCard(info: info),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BatteryLevelCard extends StatelessWidget {
  final BatteryInfo info;

  const _BatteryLevelCard({required this.info});

  Color get _levelColor {
    if (info.isLow) return AppColors.danger;
    if (info.level < 50) return AppColors.secondary;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return OxynCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: info.level / 100,
                  strokeWidth: 10,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(_levelColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                children: [
                  Text(
                    info.levelText,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    info.isCharging ? 'Şarj oluyor' : 'Kalan',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (!info.isCharging)
            Text(
              'Tahmini ${info.remainingText}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          if (info.isCharging)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, color: AppColors.success, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Şarj ediliyor',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
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

class _BatteryInfoGrid extends StatelessWidget {
  final BatteryInfo info;

  const _BatteryInfoGrid({required this.info});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoTile(
            icon: Icons.thermostat,
            iconColor:
                info.isOverheating ? AppColors.danger : AppColors.secondary,
            value: info.temperatureText,
            label: 'Sıcaklık',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoTile(
            icon: Icons.favorite,
            iconColor: info.healthPercentage > 80
                ? AppColors.success
                : AppColors.danger,
            value: info.healthText,
            label: 'Sağlık',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoTile(
            icon: Icons.loop,
            iconColor: AppColors.primary,
            value: info.cycleCount > 0 ? '${info.cycleCount}' : '—',
            label: 'Döngü',
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
                child: const Icon(Icons.alarm, color: AppColors.warning, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Şarj Alarmı',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '%$percent\'de bildirim al',
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
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.surfaceLight,
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withValues(alpha: 0.15),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: percent.toDouble(),
                      min: 20,
                      max: 100,
                      divisions: 16,
                      label: '%$percent',
                      onChanged: (v) =>
                          ref.read(chargeAlarmPercentProvider.notifier).set(v.round()),
                    ),
                  ),
                ),
                const Text(
                  '%100',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Batarya sağlığı için %80 önerilir',
              style: TextStyle(
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
    return OxynCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Enerji Tüketenler',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await NativePlatformChannel.openBatterySettings();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new,
                          size: 12, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Ayarlara Git',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Detaylı batarya kullanım bilgisi için cihaz ayarlarındaki Batarya bölümünü kontrol edebilirsiniz.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.textTertiary),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'iOS ve Android güvenlik kısıtlamaları nedeniyle uygulama bazlı enerji tüketim verisi sınırlıdır.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
