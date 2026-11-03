import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/services/router.dart';
import 'core/services/notification_service.dart';
import 'core/services/feedback_service.dart';
import 'features/subscription/data/subscription_service.dart';
import 'features/subscription/domain/access_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android 15+ draws the app edge-to-edge. Do not set status/navigation
  // bar colors here — those APIs are deprecated and trip Play pre-launch.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
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

// Every step runs before the first frame, so none of them may hang the
// launch on a slow network or a device without Play services.
const _initTimeout = Duration(seconds: 6);

Future<void> _initializeServices() async {
  try {
    if (!kIsWeb) {
      await Firebase.initializeApp().timeout(_initTimeout);
    }
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  try {
    await accessGate.loadAccessCode();
  } catch (e) {
    debugPrint('Access code load error: $e');
  }

  try {
    final service = SubscriptionService();
    await service.initialize().timeout(_initTimeout);
    final status =
        await service.getSubscriptionStatus().timeout(_initTimeout);
    accessGate.update(status.isPremium);
  } catch (e) {
    debugPrint('RevenueCat init error: $e');
  }
  try {
    final notifService = NotificationService();
    await notifService.initialize().timeout(_initTimeout);
    await notifService.cancelFreeUserReminder().timeout(_initTimeout);
    if (accessGate.hasEntitlement || accessGate.hasAccessCode) {
      await notifService.scheduleOptimizationReminder().timeout(_initTimeout);
    } else {
      await notifService.cancelUsageReminders().timeout(_initTimeout);
    }
  } catch (e) {
    debugPrint('Notification init error: $e');
  }
  try {
    await FeedbackService.instance.init().timeout(_initTimeout);
  } catch (e) {
    debugPrint('Feedback init error: $e');
  }
}
