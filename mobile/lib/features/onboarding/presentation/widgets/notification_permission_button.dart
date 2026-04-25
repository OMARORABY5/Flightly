import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/providers/storage_provider.dart';
import '../../../core/theme/app_colors.dart';

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
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _isGranted = status.isGranted;
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);
    
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
  }

  @override
  Widget build(BuildContext context) {
    if (_isGranted) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: 8),
            Text(
              'Notifications Enabled',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _isRequesting ? null : _requestPermission,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: _isRequesting 
          ? const SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
            )
          : const Icon(Icons.notifications_active),
      label: const Text(
        'Enable Notifications',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
