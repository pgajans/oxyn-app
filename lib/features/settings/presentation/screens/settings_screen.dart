import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../subscription/domain/subscription_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          const SizedBox(height: AppSpacing.md),
          if (!isPremium) ...[
            _PremiumBanner(onTap: () => context.push('/paywall')),
            const SizedBox(height: AppSpacing.lg),
          ],
          _SettingsSection(
            title: 'Abonelik',
            children: [
              if (!isPremium)
                _SettingsTile(
                  icon: Icons.star,
                  iconColor: AppColors.tertiary,
                  title: 'Oxyn Plus\'a Geç',
                  subtitle: 'Tüm özelliklerin kilidini aç',
                  onTap: () => context.push('/paywall'),
                ),
              if (isPremium)
                _SettingsTile(
                  icon: Icons.star,
                  iconColor: AppColors.tertiary,
                  title: 'Aboneliğini Yönet',
                  subtitle: 'Plus aktif',
                  onTap: () => _openSubscriptionManagement(),
                ),
              _SettingsTile(
                icon: Icons.restore,
                iconColor: AppColors.primary,
                title: 'Satın Alımları Geri Yükle',
                onTap: () {
                  ref.read(subscriptionStatusProvider.notifier).restore();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Satın alımlar kontrol ediliyor...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsSection(
            title: 'Genel',
            children: [
              _SettingsTile(
                icon: Icons.language,
                iconColor: AppColors.primary,
                title: 'Dil',
                subtitle: 'Türkçe',
                onTap: () => _showLanguageDialog(context),
              ),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                iconColor: AppColors.secondary,
                title: 'Bildirimler',
                onTap: () => _openNotificationSettings(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsSection(
            title: 'Hakkında',
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                iconColor: AppColors.textSecondary,
                title: 'Versiyon',
                subtitle: '1.0.0',
                onTap: () => _showVersionDialog(context),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: AppColors.textSecondary,
                title: 'Gizlilik Politikası',
                onTap: () => _openUrl('https://oxynapp.com/privacy'),
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                iconColor: AppColors.textSecondary,
                title: 'Kullanım Şartları',
                onTap: () => _openUrl('https://oxynapp.com/terms'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Uygulamayı silmek aboneliği iptal etmez. İptal için mağaza ayarlarını kullanın.',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Dil Seçimi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageTile(name: 'Türkçe', code: 'tr', isSelected: true),
            _LanguageTile(name: 'English', code: 'en', isSelected: false),
            _LanguageTile(name: 'Español', code: 'es', isSelected: false),
            _LanguageTile(name: 'Português', code: 'pt', isSelected: false),
            _LanguageTile(name: 'العربية', code: 'ar', isSelected: false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Future<void> _showVersionDialog(BuildContext context) async {
    PackageInfo? info;
    try {
      info = await PackageInfo.fromPlatform();
    } catch (_) {}

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Versiyon Bilgisi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VersionRow('Uygulama', info?.appName ?? 'Oxyn'),
              _VersionRow('Versiyon', info?.version ?? '1.0.0'),
              _VersionRow('Build', info?.buildNumber ?? '1'),
              const SizedBox(height: 12),
              const Text(
                'Oxyn - Telefon Bakım ve Optimizasyon',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _openNotificationSettings() async {
    if (Platform.isAndroid) {
      const intent = 'android.settings.APP_NOTIFICATION_SETTINGS';
      final uri = Uri.parse('intent:#Intent;action=$intent;end');
      try {
        await launchUrl(uri);
      } catch (_) {
        await launchUrl(Uri.parse('app-settings:'));
      }
    } else {
      await launchUrl(Uri.parse('app-settings:'));
    }
  }

  Future<void> _openSubscriptionManagement() async {
    if (Platform.isAndroid) {
      await launchUrl(
        Uri.parse('https://play.google.com/store/account/subscriptions'),
        mode: LaunchMode.externalApplication,
      );
    } else {
      await launchUrl(
        Uri.parse('https://apps.apple.com/account/subscriptions'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

class _LanguageTile extends StatelessWidget {
  final String name;
  final String code;
  final bool isSelected;

  const _LanguageTile({
    required this.name,
    required this.code,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(
        name,
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
          : null,
      onTap: () {
        if (!isSelected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name dil desteği yakında aktif olacak'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        Navigator.pop(context);
      },
    );
  }
}

class _VersionRow extends StatelessWidget {
  final String label;
  final String value;

  const _VersionRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _PremiumBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.2),
              AppColors.tertiary.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bolt, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Oxyn Plus\'a Yükselt',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Sınırsız temizlik, tüm animasyonlar, reklamsız',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            )
          : null,
      trailing:
          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }
}
