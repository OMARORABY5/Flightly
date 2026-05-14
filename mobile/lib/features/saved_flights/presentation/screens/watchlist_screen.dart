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
import 'package:flightly/features/saved_flights/services/watchlist_price_monitor.dart';
import 'package:flightly/core/presentation/widgets/premium_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  bool _isChecking = false;
  // Result state after a manual check
  int _dealsFound = 0;
  bool _showResult = false;

  Future<void> _runCheck() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    setState(() {
      _isChecking = true;
      _showResult = false;
    });

    // Invalidate so we get fresh data
    ref.invalidate(savedFlightsProvider);
    await ref.read(savedFlightsProvider.future);

    // Run manual pass (±5 days)
    final monitor = ref.read(watchlistPriceMonitorProvider);
    final alerts = await monitor.runMonitoringPass(
      userId: authState.user.id,
      isManual: true,
    );

    // Refresh again in case prices changed or alerts were generated
    ref.invalidate(savedFlightsProvider);
    ref.invalidate(watchlistLastCheckedProvider);
    await ref.read(savedFlightsProvider.future);

    if (mounted) {
      // Only show deal count when simulation is active.
      // Without simulation, real price changes are unlikely in a demo environment,
      // and showing false positives would be misleading.
      final prefs = await SharedPreferences.getInstance();
      final isSimulated = prefs.getBool('sim_discount') ?? false;

      setState(() {
        _isChecking = false;
        _dealsFound = isSimulated
            ? alerts.map((a) => a.saveId).toSet().length
            : 0;
        _showResult = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceElevated,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text('Watchlist', style: AppTextStyles.headingMedium),
        actions: [
          if (authState is AuthAuthenticated)
            _isChecking
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _runCheck,
                    onLongPress: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final isSimulated = prefs.getBool('sim_discount') ?? false;
                      await prefs.setBool('sim_discount', !isSimulated);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Simulated 15% Drop: ${!isSimulated ? "ON" : "OFF"}')),
                        );
                      }
                    },
                    child: Text('Check Now', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
                  ),
        ],
      ),
      body: authState is! AuthAuthenticated
          ? _buildGuestEmptyState(context)
          : _buildAuthenticatedContent(context),
    );
  }

  Widget _buildGuestEmptyState(BuildContext context) {
    return AppEmptyWidget(
      title: 'Log in to save flights',
      message: 'Track prices and get notified when fares change for your favorite routes.',
      icon: LucideIcons.heart,
      ctaLabel: 'Log In',
      onCta: () => context.push('/auth/login'),
    );
  }

  Widget _buildAuthenticatedContent(BuildContext context) {
    final savedFlightsAsync = ref.watch(savedFlightsProvider);

    return RefreshIndicator(
      onRefresh: _runCheck,
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
            itemCount: savedFlights.length + 1 + (_showResult ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildMonitoringBanner(context, savedFlights.length);
              }
              if (_showResult && index == 1) {
                return _buildResultBanner();
              }
              final offset = _showResult ? 2 : 1;
              final savedFlight = savedFlights[index - offset];
              return SavedFlightCard(savedFlight: savedFlight);
            },
          );
        },
      ),
    );
  }

  Widget _buildResultBanner() {
    final hasDeals = _dealsFound > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasDeals
              ? [
                  AppColors.success.withValues(alpha: 0.14),
                  AppColors.success.withValues(alpha: 0.04),
                ]
              : [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primary.withValues(alpha: 0.02),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDeals
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasDeals
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasDeals ? LucideIcons.badgeCheck : LucideIcons.searchCheck,
              size: 20,
              color: hasDeals ? AppColors.success : AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasDeals
                      ? '$_dealsFound Deal${_dealsFound > 1 ? 's' : ''} Found!'
                      : 'All Prices Checked',
                  style: AppTextStyles.labelLarge.copyWith(
                    color:
                        hasDeals ? AppColors.success : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasDeals
                      ? 'Scroll down — your flights with price drops are highlighted below.'
                      : 'No significant price changes right now. We\'ll keep watching.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showResult = false),
            child: Icon(LucideIcons.x,
                size: 16,
                color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringBanner(BuildContext context, int count) {
    final lastCheckedAsync = ref.watch(watchlistLastCheckedProvider);
    String lastCheckedText = 'Checking now...';
    
    lastCheckedAsync.whenData((date) {
      if (date != null) {
        final now = DateTime.now();
        final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
        final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        lastCheckedText = 'Last checked: ${isToday ? 'today' : '${date.month}/${date.day}'} at $timeStr';
      } else {
        lastCheckedText = 'Waiting for first check...';
      }
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.activity, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tracking $count route${count == 1 ? '' : 's'}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lastCheckedText,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.primary.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
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
