import 'package:flutter/material.dart';
import 'package:flightly/core/theme/app_colors.dart';

class SocialAuthButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onPressed;

  const SocialAuthButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.surfaceBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: icon),
      ),
    );
  }
}
