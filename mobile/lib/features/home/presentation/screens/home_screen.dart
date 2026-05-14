import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/features/search/presentation/screens/home_search_screen.dart';
import 'package:flightly/features/saved_flights/presentation/screens/watchlist_screen.dart';
import 'package:flightly/features/trips/presentation/screens/my_trips_screen.dart';
import 'package:flightly/features/trips/domain/providers/trips_provider.dart';
import 'package:flightly/features/account/presentation/screens/account_hub_screen.dart';
import 'package:flightly/core/widgets/offline_banner.dart';


// Provider to control the active tab in HomeScreen from anywhere
final homeTabProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    // Set initial tab if provided, delaying to avoid build phase issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialIndex != ref.read(homeTabProvider)) {
        ref.read(homeTabProvider.notifier).state = widget.initialIndex;
      }
    });
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(homeTabProvider.notifier).state = widget.initialIndex;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  final List<Widget> _screens = [
    const HomeSearchScreen(),
    const MyTripsScreen(),
    const WatchlistScreen(),
    const AccountHubScreen(),
  ];

  void _onNavTap(int index) {
    // When switching to My Trips tab, invalidate so data is always fresh
    if (index == 1) {
      ref.invalidate(upcomingTripsProvider);
      ref.invalidate(historyTripsProvider);
    }
    ref.read(homeTabProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(homeTabProvider);

    // Listen to tab changes and animate the page view
    ref.listen<int>(homeTabProvider, (previous, next) {
      if (previous != next && _pageController.hasClients) {
        // If the Home screen is currently active (e.g., normal tab switching), animate the transition.
        // If it's hidden behind another screen (e.g., Login screen), jump instantly to avoid messy concurrent animations.
        if (ModalRoute.of(context)?.isCurrent == true) {
          _pageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
          );
        } else {
          _pageController.jumpToPage(next);
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: OfflineBannerWrapper(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, currentIndex, LucideIcons.search, 'Search'),
                _buildNavItem(1, currentIndex, LucideIcons.plane, 'My Trips'),
                _buildNavItem(2, currentIndex, LucideIcons.heart, 'Watchlist'),
                _buildNavItem(3, currentIndex, LucideIcons.user, 'Account'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, int currentIndex, IconData icon, String label) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
