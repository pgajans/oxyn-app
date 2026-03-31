import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/oxyn_card.dart';

final selectedAnimationProvider =
    NotifierProvider<SelectedAnimationNotifier, int>(
  SelectedAnimationNotifier.new,
);

class SelectedAnimationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int value) => state = value;
}

final selectedWidgetStyleProvider =
    NotifierProvider<SelectedWidgetStyleNotifier, int>(
  SelectedWidgetStyleNotifier.new,
);

class SelectedWidgetStyleNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int value) => state = value;
}

class CustomizationScreen extends ConsumerWidget {
  const CustomizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stil')),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
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
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 12),
                itemBuilder: (context, index) => _AnimationCard(
                  index: index,
                  isLocked: index > 2,
                  ref: ref,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Widget\'lar',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            _WidgetStyleGrid(ref: ref),
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
  final WidgetRef ref;

  const _AnimationCard({
    required this.index,
    required this.isLocked,
    required this.ref,
  });

  static const _animationNames = [
    'Neon Pulse',
    'Kalp Ritmi',
    'Minimalist',
    'Futuristik',
    'Aurora',
    'Galaksi',
  ];

  static const _animationIcons = [
    Icons.bolt,
    Icons.favorite,
    Icons.circle_outlined,
    Icons.rocket_launch,
    Icons.auto_awesome,
    Icons.stars,
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
    final selectedIndex = ref.watch(selectedAnimationProvider);
    final isSelected = selectedIndex == index;

    return SizedBox(
      width: 140,
      child: OxynCard(
        onTap: () {
          if (isLocked) {
            context.push('/paywall');
            return;
          }
          ref.read(selectedAnimationProvider.notifier).set(index);
          _showAnimationPreview(context);
        },
        padding: EdgeInsets.zero,
        color: isSelected
            ? _animationColors[index].withValues(alpha: 0.08)
            : null,
        child: Stack(
          children: [
            Container(
              width: 140,
              height: 200,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(AppSpacing.cardRadius),
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
                    _animationIcons[index],
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
                  if (isSelected) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Aktif',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isLocked)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            if (isSelected && !isLocked)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAnimationPreview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AnimationPreviewSheet(
        name: _animationNames[index],
        color: _animationColors[index],
        icon: _animationIcons[index],
      ),
    );
  }
}

class _AnimationPreviewSheet extends StatefulWidget {
  final String name;
  final Color color;
  final IconData icon;

  const _AnimationPreviewSheet({
    required this.name,
    required this.color,
    required this.icon,
  });

  @override
  State<_AnimationPreviewSheet> createState() => _AnimationPreviewSheetState();
}

class _AnimationPreviewSheetState extends State<_AnimationPreviewSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 150,
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withValues(alpha: 0.2),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(
                              alpha: _opacityAnimation.value * 0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Bu animasyon şarj sırasında gösterilecek',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _WidgetStyleGrid extends StatelessWidget {
  final WidgetRef ref;

  const _WidgetStyleGrid({required this.ref});

  @override
  Widget build(BuildContext context) {
    final selectedStyle = ref.watch(selectedWidgetStyleProvider);

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _WidgetPreview(
          name: 'Dairesel',
          icon: Icons.donut_large,
          index: 0,
          isActive: selectedStyle == 0,
          ref: ref,
        ),
        _WidgetPreview(
          name: 'Minimalist',
          icon: Icons.crop_square,
          index: 1,
          isActive: selectedStyle == 1,
          ref: ref,
        ),
        _WidgetPreview(
          name: 'Detaylı',
          icon: Icons.dashboard,
          index: 2,
          isActive: selectedStyle == 2,
          ref: ref,
        ),
      ],
    );
  }
}

class _WidgetPreview extends StatelessWidget {
  final String name;
  final IconData icon;
  final int index;
  final bool isActive;
  final WidgetRef ref;

  const _WidgetPreview({
    required this.name,
    required this.icon,
    required this.index,
    required this.isActive,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return OxynCard(
      onTap: () {
        ref.read(selectedWidgetStyleProvider.notifier).set(index);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name widget stili seçildi'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      color: isActive ? AppColors.primary.withValues(alpha: 0.1) : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                color:
                    isActive ? AppColors.primary : AppColors.textSecondary,
                size: 28,
              ),
              if (isActive)
                Positioned(
                  right: -12,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        size: 10, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(
              color:
                  isActive ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
