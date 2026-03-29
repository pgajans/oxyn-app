import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oxyn_card.dart';

class CustomizationScreen extends StatelessWidget {
  const CustomizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stil')),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            // Charging Animations Section
            Text(
              'Şarj Animasyonları',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 6,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _AnimationCard(
                  index: index,
                  isLocked: index > 2,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Widgets Section
            Text(
              'Widget\'lar',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            const _WidgetStyleGrid(),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _AnimationCard extends StatelessWidget {
  final int index;
  final bool isLocked;

  const _AnimationCard({required this.index, required this.isLocked});

  static const _animationNames = [
    'Neon Pulse',
    'Kalp Ritmi',
    'Minimalist',
    'Futuristik',
    'Aurora',
    'Galaksi',
  ];

  static const _animationColors = [
    AppColors.primary,
    AppColors.danger,
    AppColors.textPrimary,
    AppColors.tertiary,
    AppColors.success,
    AppColors.secondary,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: OxynCard(
        onTap: () {
          // TODO: Preview animation
        },
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            Container(
              width: 140,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _animationColors[index].withValues(alpha: 0.3),
                    AppColors.surface,
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bolt,
                    color: _animationColors[index],
                    size: 48,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _animationNames[index],
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isLocked)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 12, color: AppColors.tertiary),
                      SizedBox(width: 2),
                      Text(
                        'Plus',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WidgetStyleGrid extends StatelessWidget {
  const _WidgetStyleGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: const [
        _WidgetPreview(name: 'Dairesel', isActive: true),
        _WidgetPreview(name: 'Minimalist', isActive: false),
        _WidgetPreview(name: 'Detaylı', isActive: false),
      ],
    );
  }
}

class _WidgetPreview extends StatelessWidget {
  final String name;
  final bool isActive;

  const _WidgetPreview({required this.name, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return OxynCard(
      onTap: () {},
      color: isActive ? AppColors.primary.withValues(alpha: 0.1) : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.widgets_outlined,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
