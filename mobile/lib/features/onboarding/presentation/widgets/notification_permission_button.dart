import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flightly/core/providers/storage_provider.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:flightly/core/constants/route_constants.dart';
import 'package:flightly/features/onboarding/providers/onboarding_provider.dart';

class NotificationPermissionButton extends ConsumerStatefulWidget {
  const NotificationPermissionButton({super.key});

  @override
  ConsumerState<NotificationPermissionButton> createState() => _NotificationPermissionButtonState();
}

class _NotificationPermissionButtonState extends ConsumerState<NotificationPermissionButton> {
  bool _isRequesting = false;
  bool _isGranted = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final status = await Permission.notification.status;
      if (mounted) {
        setState(() {
          _isGranted = status.isGranted;
        });
      }
    } catch (e) {
      debugPrint('Permission check failed: $e');
    }
  }

  Future<void> _finishOnboarding() async {
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go(RouteConstants.login);
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);
    
    try {
      final status = await Permission.notification.request();
      
      // Save the outcome
      await ref.read(storageServiceProvider).setNotificationPermissionStatus(
        status.isGranted ? 'granted' : 'denied'
      );
    } catch (e) {
      debugPrint('Permission request failed: $e');
    }
    
    await _finishOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    if (_isGranted) {
      return GestureDetector(
        onTap: _finishOnboarding,
        child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success, size: 28),
            const SizedBox(width: 12),
            Text(
              'Notifications Enabled',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: _isRequesting ? null : _requestPermission,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        shadowColor: AppColors.primary.withValues(alpha: 0.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isRequesting)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            )
          else
            const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          const Text(
            'Enable Notifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
