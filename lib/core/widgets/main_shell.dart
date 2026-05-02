import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../localization/generated/app_localizations.dart';
import '../theme/app_colors.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/trivia')) return 1;
    if (location.startsWith('/ai-doctor')) return 2;
    if (location.startsWith('/paywall') || location.startsWith('/premium')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.dividerColor, width: 0.5),
          ),
        ),
        child: NavigationBar(
          backgroundColor: theme.colorScheme.surface,
          indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.15),
          selectedIndex: index,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) {
            switch (i) {
              case 0:
                context.go('/dashboard');
              case 1:
                context.go('/trivia');
              case 2:
                context.go('/ai-doctor-tab');
              case 3:
                context.push('/paywall');
              case 4:
                context.go('/settings-tab');
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined, size: 22),
              selectedIcon: Icon(Icons.dashboard,
                  color: theme.colorScheme.primary, size: 22),
              label: t.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.quiz_outlined, size: 22),
              selectedIcon: Icon(Icons.quiz,
                  color: theme.colorScheme.primary, size: 22),
              label: 'Trivia',
            ),
            NavigationDestination(
              icon: const Icon(Icons.health_and_safety_outlined, size: 22),
              selectedIcon: const Icon(Icons.health_and_safety,
                  color: AppColors.success, size: 22),
              label: t.doctor,
            ),
            NavigationDestination(
              icon: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.primary, AppColors.tertiary],
                ).createShader(bounds),
                child: const Icon(Icons.workspace_premium,
                    color: Colors.white, size: 22),
              ),
              selectedIcon: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.primary, AppColors.tertiary],
                ).createShader(bounds),
                child: const Icon(Icons.workspace_premium,
                    color: Colors.white, size: 22),
              ),
              label: t.premium,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined, size: 22),
              selectedIcon: Icon(Icons.settings,
                  color: theme.colorScheme.primary, size: 22),
              label: t.settings,
            ),
          ],
        ),
      ),
    );
  }
}
