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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: effectiveBorderRadius,
        border: Border.all(
          color: const Color(0xFFCDD5E0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
