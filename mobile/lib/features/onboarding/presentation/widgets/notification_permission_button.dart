import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flightly/core/providers/storage_provider.dart';
import 'package:flightly/core/theme/app_colors.dart';

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

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);
    
    try {
      final status = await Permission.notification.request();
      
      // Save the outcome
      await ref.read(storageServiceProvider).setNotificationPermissionStatus(
        status.isGranted ? 'granted' : 'denied'
      );

      if (mounted) {
        setState(() {
          _isGranted = status.isGranted;
          _isRequesting = false;
        });
      }
    } catch (e) {
      debugPrint('Permission request failed: $e');
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isGranted) {
      return Container(
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
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isRequesting ? null : _requestPermission,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isRequesting 
                    ? const SizedBox(
                        width: 24, 
                        height: 24, 
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)
                      )
                    : const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 24),
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
          ),
        ),
      ),
    );
  }
}
