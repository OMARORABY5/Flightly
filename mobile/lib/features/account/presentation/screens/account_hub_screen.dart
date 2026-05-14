// account_hub_screen.dart — FLIGHTLY Account Hub Screen
// The main menu for the Account tab.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/core/utils/helpers.dart';
import 'package:flightly/core/presentation/widgets/premium_app_bar.dart';
import 'package:flightly/features/auth/providers/auth_provider.dart';
import 'package:flightly/features/account/domain/providers/account_provider.dart';

class AccountHubScreen extends ConsumerWidget {
  const AccountHubScreen({super.key});

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,
      title: 'Sign Out',
      desc: 'Are you sure you want to sign out? Any unsaved edits will be lost.',
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        ref.read(authProvider.notifier).logout();
        context.go('/auth/login');
      },
      btnOkText: 'Sign Out',
      btnOkColor: AppColors.error,
    ).show();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState is! AuthAuthenticated) {
      return _buildGuestState(context);
    }

    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceElevated,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text('Account', style: AppTextStyles.headingMedium),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileProvider);
          await ref.read(profileProvider.future);
        },
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            // ── Profile Header ─────────────────────────────────────────────
            profileAsync.when(
              data: (profile) {
                if (profile == null) return const SizedBox();
                return GestureDetector(
                  onTap: () => context.push('/account/profile'),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          backgroundImage: AppHelpers.getAvatarProvider(profile.photoUrl),
                          child: profile.photoUrl == null
                              ? const Icon(LucideIcons.user, size: 30, color: AppColors.primary)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                profile.displayName ?? 'Traveler',
                                style: AppTextStyles.headingMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Failed to load profile', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
              ),
            ),
            const SizedBox(height: 32),

            // ── Menu Items ─────────────────────────────────────────────────
            _buildMenuGroup('Travel', [
              _MenuItem(
                icon: LucideIcons.plane,
                title: 'My Bookings',
                onTap: () => context.go('/home', extra: {'tabIndex': 1}),
              ),
              _MenuItem(
                icon: LucideIcons.users,
                title: 'Passengers',
                onTap: () => context.push('/account/passengers'),
              ),
              _MenuItem(
                icon: LucideIcons.heart,
                title: 'Saved Flights',
                onTap: () => context.go('/home', extra: {'tabIndex': 2}),
              ),
            ]),
            
            _buildMenuGroup('Preferences & Payment', [
              _MenuItem(
                icon: LucideIcons.wallet,
                title: 'My Wallet',
                onTap: () => context.push('/wallet'),
              ),
              _MenuItem(
                icon: LucideIcons.creditCard,
                title: 'My Cards',
                onTap: () => context.push('/account/cards'),
              ),
              _MenuItem(
                icon: LucideIcons.settings,
                title: 'Settings',
                onTap: () => context.push('/account/settings'),
              ),
              _MenuItem(
                icon: LucideIcons.bell,
                title: 'Notification Preferences',
                onTap: () => context.push('/notification-preferences'),
              ),
            ]),

            _buildMenuGroup('Security', [
              _MenuItem(
                icon: LucideIcons.lock,
                title: 'Change Password',
                onTap: () => context.push('/account/password'),
              ),
            ]),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () => _showSignOutDialog(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  foregroundColor: AppColors.error,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Sign Out', style: AppTextStyles.button.copyWith(color: AppColors.error)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text('FLIGHTLY v1.0.0', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestState(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceElevated,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text('Account', style: AppTextStyles.headingMedium),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: const Icon(LucideIcons.user, size: 60, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Text('Log in to manage your profile', style: AppTextStyles.headingMedium, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Access your saved passengers, payment methods, and account settings.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.push('/auth/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Log In', style: AppTextStyles.button),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGroup(String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(title, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(item.icon, color: AppColors.textPrimary, size: 22),
                    title: Text(item.title, style: AppTextStyles.bodyLarge),
                    trailing: const Icon(LucideIcons.chevronRight, color: AppColors.textSecondary, size: 20),
                    onTap: item.onTap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  if (!isLast)
                    const Divider(color: AppColors.surfaceBorder, height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _MenuItem({required this.icon, required this.title, required this.onTap});
}
