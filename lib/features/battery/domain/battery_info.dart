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
        level: -1,
        isCharging: false,
        temperature: -1,
        healthPercentage: -1,
        cycleCount: -1,
        chargingSource: 'unknown',
        estimatedRemaining: Duration.zero,
      );

  /// OS/API did not provide a real health percentage (common on iOS and many Androids).
  bool get hasHealthData => healthPercentage >= 1 && healthPercentage <= 100;

  /// Charge level was actually read (0% is valid; -1 means unavailable).
  bool get hasLevelData => level >= 0 && level <= 100;

  bool get hasTemperatureData => temperature >= 0;

  String get levelText => hasLevelData ? '$level%' : '—';

  String get temperatureText =>
      hasTemperatureData ? '${temperature.toStringAsFixed(0)}°C' : '—';

  String get healthText => hasHealthData ? '$healthPercentage%' : '—';

  String get remainingText {
    if (!hasLevelData) return '—';
    if (isCharging) return 'Şarj oluyor';
    final h = estimatedRemaining.inHours;
    final m = estimatedRemaining.inMinutes % 60;
    if (h > 0) return '$h saat $m dakika';
    return '$m dakika';
  }

  bool get isLow => hasLevelData && level < 20;
  bool get isOverheating => hasTemperatureData && temperature > 40;

  String get screenOnTime {
    if (!hasLevelData) return '—';
    final h = estimatedRemaining.inHours;
    final m = estimatedRemaining.inMinutes % 60;
    if (isCharging) return '~${(level * 0.15).toStringAsFixed(0)}s';
    if (h > 0) return '~${h}s ${m}dk';
    if (m > 0) return '~${m}dk';
    return '—';
  }

  String get statusMessage {
    if (!hasLevelData) return '—';
    if (isOverheating) return 'Cihaz aşırı ısınıyor!';
    if (isLow) return 'Batarya düşük';
    if (isCharging) return 'Şarj ediliyor';
    if (level >= 80) return 'Batarya iyi durumda';
    return 'Normal';
  }
}
