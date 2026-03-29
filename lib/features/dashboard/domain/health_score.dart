class HealthScore {
  final int total;
  final int batteryScore;
  final int storageScore;
  final int temperatureScore;

  const HealthScore({
    required this.total,
    required this.batteryScore,
    required this.storageScore,
    required this.temperatureScore,
  });

  factory HealthScore.calculate({
    required int batteryLevel,
    required double temperature,
    required double storageUsedPercent,
  }) {
    // Battery: 0-35 points
    int bScore;
    if (batteryLevel >= 50) {
      bScore = 35;
    } else if (batteryLevel >= 20) {
      bScore = 20 + ((batteryLevel - 20) * 15 ~/ 30);
    } else {
      bScore = batteryLevel;
    }

    // Storage: 0-40 points (most important for this app)
    int sScore;
    final freePercent = 100 - storageUsedPercent;
    if (freePercent >= 30) {
      sScore = 40;
    } else if (freePercent >= 10) {
      sScore = 15 + ((freePercent - 10) * 25 ~/ 20);
    } else {
      sScore = (freePercent * 1.5).round();
    }

    // Temperature: 0-25 points
    int tScore;
    if (temperature <= 35) {
      tScore = 25;
    } else if (temperature <= 42) {
      tScore = 25 - ((temperature - 35) * 25 ~/ 7);
    } else {
      tScore = 0;
    }

    final total = (bScore + sScore + tScore).clamp(0, 100);

    return HealthScore(
      total: total,
      batteryScore: bScore,
      storageScore: sScore,
      temperatureScore: tScore,
    );
  }

  factory HealthScore.empty() => const HealthScore(
        total: 0,
        batteryScore: 0,
        storageScore: 0,
        temperatureScore: 0,
      );

  String get statusMessage {
    if (total >= 80) return 'Cihazın sağlıklı';
    if (total >= 60) return 'İyileştirme önerisi var';
    if (total >= 40) return 'Cihazın bakıma ihtiyaç duyuyor';
    return 'Acil bakım gerekli';
  }

  bool get isGood => total >= 70;
  bool get isMedium => total >= 40 && total < 70;
  bool get isBad => total < 40;
}
