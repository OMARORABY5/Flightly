import 'package:flutter/material.dart';
import 'package:flightly/core/theme/app_colors.dart';

/// A reusable dark-surface card with rounded corners, border, and shadow.
/// Uses Container.clipBehavior instead of a separate ClipRRect so that the
/// card decoration (border, shadow) renders outside the clip boundary and
/// content inside is properly clipped to the border radius.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;    // kept for API compat — not used
  final double opacity; // kept for API compat — not used
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.1,
    this.borderRadius,
    this.padding = const EdgeInsets.all(24.0),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(24.0);

    return Container(
      width: width,
      height: height,
      padding: padding,
      // clipBehavior on the Container itself clips children to the border
      // radius without a separate ClipRRect that can cut content too early.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevated,
            AppColors.surface,
          ],
        ),
        border: Border.all(
          color: AppColors.surfaceBorder.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
