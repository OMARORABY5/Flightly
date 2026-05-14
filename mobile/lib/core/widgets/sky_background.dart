import 'package:flutter/material.dart';
import 'package:flightly/core/theme/app_colors.dart';

class SkyBackground extends StatelessWidget {
  final Widget child;
  final Widget? illustration;
  final bool showClouds;

  const SkyBackground({
    super.key,
    required this.child,
    this.illustration,
    this.showClouds = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.info,
      body: Stack(
        children: [
          // Clouds and Illustrations at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (showClouds)
                  Positioned.fill(
                    child: _buildCloudPatterns(),
                  ),
                if (illustration != null)
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: illustration!,
                  ),
              ],
            ),
          ),
          
          // Bottom Content Card (White with Cloud-like top edges)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: MediaQuery.of(context).size.height * 0.45,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Simple hardcoded clouds for the background effect
  Widget _buildCloudPatterns() {
    return Stack(
      children: [
        Positioned(
          top: 60,
          left: -20,
          child: _CloudIcon(size: 100),
        ),
        Positioned(
          top: 80,
          right: 40,
          child: _CloudIcon(size: 140),
        ),
        Positioned(
          top: 200,
          left: 40,
          child: _CloudIcon(size: 80, opacity: 0.7),
        ),
        Positioned(
          top: 250,
          right: -30,
          child: _CloudIcon(size: 120, opacity: 0.5),
        ),
      ],
    );
  }
}

class _CloudIcon extends StatelessWidget {
  final double size;
  final double opacity;

  const _CloudIcon({required this.size, this.opacity = 1.0});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.cloud,
      size: size,
      color: Colors.white.withValues(alpha: 0.2 * opacity),
    );
  }
}
