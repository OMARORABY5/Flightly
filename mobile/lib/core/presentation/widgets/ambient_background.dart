import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flightly/core/theme/app_colors.dart';

/// Animated ambient background with glowing orbs.
/// Renders as a plain Stack (no Scaffold) so it can be safely nested
/// inside any other Scaffold without causing hit-test assertion failures.
class AmbientBackground extends StatefulWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Orb 1: Top Right (Primary Blue)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Positioned(
              top: -100 + (sin(_controller.value * 2 * pi) * 50),
              right: -100 + (cos(_controller.value * 2 * pi) * 30),
              child: _buildOrb(AppColors.primary, size: 400, opacity: 0.15),
            ),
          ),

          // Orb 2: Bottom Left (Accent/Purple)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Positioned(
              bottom: -150 + (cos(_controller.value * 2 * pi) * 60),
              left: -100 + (sin(_controller.value * 2 * pi) * 40),
              child: _buildOrb(AppColors.badgeBest, size: 450, opacity: 0.12),
            ),
          ),

          // Screen content on top
          widget.child,
        ],
      ),
    );
  }

  Widget _buildOrb(Color color, {required double size, required double opacity}) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
