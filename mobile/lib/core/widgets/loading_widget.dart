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
