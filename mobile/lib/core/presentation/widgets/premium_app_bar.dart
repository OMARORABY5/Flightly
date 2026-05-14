import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final double height;
  final bool showBottomBorder;
  final EdgeInsetsGeometry padding;

  const PremiumAppBar({
    Key? key,
    this.title,
    this.leading,
    this.actions,
    this.height = kToolbarHeight + 16.0, // Extra breathing room by default
    this.showBottomBorder = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          // Calculate exact height: user-specified height + safe area
          height: height + topPadding,
          padding: EdgeInsets.only(top: topPadding)
              .add(padding),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.90),
            boxShadow: showBottomBorder
                ? [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) leading!
              else if (Navigator.canPop(context))
                IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (leading != null || Navigator.canPop(context))
                const SizedBox(width: 16),
              if (title != null) Expanded(child: title!)
              else const Spacer(),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
