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

// #region agent log
void _debugLog(String location, String message, [Map<String, dynamic>? data]) {
  debugPrint('[DEBUG-53de45] $location | $message${data != null ? ' | $data' : ''}');
}
// #endregion

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
  // #region agent log
  _debugLog('main.dart:initServices', 'Starting service initialization');
  // #endregion

  try {
    if (!kIsWeb) {
      await Firebase.initializeApp();
    }
    // #region agent log
    _debugLog('main.dart:firebase', 'Firebase initialized OK', {"hypothesisId": "B"});
    // #endregion
  } catch (e) {
    // #region agent log
    _debugLog('main.dart:firebase', 'Firebase FAILED', {"error": "$e", "hypothesisId": "B"});
    // #endregion
    debugPrint('Firebase init error: $e');
  }

  try {
    await SubscriptionService().initialize();
    // #region agent log
    _debugLog('main.dart:revenuecat', 'RevenueCat initialized OK', {"hypothesisId": "B"});
    // #endregion
  } catch (e) {
    // #region agent log
    _debugLog('main.dart:revenuecat', 'RevenueCat FAILED', {"error": "$e", "hypothesisId": "B"});
    // #endregion
    debugPrint('RevenueCat init error: $e');
  }
  try {
    await NotificationService().initialize();
    // #region agent log
    _debugLog('main.dart:notification', 'NotificationService initialized OK', {"hypothesisId": "C"});
    // #endregion
  } catch (e) {
    // #region agent log
    _debugLog('main.dart:notification', 'NotificationService FAILED', {"error": "$e", "hypothesisId": "C"});
    // #endregion
    debugPrint('Notification init error: $e');
  }
  try {
    await AdService().initialize();
    // #region agent log
    _debugLog('main.dart:ad', 'AdService initialized OK');
    // #endregion
  } catch (e) {
    // #region agent log
    _debugLog('main.dart:ad', 'AdService FAILED', {"error": "$e"});
    // #endregion
    debugPrint('Ad init error: $e');
  }

  // #region agent log
  _debugLog('main.dart:initServices', 'All services initialized');
  // #endregion
}
