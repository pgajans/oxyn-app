import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../platform/native_platform_channel.dart';
import '../../../subscription/domain/subscription_provider.dart';

final _appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final isPremium = ref.watch(isPremiumProvider);
    final appVersion = ref.watch(_appVersionProvider).value ?? '...';
    final currentLocale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          const SizedBox(height: AppSpacing.md),
          if (!isPremium) ...[
            _PremiumBanner(
              onTap: () => context.push('/paywall'),
              title: t.upgradeToPlusLong,
              subtitle: t.unlimitedCleaningAllAnimationsNoAds,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          _SettingsSection(
            title: t.subscription,
            children: [
              if (!isPremium)
                _SettingsTile(
                  icon: Icons.star_outline,
                  iconColor: AppColors.tertiary,
                  title: t.freeVersion,
                  subtitle: t.tapToUpgradeToPremium,
                  onTap: () => context.push('/paywall'),
                ),
              if (isPremium)
                _SettingsTile(
                  icon: Icons.star,
                  iconColor: AppColors.tertiary,
                  title: t.oxynPlusActive,
                  subtitle: t.manageYourSubscription,
                  onTap: () => _openSubscriptionManagement(),
                ),
              _SettingsTile(
                icon: Icons.restore,
                iconColor: AppColors.primary,
                title: t.restorePurchases,
                onTap: () {
                  ref.read(subscriptionStatusProvider.notifier).restore();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t.checkingPurchases),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsSection(
            title: t.general,
            children: [
              _SettingsTile(
                icon: Icons.language,
                iconColor: AppColors.primary,
                title: t.language,
                subtitle: _languageDisplayName(t, currentLocale),
                onTap: () => _showLanguageDialog(context, ref, currentLocale),
              ),
              _SettingsTile(
                icon: Icons.palette_outlined,
                iconColor: AppColors.tertiary,
                title: t.theme,
                subtitle: _themeDisplayName(t, themeMode),
                onTap: () => _showThemeDialog(context, ref, themeMode),
              ),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                iconColor: AppColors.secondary,
                title: t.notifications,
                onTap: () => _openNotificationSettings(),
              ),
              _SettingsTile(
                icon: Icons.thumb_up_outlined,
                iconColor: AppColors.success,
                title: t.rateApp,
                subtitle: t.rateAppSubtitle,
                onTap: () => _requestReview(context, t),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsSection(
            title: t.features,
            children: [
              _SettingsTile(
                icon: Icons.health_and_safety,
                iconColor: AppColors.success,
                title: t.aiDeviceDoctor,
                subtitle:
                    isPremium ? t.aiAnalysisDailyOne : t.premiumFeature,
                onTap: () => context.push('/ai-doctor'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsSection(
            title: t.about,
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                iconColor: AppColors.textSecondary,
                title: t.version,
                subtitle: appVersion,
                onTap: () => _showVersionDialog(context, t),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: AppColors.textSecondary,
                title: t.privacyPolicy,
                onTap: () => context.push('/privacy'),
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                iconColor: AppColors.textSecondary,
                title: t.termsOfUse,
                onTap: () => context.push('/terms'),
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
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.cancelSubscriptionNote,
                    style: const TextStyle(
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

  String _languageDisplayName(AppLocalizations t, Locale? locale) {
    if (locale == null) return t.themeSystem;
    switch (locale.languageCode) {
      case 'en':
        return t.english;
      case 'tr':
        return t.turkish;
      case 'es':
        return t.spanish;
      case 'pt':
        return t.portuguese;
      case 'ar':
        return t.arabic;
      default:
        return locale.languageCode;
    }
  }

  String _themeDisplayName(AppLocalizations t, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return t.themeLight;
      case ThemeMode.dark:
        return t.themeDark;
      case ThemeMode.system:
        return t.themeSystem;
    }
  }

  void _showLanguageDialog(
      BuildContext context, WidgetRef ref, Locale? current) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.languageSelection),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageTile(
              name: t.themeSystem,
              isSelected: current == null,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(null);
                Navigator.pop(ctx);
              },
            ),
            const Divider(height: 1),
            _LanguageTile(
              name: 'English',
              isSelected: current?.languageCode == 'en',
              onTap: () {
                ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('en'));
                Navigator.pop(ctx);
              },
            ),
            _LanguageTile(
              name: 'Türkçe',
              isSelected: current?.languageCode == 'tr',
              onTap: () {
                ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('tr'));
                Navigator.pop(ctx);
              },
            ),
            _LanguageTile(
              name: 'Español',
              isSelected: current?.languageCode == 'es',
              onTap: () {
                ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('es'));
                Navigator.pop(ctx);
              },
            ),
            _LanguageTile(
              name: 'Português',
              isSelected: current?.languageCode == 'pt',
              onTap: () {
                ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('pt'));
                Navigator.pop(ctx);
              },
            ),
            _LanguageTile(
              name: 'العربية',
              isSelected: current?.languageCode == 'ar',
              onTap: () {
                ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('ar'));
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.close),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(
      BuildContext context, WidgetRef ref, ThemeMode current) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.themeSelection),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeTile(
              icon: Icons.brightness_auto,
              name: t.themeSystem,
              isSelected: current == ThemeMode.system,
              onTap: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setMode(ThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
            _ThemeTile(
              icon: Icons.light_mode,
              name: t.themeLight,
              isSelected: current == ThemeMode.light,
              onTap: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setMode(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            _ThemeTile(
              icon: Icons.dark_mode,
              name: t.themeDark,
              isSelected: current == ThemeMode.dark,
              onTap: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setMode(ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.close),
          ),
        ],
      ),
    );
  }

  Future<void> _requestReview(BuildContext context, AppLocalizations t) async {
    final inApp = InAppReview.instance;
    try {
      if (await inApp.isAvailable()) {
        await inApp.requestReview();
      } else {
        await inApp.openStoreListing(
          appStoreId: 'PUT_YOUR_APP_STORE_ID',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.rateAppFailed),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showVersionDialog(
      BuildContext context, AppLocalizations t) async {
    PackageInfo? info;
    try {
      info = await PackageInfo.fromPlatform();
    } catch (e) {
      debugPrint('PackageInfo error: $e');
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.versionInfo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VersionRow(t.application, info?.appName ?? 'Oxyn'),
              _VersionRow(t.version, info?.version ?? '1.0.0'),
              _VersionRow(t.build, info?.buildNumber ?? '1'),
              const SizedBox(height: 12),
              Text(
                t.oxynDescription,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.ok),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _openNotificationSettings() async {
    if (Platform.isAndroid) {
      await NativePlatformChannel.openNotificationSettings();
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
}

class _LanguageTile extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      title: Text(
        name,
        style: TextStyle(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.textTheme.bodyLarge?.color,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle,
              color: theme.colorScheme.primary, size: 20)
          : null,
      onTap: onTap,
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.icon,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.iconTheme.color?.withValues(alpha: 0.8),
      ),
      title: Text(
        name,
        style: TextStyle(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.textTheme.bodyLarge?.color,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle,
              color: theme.colorScheme.primary, size: 20)
          : null,
      onTap: onTap,
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
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  const _PremiumBanner({
    required this.onTap,
    required this.title,
    required this.subtitle,
  });

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
              child:
                  const Icon(Icons.bolt, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
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
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: isDark ? AppColors.surfaceLight : AppColors.lightDivider,
            ),
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
        style: const TextStyle(fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            )
          : null,
      trailing:
          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }
}
