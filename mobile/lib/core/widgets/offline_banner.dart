// offline_banner.dart — FLIGHTLY Offline Banner
// A subtle, non-intrusive banner that appears at the top when offline.
// WHY: Users need immediate feedback when they lose connection so they understand
//      why their actions aren't working.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/connectivity_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Wraps any screen and adds an animated offline banner at the top.
/// Usage: Wrap HomeScreen or specific screens that need offline awareness.
class OfflineBannerWrapper extends ConsumerWidget {
  final Widget child;
  const OfflineBannerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isOnline
              ? const SizedBox.shrink()
              : Container(
                  width: double.infinity,
                  color: AppColors.warning,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        const Icon(LucideIcons.wifiOff, color: Colors.black87, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No internet connection. Some features may be unavailable.',
                            style: AppTextStyles.labelSmall.copyWith(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
