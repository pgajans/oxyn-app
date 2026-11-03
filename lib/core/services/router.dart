import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/battery/presentation/screens/battery_screen.dart';
import '../../features/cleaner/presentation/screens/cleaner_screen.dart';
import '../../features/performance/presentation/screens/performance_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/subscription/domain/access_gate.dart';
import '../../features/subscription/presentation/screens/paywall_screen.dart';
import '../../features/legal/presentation/screens/privacy_policy_screen.dart';
import '../../features/legal/presentation/screens/terms_screen.dart';
import '../../features/trivia/presentation/screens/trivia_screen.dart';
import '../../features/ai_doctor/presentation/screens/ai_doctor_screen.dart';
import '../../features/news/presentation/screens/news_screen.dart';
import '../widgets/main_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

const _onboardingSeenKey = 'onboarding_seen';

Future<bool> hasSeenOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_onboardingSeenKey) ?? false;
}

Future<void> markOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_onboardingSeenKey, true);
}

/// Routes a user without an active subscription may still open. Privacy and
/// terms must stay reachable from the paywall (App Store 3.1.2).
const _routesWithoutSubscription = {
  '/onboarding',
  '/subscribe',
  '/privacy',
  '/terms',
};

GoRouter buildRouter({required bool showOnboarding}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: showOnboarding
        ? '/onboarding'
        : (accessGate.hasAccess ? '/dashboard' : '/subscribe'),
    refreshListenable: accessGate,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (!accessGate.hasAccess) {
        return _routesWithoutSubscription.contains(location)
            ? null
            : '/subscribe';
      }
      if (location == '/subscribe') return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/subscribe',
        builder: (context, state) => const PaywallScreen(hardGate: true),
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
            path: '/trivia',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TriviaScreen(),
            ),
          ),
          GoRoute(
            path: '/ai-doctor-tab',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AiDoctorScreen(),
            ),
          ),
          GoRoute(
            path: '/settings-tab',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
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
            path: '/news',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NewsScreen(),
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
      GoRoute(
        path: '/ai-doctor',
        builder: (context, state) => const AiDoctorScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/paywall',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const PaywallScreen(),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
    ],
  );
}
