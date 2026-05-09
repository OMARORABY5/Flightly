import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flightly/core/theme/app_colors.dart';

/// A reusable glassmorphism container that applies a frosted glass effect
/// to whatever is behind it, with a subtle border and gradient.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
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

    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: effectiveBorderRadius,
            // Subtle gradient to simulate glass reflection
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surfaceElevated.withValues(alpha: 0.85),
                AppColors.surface.withValues(alpha: 0.95),
              ],
            ),
            // Semi-transparent border for the glass edge
            border: Border.all(
              color: AppColors.surfaceBorder.withValues(alpha: 0.6),
              width: 1.5,
            ),
            // Subtle shadow for depth
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: -5,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
