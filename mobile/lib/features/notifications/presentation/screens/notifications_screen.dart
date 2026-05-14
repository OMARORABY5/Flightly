import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/features/auth/providers/auth_provider.dart';
import 'package:flightly/features/notifications/domain/models/app_notification.dart';
import 'package:flightly/features/notifications/domain/providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState is! AuthAuthenticated) {
      return _buildGuestState(context);
    }

    final notificationState = ref.watch(notificationNotifierProvider);
    final notifier = ref.read(notificationNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.surfaceElevated,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Notifications', style: AppTextStyles.headingMedium),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (notificationState.notifications.isNotEmpty && notificationState.unreadCount > 0)
            TextButton(
              onPressed: () => notifier.markAllAsRead(),
              child: Text('Mark all as read', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.refresh(),
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: _buildBody(context, notificationState, notifier),
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationState state, NotificationNotifier notifier) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Failed to load notifications', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => notifier.refresh(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.notifications.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.surfaceBorder),
      itemBuilder: (context, index) {
        final notification = state.notifications[index];
        return _buildNotificationItem(context, notification, notifier);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.bellOff, size: 64, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Text("You're all caught up!", style: AppTextStyles.headingMedium),
          const SizedBox(height: 8),
          Text(
            "No new notifications at the moment.",
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestState(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceElevated,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Notifications', style: AppTextStyles.headingMedium),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
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
                child: const Icon(LucideIcons.bellRing, size: 60, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Text('Log in to see updates', style: AppTextStyles.headingMedium, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Sign in to receive alerts about your flights, gate changes, and exclusive deals.',
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

  Widget _buildNotificationItem(BuildContext context, AppNotification notification, NotificationNotifier notifier) {
    // Select icon based on type
    IconData iconData = LucideIcons.bell;
    Color iconColor = AppColors.primary;
    
    switch (notification.type) {
      case 'booking_confirmed':
        iconData = LucideIcons.checkCircle2;
        iconColor = Colors.green;
        break;
      case 'price_alert':
        iconData = LucideIcons.trendingDown;
        iconColor = Colors.orange;
        break;
      case 'flight_delay':
      case 'flight_cancelled':
        iconData = LucideIcons.alertTriangle;
        iconColor = AppColors.error;
        break;
      case 'promotional':
        iconData = LucideIcons.sparkles;
        iconColor = Colors.purple;
        break;
      case 'flight_reminder':
        iconData = LucideIcons.planeTakeoff;
        iconColor = AppColors.primary;
        break;
      case 'baggage_reminder':
        iconData = LucideIcons.briefcase;
        iconColor = Colors.teal;
        break;
      case 'arrival_advisory':
        iconData = LucideIcons.mapPin;
        iconColor = Colors.orange;
        break;
      case 'watchlistPriceDrop':
        iconData = LucideIcons.trendingDown;
        iconColor = Colors.green;
        break;
      case 'watchlistFlexibleDate':
        iconData = LucideIcons.calendarDays;
        iconColor = Colors.orange;
        break;
      case 'watchlistGoodPrice':
        iconData = LucideIcons.badgePercent;
        iconColor = Colors.blue;
        break;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      onDismissed: (direction) {
        notifier.deleteNotification(notification.id);
      },
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            notifier.markAsRead(notification.id);
          }
          // Navigate to the related trip detail when a booking_id is present in data
          final bookingId = notification.data?['booking_id'] as String?;
          if (bookingId != null && bookingId.isNotEmpty) {
            context.push('/trips/$bookingId');
          } else if (notification.type.startsWith('watchlist')) {
            // Tap navigation -> go to Home with watchlist tab active
            context.go('/', extra: {'tabIndex': 2});
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          color: notification.isRead ? Colors.transparent : AppColors.primary.withValues(alpha: 0.05),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                              color: notification.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimeAgo(notification.createdAt),
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: notification.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead) ...[
                const SizedBox(width: 12),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
