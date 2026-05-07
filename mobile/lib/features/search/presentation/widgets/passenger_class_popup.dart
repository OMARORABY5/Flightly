import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/features/search/domain/models/search_query.dart';
import 'package:flightly/features/search/domain/providers/search_form_provider.dart';

class PassengerClassPopup extends ConsumerStatefulWidget {
  const PassengerClassPopup({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PassengerClassPopup(),
    );
  }

  @override
  ConsumerState<PassengerClassPopup> createState() => _PassengerClassPopupState();
}

class _PassengerClassPopupState extends ConsumerState<PassengerClassPopup> {
  late int adults;
  late int children;
  late int infants;
  late CabinClass cabinClass;

  @override
  void initState() {
    super.initState();
    final query = ref.read(searchFormProvider);
    adults = query.adults;
    children = query.children;
    infants = query.infants;
    cabinClass = query.cabinClass;
  }

  void _apply() {
    final query = ref.read(searchFormProvider);
    ref.read(searchFormProvider.notifier).updateQuery(
      query.copyWith(
        adults: adults,
        children: children,
        infants: infants,
        cabinClass: cabinClass,
      ),
    );
    Navigator.of(context).pop();
  }

  bool _canAddPassenger() => (adults + children + infants) < 8;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Passengers & Class', style: AppTextStyles.headingLarge),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Passengers
          _buildCounterRow(
            title: 'Adults',
            subtitle: '12+ years',
            value: adults,
            onDecrease: adults > 1 ? () {
              setState(() {
                adults--;
                if (infants > adults) infants = adults;
              });
            } : null,
            onIncrease: _canAddPassenger() ? () => setState(() => adults++) : null,
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider(color: AppColors.surface)),
          _buildCounterRow(
            title: 'Children',
            subtitle: '2-11 years',
            value: children,
            onDecrease: children > 0 ? () => setState(() => children--) : null,
            onIncrease: _canAddPassenger() ? () => setState(() => children++) : null,
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider(color: AppColors.surface)),
          _buildCounterRow(
            title: 'Infants',
            subtitle: 'Under 2 (on lap)',
            value: infants,
            onDecrease: infants > 0 ? () => setState(() => infants--) : null,
            onIncrease: (_canAddPassenger() && infants < adults) ? () => setState(() => infants++) : null,
          ),
          
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Cabin Class', style: AppTextStyles.headingMedium),
            ),
          ),
          const SizedBox(height: 16),
          
          // Cabin Class
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildClassChip(CabinClass.economy, 'Economy'),
                _buildClassChip(CabinClass.business, 'Business'),
                _buildClassChip(CabinClass.first, 'First'),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Apply', style: AppTextStyles.button),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterRow({
    required String title,
    required String subtitle,
    required int value,
    required VoidCallback? onDecrease,
    required VoidCallback? onIncrease,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodyLarge),
              Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          Row(
            children: [
              _buildRoundButton(LucideIcons.minus, onDecrease),
              SizedBox(
                width: 40,
                child: Center(
                  child: Text('$value', style: AppTextStyles.headingMedium),
                ),
              ),
              _buildRoundButton(LucideIcons.plus, onIncrease),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoundButton(IconData icon, VoidCallback? onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: onPressed == null ? AppColors.surface : AppColors.primary,
            width: 1.5,
          ),
          color: onPressed == null ? AppColors.surface : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 16,
          color: onPressed == null ? AppColors.textSecondary.withOpacity(0.5) : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildClassChip(CabinClass cClass, String label) {
    final isSelected = cabinClass == cClass;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) setState(() => cabinClass = cClass);
        },
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
      ),
    );
  }
}
