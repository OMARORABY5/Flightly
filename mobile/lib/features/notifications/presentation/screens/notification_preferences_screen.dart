import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/features/notifications/domain/models/notification_preferences.dart';
import 'package:flightly/features/notifications/domain/providers/notification_preferences_provider.dart';

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsState = ref.watch(notificationPreferencesNotifierProvider);
    final notifier = ref.read(notificationPreferencesNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Notification Preferences', style: AppTextStyles.headingMedium),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: prefsState.when(
        data: (prefs) => _buildBody(context, prefs, notifier),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Failed to load preferences', style: AppTextStyles.bodyLarge),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(notificationPreferencesNotifierProvider),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationPreferences prefs, NotificationPreferencesNotifier notifier) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'CHOOSE WHAT YOU WANT TO BE NOTIFIED ABOUT',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, letterSpacing: 1),
          ),
        ),
        _buildSwitchTile(
          title: 'Booking Updates',
          subtitle: 'Flight confirmations, check-in reminders, gate changes.',
          value: prefs.bookingUpdates,
          onChanged: (val) => notifier.updatePreferences(prefs.copyWith(bookingUpdates: val)),
        ),
        _buildSwitchTile(
          title: 'Price Alerts',
          subtitle: 'Be notified when prices drop for flights in your watchlist.',
          value: prefs.priceAlerts,
          onChanged: (val) => notifier.updatePreferences(prefs.copyWith(priceAlerts: val)),
        ),
        _buildSwitchTile(
          title: 'Schedule Updates',
          subtitle: 'Alerts for delays, cancellations, or itinerary changes.',
          value: prefs.scheduleUpdates,
          onChanged: (val) => notifier.updatePreferences(prefs.copyWith(scheduleUpdates: val)),
        ),
        _buildSwitchTile(
          title: 'Promotions & Offers',
          subtitle: 'Exclusive deals, discounts, and travel inspiration.',
          value: prefs.promotional,
          onChanged: (val) => notifier.updatePreferences(prefs.copyWith(promotional: val)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Divider(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'SMART TRAVEL REMINDERS',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, letterSpacing: 1),
          ),
        ),
        _buildSwitchTile(
          title: 'Flight Reminders',
          subtitle: 'Get reminded 24h, 12h, 6h, and 2h before your departure.',
          value: prefs.flightReminders,
          onChanged: (val) async {
            notifier.updatePreferences(prefs.copyWith(flightReminders: val));
            final sp = await SharedPreferences.getInstance();
            await sp.setBool('pref_flight_reminders', val);
          },
        ),
        _buildSwitchTile(
          title: 'Travel Advisory',
          subtitle: 'Baggage allowance tips and recommended airport arrival time.',
          value: prefs.travelAdvisory,
          onChanged: (val) async {
            notifier.updatePreferences(prefs.copyWith(travelAdvisory: val));
            final sp = await SharedPreferences.getInstance();
            await sp.setBool('pref_travel_advisory', val);
          },
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 2),
      child: SwitchListTile(
        title: Text(title, style: AppTextStyles.bodyLarge),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
