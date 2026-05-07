// settings_screen.dart — FLIGHTLY Settings Screen
// UI for Language, Country, Currency, Notification toggles

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/features/account/domain/providers/account_provider.dart';
import 'package:flightly/features/account/domain/models/settings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;

  Future<void> _updateSetting(String key, String value) async {
    final currentSettings = ref.read(settingsProvider).value;
    if (currentSettings == null) return;

    Settings newSettings = currentSettings;
    if (key == 'language') newSettings = currentSettings.copyWith(language: value);
    if (key == 'country') newSettings = currentSettings.copyWith(country: value);
    if (key == 'currency') newSettings = currentSettings.copyWith(currency: value);

    setState(() => _isLoading = true);

    try {
      await ref.read(accountRepositoryProvider).updateSettings(newSettings);
      ref.invalidate(settingsProvider);
      
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(message: 'Settings updated successfully'),
        );
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: 'Failed to update settings: $e'),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Settings', style: AppTextStyles.headingMedium),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error))),
        data: (settings) {
          if (settings == null) return const Center(child: Text('No settings available'));

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                children: [
                  _buildSectionTitle('Preferences'),
                  _buildSettingItem(
                    title: 'Language',
                    subtitle: settings.language.toUpperCase(),
                    icon: LucideIcons.languages,
                    onTap: () => _showOptionsDialog(
                      'Language',
                      ['en', 'ar', 'fr'],
                      settings.language,
                      (val) => _updateSetting('language', val),
                    ),
                  ),
                  _buildSettingItem(
                    title: 'Country/Region',
                    subtitle: settings.country,
                    icon: LucideIcons.mapPin,
                    onTap: () => _showOptionsDialog(
                      'Country',
                      ['Egypt', 'United States', 'UAE', 'United Kingdom'],
                      settings.country,
                      (val) => _updateSetting('country', val),
                    ),
                  ),
                  _buildSettingItem(
                    title: 'Currency',
                    subtitle: settings.currency.toUpperCase(),
                    icon: LucideIcons.coins,
                    onTap: () => _showOptionsDialog(
                      'Currency',
                      ['USD', 'EGP', 'AED', 'EUR', 'GBP'],
                      settings.currency,
                      (val) => _updateSetting('currency', val),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle('App Info'),
                  _buildSettingItem(
                    title: 'About FLIGHTLY',
                    icon: LucideIcons.info,
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    title: 'Terms of Service',
                    icon: LucideIcons.fileText,
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    title: 'Privacy Policy',
                    icon: LucideIcons.shield,
                    onTap: () {},
                  ),
                ],
              ),
              if (_isLoading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black12,
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Text(title, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
    );
  }

  Widget _buildSettingItem({
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textPrimary, size: 22),
        title: Text(title, style: AppTextStyles.bodyLarge),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (subtitle != null)
              Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            if (subtitle != null) const SizedBox(width: 8),
            const Icon(LucideIcons.chevronRight, color: AppColors.textSecondary, size: 20),
          ],
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showOptionsDialog(String title, List<String> options, String currentValue, Function(String) onSelect) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Select $title', style: AppTextStyles.headingMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((option) {
                return RadioListTile<String>(
                  title: Text(option, style: AppTextStyles.bodyLarge),
                  value: option,
                  groupValue: currentValue,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    Navigator.pop(ctx);
                    if (val != null && val != currentValue) onSelect(val);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: AppTextStyles.button.copyWith(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }
}
