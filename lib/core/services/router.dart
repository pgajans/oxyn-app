import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/battery/presentation/screens/battery_screen.dart';
import '../../features/cleaner/presentation/screens/cleaner_screen.dart';
import '../../features/performance/presentation/screens/performance_screen.dart';
import '../../features/customization/presentation/screens/customization_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../widgets/main_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/battery',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BatteryScreen(),
          ),
        ),
        GoRoute(
          path: '/cleaner',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CleanerScreen(),
          ),
        ),
        GoRoute(
          path: '/style',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CustomizationScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/performance',
      builder: (context, state) => const PerformanceScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
