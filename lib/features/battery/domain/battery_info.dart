class BatteryInfo {
  final int level;
  final bool isCharging;
  final double temperature;
  final int healthPercentage;
  final int cycleCount;
  final String chargingSource;
  final Duration estimatedRemaining;

  const BatteryInfo({
    required this.level,
    required this.isCharging,
    required this.temperature,
    required this.healthPercentage,
    required this.cycleCount,
    required this.chargingSource,
    required this.estimatedRemaining,
  });

  factory BatteryInfo.empty() => const BatteryInfo(
        level: 0,
        isCharging: false,
        temperature: 0,
        healthPercentage: 100,
        cycleCount: 0,
        chargingSource: 'unknown',
        estimatedRemaining: Duration.zero,
      );

  String get levelText => '$level%';

  String get temperatureText => '${temperature.toStringAsFixed(0)}°C';

  String get healthText => '$healthPercentage%';

  String get remainingText {
    if (isCharging) return 'Şarj oluyor';
    final h = estimatedRemaining.inHours;
    final m = estimatedRemaining.inMinutes % 60;
    if (h > 0) return '$h saat $m dakika';
    return '$m dakika';
  }

  bool get isLow => level < 20;
  bool get isOverheating => temperature > 40;

  String get statusMessage {
    if (isOverheating) return 'Cihaz aşırı ısınıyor!';
    if (isLow) return 'Batarya düşük';
    if (isCharging) return 'Şarj ediliyor';
    if (level >= 80) return 'Batarya iyi durumda';
    return 'Normal';
  }
}
