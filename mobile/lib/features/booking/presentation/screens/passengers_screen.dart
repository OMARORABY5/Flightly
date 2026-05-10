import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/core/presentation/widgets/ambient_background.dart';
import 'package:flightly/core/presentation/widgets/glass_card.dart';
import 'package:flightly/features/booking/domain/providers/booking_provider.dart';
import 'package:flightly/features/auth/providers/auth_provider.dart';
import 'package:flightly/core/widgets/loading_widget.dart';
import 'package:flightly/core/widgets/error_widget.dart' as app;
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flightly/features/booking/presentation/screens/add_edit_passenger_screen.dart';

class PassengersScreen extends ConsumerWidget {
  final bool isBookingFlow;
  const PassengersScreen({super.key, this.isBookingFlow = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Guard: require login before making any API call
    if (authState is! AuthAuthenticated) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('Select Passengers', style: AppTextStyles.headingMedium),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Stack(children: [
          AmbientBackground(child: SizedBox.shrink()),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.lock, size: 56, color: AppColors.textSecondary),
                  const SizedBox(height: 20),
                  Text('Sign in required', style: AppTextStyles.headingMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Please log in to manage your passengers.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () => context.push('/auth/login'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, minimumSize: const Size(180, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('Log In', style: AppTextStyles.button),
                  ),
                ],
              ),
            ),
          ),
        ]),
      );
    }

    final passengersAsync = ref.watch(savedPassengersProvider);
    final selectedPassengers = ref.watch(selectedPassengersProvider);

    return PopScope(
      canPop: !isBookingFlow || selectedPassengers.isNotEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isBookingFlow) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select at least one passenger to continue.')),
          );
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Select Passengers', style: AppTextStyles.headingMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AmbientBackground(child: SizedBox.shrink()),
          passengersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 120),
              child: GenericListShimmer(count: 4),
            ),
            error: (err, _) {
              // Extract the human-readable message from Failure objects or plain exceptions
              final msg = err.toString().contains('message:')
                  ? err.toString().split('message:').last.trim().replaceAll(')', '')
                  : err.toString().replaceAll('Exception:', '').trim();
              return app.AppErrorWidget(
                message: msg.isEmpty ? 'Failed to load passengers. Please try again.' : msg,
                onRetry: () => ref.invalidate(savedPassengersProvider),
              );
            },
            data: (passengers) {
              if (passengers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.users, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('No saved passengers yet', style: AppTextStyles.bodyLarge),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                  left: 20,
                  right: 20,
                  bottom: 100,
                ),
                itemCount: passengers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final p = passengers[index];
                  final isSelected = selectedPassengers.any((selected) => selected.id == p.id);

                  return GlassCard(
                    padding: const EdgeInsets.all(0),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                        child: Icon(
                          p.gender == 'male' ? LucideIcons.user : LucideIcons.userCircle, 
                          color: isSelected ? Colors.white : AppColors.textSecondary
                        ),
                      ),
                      title: Text(p.fullName, style: AppTextStyles.headingSmall),
                      subtitle: Text('Passport: ${p.passportNumber}', style: AppTextStyles.bodySmall),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.edit2, size: 18),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditPassengerScreen(passenger: p))),
                          ),
                          Checkbox(
                            value: isSelected,
                            activeColor: AppColors.primary,
                            onChanged: (_) {
                              ref.read(selectedPassengersProvider.notifier).togglePassenger(p);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        ref.read(selectedPassengersProvider.notifier).togglePassenger(p);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: isBookingFlow
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditPassengerScreen())),
                        icon: const Icon(LucideIcons.plus, size: 20),
                        label: const Text('Add'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: const BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: selectedPassengers.isNotEmpty ? () => context.pop() : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.surface,
                          disabledForegroundColor: AppColors.textSecondary.withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'Done (${selectedPassengers.length})',
                          style: AppTextStyles.button.copyWith(
                            color: selectedPassengers.isNotEmpty ? Colors.white : AppColors.textSecondary.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditPassengerScreen())),
                  icon: const Icon(LucideIcons.plus, size: 20),
                  label: const Text('Add Passenger'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                  ),
                ),
        ),
      ),
    ), // Scaffold
    ); // PopScope
  }
}
