import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flightly/core/theme/app_colors.dart';

/// Animated ambient background with glowing orbs.
/// Uses StackFit.expand so it always fills its parent and Clip.none so
/// card box-shadows / decorations near edges are never clipped.
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
    return Stack(
      // expand: all non-positioned children (i.e. widget.child) fill the stack.
      // This ensures Column+Expanded, SafeArea, etc. all receive tight constraints.
      fit: StackFit.expand,
      // none: do NOT clip — the parent (Scaffold body) clips naturally.
      // Clip.hardEdge was cutting box-shadows and card edges near screen edges.
      clipBehavior: Clip.none,
      children: [
        // ── Solid background colour ──────────────────────────────────────────
        const ColoredBox(color: AppColors.background),

        // ── Orb 1: Top Right ────────────────────────────────────────────────
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Positioned(
            top: -100 + (sin(_controller.value * 2 * pi) * 50),
            right: -100 + (cos(_controller.value * 2 * pi) * 30),
            child: _buildOrb(AppColors.primary, size: 400, opacity: 0.15),
          ),
        ),

        // ── Orb 2: Bottom Left ──────────────────────────────────────────────
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Positioned(
            bottom: -150 + (cos(_controller.value * 2 * pi) * 60),
            left: -100 + (sin(_controller.value * 2 * pi) * 40),
            child: _buildOrb(AppColors.badgeBest, size: 450, opacity: 0.12),
          ),
        ),

        // ── Screen content (expands to fill, receives tight constraints) ─────
        widget.child,
      ],
    );
  }

  Widget _buildOrb(Color color,
      {required double size, required double opacity}) {
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
