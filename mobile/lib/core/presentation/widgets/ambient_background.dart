import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flightly/core/theme/app_colors.dart';

/// A reusable animated ambient background that creates a glowing, "breathing" effect
/// by moving blurred colored orbs around the screen.
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
    // 10 second loop for a very slow, ambient breath
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Orb 1: Top Right (Primary Blue)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned(
                top: -100 + (sin(_controller.value * 2 * pi) * 50),
                right: -100 + (cos(_controller.value * 2 * pi) * 30),
                child: _buildOrb(
                  AppColors.primary,
                  size: 400,
                  opacity: 0.15,
                ),
              );
            },
          ),
          
          // Orb 2: Bottom Left (Accent/Purple)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned(
                bottom: -150 + (cos(_controller.value * 2 * pi) * 60),
                left: -100 + (sin(_controller.value * 2 * pi) * 40),
                child: _buildOrb(
                  AppColors.badgeBest, // Purple color
                  size: 450,
                  opacity: 0.12,
                ),
              );
            },
          ),
          
          // The actual screen content
          SafeArea(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildOrb(Color color, {required double size, required double opacity}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
