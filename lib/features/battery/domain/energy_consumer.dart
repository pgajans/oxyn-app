class EnergyConsumer {
  final String appName;
  final String packageName;
  final double usagePercent;
  final Duration screenTime;

  const EnergyConsumer({
    required this.appName,
    required this.packageName,
    required this.usagePercent,
    required this.screenTime,
  });

  String get usageText => '${usagePercent.toStringAsFixed(0)}%';

  String get screenTimeText {
    final h = screenTime.inHours;
    final m = screenTime.inMinutes % 60;
    if (h > 0) return '${h}sa ${m}dk';
    return '${m}dk';
  }
}
