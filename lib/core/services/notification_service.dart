import 'package:flutter/foundation.dart';
import '../../features/battery/domain/battery_info.dart';

/// Bildirim servisi - yerel ve push bildirimleri yönetir.
/// flutter_local_notifications ve firebase_messaging paketleri
/// pubspec.yaml'a eklendikten sonra tam entegrasyon yapılacak.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    // flutter_local_notifications ve firebase_messaging
    // kurulduğunda burada initialize edilecek
    _initialized = true;
    debugPrint('NotificationService initialized');
  }

  /// Şarj alarmı: Batarya belirli seviyeye ulaştığında bildirim gönder
  Future<void> scheduleChargeAlarm({
    required int targetPercent,
  }) async {
    debugPrint('Charge alarm scheduled for $targetPercent%');
    // flutter_local_notifications ile implement edilecek
  }

  /// Şarj alarmını iptal et
  Future<void> cancelChargeAlarm() async {
    debugPrint('Charge alarm cancelled');
  }

  /// Haftalık bakım hatırlatması (her Pazartesi 10:00)
  Future<void> scheduleWeeklyMaintenance() async {
    debugPrint('Weekly maintenance reminder scheduled');
    // flutter_local_notifications ile weekly repeating notification
  }

  /// Günlük sağlık skoru bildirimi
  Future<void> scheduleDailyScoreNotification({
    required int hour,
    required int minute,
  }) async {
    debugPrint('Daily score notification scheduled at $hour:$minute');
  }

  /// Depolama doluluk uyarısı
  Future<void> showStorageWarning({
    required double usedPercent,
  }) async {
    if (usedPercent > 90) {
      debugPrint('Storage warning: $usedPercent% used');
      // Immediate local notification
    }
  }

  /// Batarya durumu kontrol et ve gerekirse bildirim gönder
  Future<void> checkBatteryAndNotify(BatteryInfo info, int alarmPercent) async {
    if (info.isCharging && info.level >= alarmPercent) {
      debugPrint('Battery reached $alarmPercent% while charging');
      // Show charge alarm notification
    }
    if (info.isOverheating) {
      debugPrint('Battery overheating: ${info.temperature}°C');
      // Show overheating warning
    }
  }

  /// Push bildirim token'ı al (Firebase Cloud Messaging)
  Future<String?> getFCMToken() async {
    // firebase_messaging ile implement edilecek
    return null;
  }

  /// Push bildirim izni iste
  Future<bool> requestPermission() async {
    // Android 13+ ve iOS için bildirim izni
    // permission_handler ile implement edilecek
    return false;
  }
}
