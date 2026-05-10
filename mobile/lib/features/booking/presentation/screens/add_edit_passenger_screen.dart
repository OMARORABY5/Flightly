// add_edit_passenger_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/core/presentation/widgets/ambient_background.dart';
import 'package:flightly/core/presentation/widgets/glass_card.dart';
import 'package:flightly/features/booking/domain/models/passenger.dart';
import 'package:flightly/features/booking/domain/providers/booking_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:country_picker/country_picker.dart';

class AddEditPassengerScreen extends ConsumerStatefulWidget {
  final Passenger? passenger;

  const AddEditPassengerScreen({super.key, this.passenger});

  @override
  ConsumerState<AddEditPassengerScreen> createState() => _AddEditPassengerScreenState();
}

class _AddEditPassengerScreenState extends ConsumerState<AddEditPassengerScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _passportController;
  
  String _gender = 'male';
  DateTime? _dob;
  DateTime? _passportExpiry;
  String _nationality = '';
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.passenger?.fullName ?? '');
    _passportController = TextEditingController(text: widget.passenger?.passportNumber ?? '');
    
    if (widget.passenger != null) {
      _gender = widget.passenger!.gender;
      _dob = widget.passenger!.dateOfBirth;
      _passportExpiry = widget.passenger!.passportExpiry;
      _nationality = widget.passenger!.nationality;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passportController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isDob) async {
    final initialDate = isDob 
        ? (_dob ?? DateTime.now().subtract(const Duration(days: 365 * 30))) 
        : (_passportExpiry ?? DateTime.now().add(const Duration(days: 365)));
    
    final firstDate = isDob ? DateTime(1900) : DateTime.now();
    final lastDate = isDob ? DateTime.now() : DateTime.now().add(const Duration(days: 3650));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isDob) {
          _dob = picked;
        } else {
          _passportExpiry = picked;
        }
      });
    }
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      countryListTheme: CountryListThemeData(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        backgroundColor: AppColors.background,
        textStyle: AppTextStyles.bodyMedium,
        searchTextStyle: AppTextStyles.bodyMedium,
      ),
      onSelect: (Country country) {
        setState(() {
          _nationality = country.name;
        });
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_dob == null) {
      showTopSnackBar(Overlay.of(context), const CustomSnackBar.error(message: 'Please select Date of Birth'));
      return;
    }
    if (_nationality.isEmpty) {
      showTopSnackBar(Overlay.of(context), const CustomSnackBar.error(message: 'Please select Nationality'));
      return;
    }
    if (_passportExpiry == null) {
      showTopSnackBar(Overlay.of(context), const CustomSnackBar.error(message: 'Please select Passport Expiry Date'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(bookingRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);

      final newPassenger = Passenger(
        id: widget.passenger?.id ?? '',
        userId: userId,
        fullName: _nameController.text.trim(),
        gender: _gender,
        dateOfBirth: _dob!,
        nationality: _nationality,
        passportNumber: _passportController.text.trim().toUpperCase(),
        passportExpiry: _passportExpiry,
      );

      if (widget.passenger == null) {
        await repo.addPassenger(newPassenger);
      } else {
        await repo.updatePassenger(newPassenger);
      }

      ref.invalidate(savedPassengersProvider);
      if (mounted && context.mounted) {
        context.pop();
        showTopSnackBar(Overlay.of(context), const CustomSnackBar.success(message: 'Passenger saved successfully'));
      }
    } catch (e) {
      showTopSnackBar(Overlay.of(context), CustomSnackBar.error(message: e.toString().replaceAll('Exception: ', '')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(bookingRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);
      
      await repo.deletePassenger(widget.passenger!.id, userId);
      
      ref.invalidate(savedPassengersProvider);
      
      // Also remove from selected passengers if they were selected
      final selected = ref.read(selectedPassengersProvider);
      if (selected.any((p) => p.id == widget.passenger!.id)) {
        ref.read(selectedPassengersProvider.notifier).togglePassenger(widget.passenger!);
      }

      if (mounted && context.mounted) {
        context.pop();
        showTopSnackBar(Overlay.of(context), const CustomSnackBar.success(message: 'Passenger deleted'));
      }
    } catch (e) {
      showTopSnackBar(Overlay.of(context), CustomSnackBar.error(message: e.toString().replaceAll('Exception: ', '')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.passenger != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Passenger' : 'Add Passenger', style: AppTextStyles.headingMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _isLoading ? null : _delete,
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: AmbientBackground(child: SizedBox.shrink())),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Full Name (as in passport)'),
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(labelText: 'Gender'),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(value: 'female', child: Text('Female')),
                        ],
                        onChanged: (v) => setState(() => _gender = v!),
                      ),
                      const SizedBox(height: 16),

                      InkWell(
                        onTap: () => _selectDate(context, true),
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Date of Birth'),
                          child: Text(_dob != null ? DateFormat('dd MMM yyyy').format(_dob!) : 'Select Date'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      InkWell(
                        onTap: _showCountryPicker,
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Nationality'),
                          child: Text(_nationality.isNotEmpty ? _nationality : 'Select Country'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passportController,
                        decoration: const InputDecoration(labelText: 'Passport Number'),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      InkWell(
                        onTap: () => _selectDate(context, false),
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Passport Expiry Date'),
                          child: Text(_passportExpiry != null ? DateFormat('dd MMM yyyy').format(_passportExpiry!) : 'Select Date'),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text('Save Passenger', style: AppTextStyles.button),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
