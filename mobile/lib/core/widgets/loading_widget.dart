// loading_widget.dart — FLIGHTLY Loading States
// Shimmer skeleton and spinner components for loading states
// WHY: Shimmer loading feels more premium than plain spinners and prevents layout shift

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../theme/app_colors.dart';

// ─── Shimmer Skeleton ─────────────────────────────────────────────────────────

/// Generic shimmer box for skeleton loading
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceElevated,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer card — mimics a flight card skeleton
class FlightCardShimmer extends StatelessWidget {
  const FlightCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Shimmer.fromColors(
          baseColor: AppColors.surface,
          highlightColor: AppColors.surfaceElevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 40, height: 40, decoration: const BoxDecoration(color: AppColors.surfaceElevated, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 100, height: 14, color: AppColors.surfaceElevated),
                      const SizedBox(height: 6),
                      Container(width: 60, height: 10, color: AppColors.surfaceElevated),
                    ],
                  ),
                  const Spacer(),
                  Container(width: 80, height: 20, color: AppColors.surfaceElevated),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 60, height: 24, color: AppColors.surfaceElevated),
                  Container(width: 80, height: 12, color: AppColors.surfaceElevated),
                  Container(width: 60, height: 24, color: AppColors.surfaceElevated),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// List of flight card shimmer skeletons (for results screen loading state)
class FlightListShimmer extends StatelessWidget {
  final int count;

  const FlightListShimmer({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: count,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (_, index) => const FlightCardShimmer(),
    );
  }
}

// ─── Action Spinner ───────────────────────────────────────────────────────────

/// Full-screen loading overlay for async actions (login, booking, etc.)
class LoadingOverlay extends StatelessWidget {
  final String? message;

  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.black.withAlpha(153),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SpinKitDoubleBounce(color: AppColors.primary, size: 50),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small inline spinner for buttons
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
      ),
    );
  }
}

// ─── Trip Card Shimmer ────────────────────────────────────────────────────────

/// Shimmer card that matches the shape of a TripCard for My Trips loading state
class TripCardShimmer extends StatelessWidget {
  const TripCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Shimmer.fromColors(
          baseColor: AppColors.surface,
          highlightColor: AppColors.surfaceElevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge + date row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 80, height: 22, decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(8))),
                  Container(width: 60, height: 14, color: AppColors.surfaceElevated),
                ],
              ),
              const SizedBox(height: 16),
              // Route row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 50, height: 28, color: AppColors.surfaceElevated),
                  Container(width: 60, height: 12, color: AppColors.surfaceElevated),
                  Container(width: 50, height: 28, color: AppColors.surfaceElevated),
                ],
              ),
              const SizedBox(height: 12),
              Container(width: 120, height: 12, color: AppColors.surfaceElevated),
            ],
          ),
        ),
      ),
    );
  }
}

/// List of trip card shimmer skeletons for My Trips loading
class TripListShimmer extends StatelessWidget {
  final int count;
  const TripListShimmer({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: count,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (_, __) => const TripCardShimmer(),
    );
  }
}

// ─── Generic Card Shimmer ─────────────────────────────────────────────────────

/// Generic shimmer card — used for notifications, passengers, settings lists
class GenericCardShimmer extends StatelessWidget {
  final double height;
  const GenericCardShimmer({super.key, this.height = 72});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        height: height,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Shimmer.fromColors(
          baseColor: AppColors.surface,
          highlightColor: AppColors.surfaceElevated,
          child: Row(
            children: [
              Container(width: 40, height: 40, decoration: const BoxDecoration(color: AppColors.surfaceElevated, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 14, color: AppColors.surfaceElevated),
                    const SizedBox(height: 6),
                    Container(width: 120, height: 10, color: AppColors.surfaceElevated),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// List of generic card shimmers
class GenericListShimmer extends StatelessWidget {
  final int count;
  const GenericListShimmer({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: count,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (_, __) => const GenericCardShimmer(),
    );
  }
}

