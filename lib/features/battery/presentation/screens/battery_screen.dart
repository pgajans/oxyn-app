import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oxyn_card.dart';

class BatteryScreen extends StatelessWidget {
  const BatteryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batarya')),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            // Battery Level
            _BatteryLevelCard(),
            const SizedBox(height: AppSpacing.md),
            // Battery Health Info
            const _BatteryInfoGrid(),
            const SizedBox(height: AppSpacing.md),
            // Charge Alarm
            const _ChargeAlarmCard(),
            const SizedBox(height: AppSpacing.md),
            // Energy Consumers
            const _EnergyConsumersCard(),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _BatteryLevelCard extends StatelessWidget {
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
                  value: 0.72,
                  strokeWidth: 10,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                  strokeCap: StrokeCap.round,
                ),
              ),
              const Column(
                children: [
                  Text(
                    '72%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Kalan',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Tahmini 5 saat 23 dakika',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _BatteryInfoGrid extends StatelessWidget {
  const _BatteryInfoGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OxynCard(
            child: Column(
              children: [
                Icon(Icons.thermostat, color: AppColors.secondary, size: 28),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  '32°C',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'Sıcaklık',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OxynCard(
            child: Column(
              children: [
                Icon(Icons.favorite, color: AppColors.danger, size: 28),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  '%94',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'Sağlık',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OxynCard(
            child: Column(
              children: [
                Icon(Icons.loop, color: AppColors.primary, size: 28),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  '347',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'Döngü',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChargeAlarmCard extends StatelessWidget {
  const _ChargeAlarmCard();

  @override
  Widget build(BuildContext context) {
    return OxynCard(
      child: Row(
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Şarj Alarmı',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '%80\'de bildirim al',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: true,
            onChanged: (v) {},
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _EnergyConsumersCard extends StatelessWidget {
  const _EnergyConsumersCard();

  @override
  Widget build(BuildContext context) {
    return OxynCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enerji Tüketenler',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ConsumerRow(name: 'Instagram', usage: '23%', color: AppColors.danger),
          const SizedBox(height: AppSpacing.sm),
          _ConsumerRow(name: 'YouTube', usage: '18%', color: AppColors.secondary),
          const SizedBox(height: AppSpacing.sm),
          _ConsumerRow(name: 'WhatsApp', usage: '12%', color: AppColors.success),
          const SizedBox(height: AppSpacing.sm),
          _ConsumerRow(name: 'Chrome', usage: '9%', color: AppColors.primary),
        ],
      ),
    );
  }
}

class _ConsumerRow extends StatelessWidget {
  final String name;
  final String usage;
  final Color color;

  const _ConsumerRow({
    required this.name,
    required this.usage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percent = double.tryParse(usage.replaceAll('%', '')) ?? 0;

    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
        Text(
          usage,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }
}
