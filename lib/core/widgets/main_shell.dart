import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.surfaceLight, width: 0.5),
          ),
        ),
        child: NavigationBar(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.15),
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
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, size: 22),
              selectedIcon: Icon(Icons.dashboard, color: AppColors.primary, size: 22),
              label: 'Ana Sayfa',
            ),
            const NavigationDestination(
              icon: Icon(Icons.quiz_outlined, size: 22),
              selectedIcon: Icon(Icons.quiz, color: AppColors.primary, size: 22),
              label: 'Trivia',
            ),
            const NavigationDestination(
              icon: Icon(Icons.health_and_safety_outlined, size: 22),
              selectedIcon: Icon(Icons.health_and_safety, color: AppColors.success, size: 22),
              label: 'Doktor',
            ),
            NavigationDestination(
              icon: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.primary, AppColors.tertiary],
                ).createShader(bounds),
                child: const Icon(Icons.workspace_premium, color: Colors.white, size: 22),
              ),
              selectedIcon: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.primary, AppColors.tertiary],
                ).createShader(bounds),
                child: const Icon(Icons.workspace_premium, color: Colors.white, size: 22),
              ),
              label: 'Premium',
            ),
            const NavigationDestination(
              icon: Icon(Icons.settings_outlined, size: 22),
              selectedIcon: Icon(Icons.settings, color: AppColors.primary, size: 22),
              label: 'Ayarlar',
            ),
          ],
        ),
      ),
    );
  }
}
