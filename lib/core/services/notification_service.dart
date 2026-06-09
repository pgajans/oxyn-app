import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../features/battery/domain/battery_info.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  bool _initialized = false;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static const _channelId = 'oxyn_notifications';
  static const _channelName = 'Oxyn Notifications';
  static const _chargeChannelId = 'oxyn_charge_alarm';
  static const _chargeChannelName = 'Charge Alarm';

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _local.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _showLocalNotification(
          title: notification.title ?? 'Oxyn',
          body: notification.body ?? '',
        );
      }
    });

    _initialized = true;
    debugPrint('NotificationService initialized');
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = _channelId,
    String channelName = _channelName,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _local.show(
      id: title.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> scheduleChargeAlarm({required int targetPercent}) async {
    debugPrint('Charge alarm set for $targetPercent%');
  }

  Future<void> cancelChargeAlarm() async {
    await _local.cancel(id: 'charge_alarm'.hashCode);
    debugPrint('Charge alarm cancelled');
  }

  Future<void> scheduleWeeklyMaintenance() async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 10);
    while (scheduled.weekday != DateTime.monday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    final androidDetails = const AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    final details = NotificationDetails(
        android: androidDetails, iOS: const DarwinNotificationDetails());

    await _local.zonedSchedule(
      id: 'weekly_maintenance'.hashCode,
      title: 'Haftalık Bakım Zamanı',
      body: 'Telefonunu optimize etmek için hızlı bir tarama yap.',
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
    debugPrint('Weekly maintenance scheduled');
  }

  Future<void> scheduleOptimizationReminder() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = now.add(const Duration(hours: 12));

    final androidDetails = const AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    final details = NotificationDetails(
        android: androidDetails, iOS: const DarwinNotificationDetails());

    await _local.zonedSchedule(
      id: 'optimize_reminder'.hashCode,
      title: 'Cihaz Analizi Zamanı',
      body: 'Cihazının durumunu kontrol etme zamanı geldi. Depolama ve batarya analizini gör!',
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    debugPrint('Optimization reminder scheduled for 12 hours');
  }

  Future<void> scheduleFreeUserReminder() async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day + 1, 10, 0);

    final androidDetails = const AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    final details = NotificationDetails(
        android: androidDetails, iOS: const DarwinNotificationDetails());

    await _local.zonedSchedule(
      id: 'free_user_reminder'.hashCode,
      title: 'Telefonunu Analiz Et',
      body: 'Telefonunun sağlık durumunu kontrol etmeyi unutma!',
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    debugPrint('Free user daily reminder scheduled');
  }

  Future<void> scheduleDailyScoreNotification({
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final androidDetails = const AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    final details = NotificationDetails(
        android: androidDetails, iOS: const DarwinNotificationDetails());

    await _local.zonedSchedule(
      id: 'daily_score'.hashCode,
      title: 'Günlük Sağlık Skoru',
      body: 'Telefonunun bugünkü skorunu kontrol et.',
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    debugPrint('Daily score notification scheduled at $hour:$minute');
  }

  Future<void> showStorageWarning({required double usedPercent}) async {
    if (usedPercent > 90) {
      await _showLocalNotification(
        title: 'Depolama Uyarısı',
        body:
            'Depolaman %${usedPercent.toStringAsFixed(0)} dolu! Temizlik yaparak yer açabilirsin.',
        payload: 'storage_warning',
      );
    }
  }

  Future<void> checkBatteryAndNotify(
      BatteryInfo info, int alarmPercent) async {
    if (info.isCharging && info.level >= alarmPercent) {
      await _showLocalNotification(
        title: 'Şarj Alarmı',
        body:
            'Bataryan %${info.level} seviyesine ulaştı. Şarjı çıkarabilirsin.',
        channelId: _chargeChannelId,
        channelName: _chargeChannelName,
        payload: 'charge_alarm',
      );
    }
    if (info.isOverheating) {
      await _showLocalNotification(
        title: 'Aşırı Isınma Uyarısı',
        body:
            'Batarya sıcaklığı ${info.temperature}°C. Telefonunu dinlendir.',
        payload: 'overheat_warning',
      );
    }
  }

  Future<String?> getFCMToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('FCM token error: $e');
      return null;
    }
  }

  Future<bool> requestPermission() async {
    try {
      if (Platform.isIOS) {
        final settings = await _fcm.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        return settings.authorizationStatus == AuthorizationStatus.authorized;
      }
      final plugin = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (plugin != null) {
        final granted = await plugin.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Permission request error: $e');
      return false;
    }
  }
}
