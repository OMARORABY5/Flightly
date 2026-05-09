import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/features/search/domain/providers/search_provider.dart';
import 'package:flightly/features/auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flightly/features/saved_flights/presentation/widgets/saved_flight_card.dart';
import 'package:flightly/core/widgets/empty_widget.dart';
class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Watchlist', style: AppTextStyles.headingMedium),
      ),
      body: authState is! AuthAuthenticated
          ? _buildGuestEmptyState(context, ref)
          : _buildAuthenticatedContent(context, ref),
    );
  }

  Widget _buildGuestEmptyState(BuildContext context, WidgetRef ref) {
    return AppEmptyWidget(
      title: 'Log in to save flights',
      message: 'Track prices and get notified when fares change for your favorite routes.',
      icon: LucideIcons.heart,
      ctaLabel: 'Log In',
      onCta: () => context.push('/auth/login'),
    );
  }

  Widget _buildAuthenticatedContent(BuildContext context, WidgetRef ref) {
    final savedFlightsAsync = ref.watch(savedFlightsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(savedFlightsProvider);
        await ref.read(savedFlightsProvider.future);
      },
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: savedFlightsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stack) => Center(
          child: Text('Failed to load watchlist', style: AppTextStyles.bodyLarge),
        ),
        data: (savedFlights) {
          if (savedFlights.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: savedFlights.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final savedFlight = savedFlights[index];
              return SavedFlightCard(savedFlight: savedFlight);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        AppEmptyWidget(
          title: 'Your watchlist is empty',
          message: 'Search for flights and tap the heart icon to save them here for later.',
          icon: LucideIcons.heart,
        ),
      ],
    );
  }
}
