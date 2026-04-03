import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/services/router.dart';
import 'core/services/notification_service.dart';
import 'core/services/ad_service.dart';
import 'features/subscription/data/subscription_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF141B2D),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await _initializeServices();

  final showOnboarding = !(await hasSeenOnboarding());
  final router = buildRouter(showOnboarding: showOnboarding);

  runApp(
    ProviderScope(
      child: OxynApp(router: router),
    ),
  );
}

Future<void> _initializeServices() async {
  try {
    if (!kIsWeb) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  try {
    await SubscriptionService().initialize();
  } catch (e) {
    debugPrint('RevenueCat init error: $e');
  }
  try {
    final notifService = NotificationService();
    await notifService.initialize();
    await notifService.scheduleOptimizationReminder();
    await notifService.scheduleFreeUserReminder();
  } catch (e) {
    debugPrint('Notification init error: $e');
  }
  try {
    await AdService().initialize();
  } catch (e) {
    debugPrint('Ad init error: $e');
  }
}
