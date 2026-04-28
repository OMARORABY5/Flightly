// passengers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/core/presentation/widgets/ambient_background.dart';
import 'package:flightly/core/presentation/widgets/glass_card.dart';
import 'package:flightly/features/booking/domain/providers/booking_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PassengersScreen extends ConsumerWidget {
  const PassengersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passengersAsync = ref.watch(savedPassengersProvider);
    final selectedPassengers = ref.watch(selectedPassengersProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Select Passengers', style: AppTextStyles.headingMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const AmbientBackground(child: SizedBox()),
          passengersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
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
                            onPressed: () => context.push('/booking/passengers/edit', extra: p),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/booking/passengers/add'),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Add Passenger'),
      ),
    );
  }
}
