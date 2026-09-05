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

  bool get hasScore => total >= 0;

  factory HealthScore.unavailable() => const HealthScore(
        total: -1,
        batteryScore: 0,
        storageScore: 0,
        temperatureScore: 0,
      );

  factory HealthScore.calculate({
    required int batteryLevel,
    required double temperature,
    required double storageUsedPercent,
    bool hasTemperature = true,
  }) {
    // Battery: 0-35 points (more granular)
    int bScore;
    if (batteryLevel >= 90) {
      bScore = 35;
    } else if (batteryLevel >= 70) {
      bScore = 28 + ((batteryLevel - 70) * 7 ~/ 20);
    } else if (batteryLevel >= 50) {
      bScore = 20 + ((batteryLevel - 50) * 8 ~/ 20);
    } else if (batteryLevel >= 30) {
      bScore = 12 + ((batteryLevel - 30) * 8 ~/ 20);
    } else if (batteryLevel >= 15) {
      bScore = 5 + ((batteryLevel - 15) * 7 ~/ 15);
    } else {
      bScore = (batteryLevel * 5 ~/ 15);
    }

    // Storage: 0-40 points (more granular)
    int sScore;
    final freePercent = 100 - storageUsedPercent;
    if (freePercent >= 50) {
      sScore = 40;
    } else if (freePercent >= 35) {
      sScore = 32 + ((freePercent - 35) * 8 ~/ 15);
    } else if (freePercent >= 20) {
      sScore = 22 + ((freePercent - 20) * 10 ~/ 15);
    } else if (freePercent >= 10) {
      sScore = 10 + ((freePercent - 10) * 12 ~/ 10);
    } else {
      sScore = (freePercent).round();
    }

    // Temperature: 0-25 points (more granular)
    int tScore;
    if (temperature <= 0) {
      tScore = 25;
    } else if (temperature <= 28) {
      tScore = 25;
    } else if (temperature <= 33) {
      tScore = 20 + ((33 - temperature) * 5 ~/ 5);
    } else if (temperature <= 38) {
      tScore = 12 + ((38 - temperature) * 8 ~/ 5);
    } else if (temperature <= 42) {
      tScore = 4 + ((42 - temperature) * 8 ~/ 4);
    } else {
      tScore = 0;
    }

    final raw = bScore + sScore + (hasTemperature ? tScore : 0);
    final maxPoints = 35 + 40 + (hasTemperature ? 25 : 0);
    final total = ((raw / maxPoints) * 100).round().clamp(0, 100);

    return HealthScore(
      total: total,
      batteryScore: bScore,
      storageScore: sScore,
      temperatureScore: hasTemperature ? tScore : 0,
    );
  }

  factory HealthScore.empty() => HealthScore.unavailable();

  /// 0 = healthy, 1 = good, 2 = improvement, 3 = maintenance, 4 = urgent.
  /// -1 = not enough data to score.
  int get statusLevel {
    if (!hasScore) return -1;
    if (total >= 85) return 0;
    if (total >= 70) return 1;
    if (total >= 55) return 2;
    if (total >= 40) return 3;
    return 4;
  }

  bool get isGood => hasScore && total >= 70;
  bool get isMedium => hasScore && total >= 40 && total < 70;
  bool get isBad => hasScore && total < 40;
}
