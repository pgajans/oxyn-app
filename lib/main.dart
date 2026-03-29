import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
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

  // Initialize services
  await _initializeServices();

  runApp(
    const ProviderScope(
      child: OxynApp(),
    ),
  );
}

Future<void> _initializeServices() async {
  // Firebase (uncomment when firebase_options.dart is generated)
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // RevenueCat
  await SubscriptionService().initialize();

  // Notifications
  await NotificationService().initialize();

  // Ads (AppLovin MAX)
  await AdService().initialize();
}
