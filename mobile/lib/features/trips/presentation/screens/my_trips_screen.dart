// my_trips_screen.dart — FLIGHTLY My Trips Screen (Phase 10)
// Two-tab layout: Upcoming flights and Travel history.
// Tabs are preserved in state; pull-to-refresh works per tab.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/features/auth/providers/auth_provider.dart';
import 'package:flightly/features/trips/domain/providers/trips_provider.dart';
import 'package:flightly/features/home/presentation/screens/home_screen.dart';
import 'package:flightly/features/trips/domain/models/trip.dart';
import 'package:flightly/features/trips/presentation/widgets/trip_card.dart';
import 'package:flightly/core/widgets/loading_widget.dart';
import 'package:flightly/core/widgets/error_widget.dart' as app;
import 'package:flightly/core/widgets/empty_widget.dart';
class MyTripsScreen extends ConsumerStatefulWidget {
  const MyTripsScreen({super.key});

  @override
  ConsumerState<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends ConsumerState<MyTripsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Refresh the active tab's data every time user switches to it
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    if (_tabController.index == 0) {
      ref.invalidate(upcomingTripsProvider);
    } else {
      ref.invalidate(historyTripsProvider);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('My Trips', style: AppTextStyles.headingMedium),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTextStyles.labelMedium,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: authState is! AuthAuthenticated
          ? _buildGuestState()
          : TabBarView(
              controller: _tabController,
              children: [
                _TripsTabView(
                  provider: upcomingTripsProvider,
                  emptyIcon: LucideIcons.planeTakeoff,
                  emptyTitle: 'No upcoming trips',
                  emptySubtitle: 'Book a flight and your upcoming trips will appear here.',
                  showBookCTA: true,
                ),
                _TripsTabView(
                  provider: historyTripsProvider,
                  emptyIcon: LucideIcons.clock,
                  emptyTitle: 'No travel history',
                  emptySubtitle: 'Your completed and cancelled trips will appear here.',
                  showBookCTA: false,
                ),
              ],
            ),
    );
  }

  Widget _buildGuestState() {
    return Center(
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
              child: const Icon(LucideIcons.plane, size: 60, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Text('Log in to see your trips', style: AppTextStyles.headingMedium, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'All your bookings and travel history will be here once you log in.',
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
    );
  }
}

// ─── Individual Tab View ──────────────────────────────────────────────────────
// Extracted to keep MyTripsScreen clean; handles loading / error / empty / list.
class _TripsTabView extends ConsumerWidget {
  final AutoDisposeFutureProvider<List<Trip>> provider;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final bool showBookCTA;
  final String? imagePath;

  const _TripsTabView({
    required this.provider,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.showBookCTA,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(provider);

    Future<void> onRefresh() async {
      ref.invalidate(provider);
      await ref.read(provider.future);
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: tripsAsync.when(
        // Phase 12: use TripListShimmer instead of a plain spinner
        loading: () => SingleChildScrollView(child: TripListShimmer()),
        error: (err, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 80),
            app.AppErrorWidget(
              message: 'Failed to load trips. Pull down to retry.',
              onRetry: () => ref.invalidate(provider),
            ),
          ],
        ),
        data: (trips) => trips.isEmpty
            ? _buildEmpty(context, ref)
            : _buildList(context, trips),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.1),
        AppEmptyWidget(
          icon: emptyIcon,
          title: emptyTitle,
          message: emptySubtitle,
          imagePath: imagePath,
          ctaLabel: showBookCTA ? 'Search Flights' : null,
          onCta: showBookCTA ? () => ref.read(homeTabProvider.notifier).state = 0 : null,
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context, List<Trip> trips) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final trip = trips[index];
        return TripCard(
          trip: trip,
          onTap: () => context.push('/trips/${trip.id}', extra: trip),
        );
      },
    );
  }
}
