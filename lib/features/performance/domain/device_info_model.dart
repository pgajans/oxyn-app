class DeviceInfoModel {
  final String model;
  final String osVersion;
  final String totalStorage;
  final String usedStorage;
  final String freeStorage;
  final double cpuTemperature;
  final String ramUsage;
  final String totalRam;

  const DeviceInfoModel({
    required this.model,
    required this.osVersion,
    required this.totalStorage,
    required this.usedStorage,
    required this.freeStorage,
    required this.cpuTemperature,
    required this.ramUsage,
    required this.totalRam,
  });

  factory DeviceInfoModel.empty() => const DeviceInfoModel(
        model: '—',
        osVersion: '—',
        totalStorage: '—',
        usedStorage: '—',
        freeStorage: '—',
        cpuTemperature: 0,
        ramUsage: '—',
        totalRam: '—',
      );

  String get cpuTempText => '${cpuTemperature.toStringAsFixed(0)}°C';
  bool get isCpuHot => cpuTemperature > 42;
}
