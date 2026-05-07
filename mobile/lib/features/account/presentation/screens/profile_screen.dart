// profile_screen.dart — FLIGHTLY Profile Screen
// Edit name, phone, nationality, and simulate profile photo upload.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/features/account/domain/providers/account_provider.dart';
import 'package:flightly/features/account/domain/models/profile.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalityController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from current provider state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileAsync = ref.read(profileProvider);
      if (profileAsync is AsyncData<Profile?> && profileAsync.value != null) {
        final p = profileAsync.value!;
        _nameController.text = p.displayName ?? '';
        _phoneController.text = p.phone ?? '';
        _nationalityController.text = p.nationality ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nationalityController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentProfile = ref.read(profileProvider).value;
      if (currentProfile == null) return;

      final updatedProfile = Profile(
        id: currentProfile.id,
        email: currentProfile.email, // email is not editable
        displayName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        nationality: _nationalityController.text.trim(),
        photoUrl: currentProfile.photoUrl,
        createdAt: currentProfile.createdAt,
      );

      await ref.read(accountRepositoryProvider).updateProfile(updatedProfile);
      ref.invalidate(profileProvider); // Refresh state

      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(message: 'Profile updated successfully'),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: e.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile == null) return; // User cancelled

      setState(() => _isLoading = true);

      // Simulate upload: generate a dynamic avatar URL based on the user's name
      // This is our agreed upon workaround for the DB constraints (VARCHAR 500) 
      // without having an actual S3 file bucket to upload to.
      final currentProfile = ref.read(profileProvider).value;
      final name = currentProfile?.displayName?.isNotEmpty == true 
          ? currentProfile!.displayName! 
          : 'User';
      
      final randomHex = (Random().nextDouble() * 0xFFFFFF).toInt().toRadixString(16).padLeft(6, '0');
      final dummyUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=$randomHex&color=fff&size=256';

      await ref.read(accountRepositoryProvider).updateProfilePhoto(dummyUrl);
      ref.invalidate(profileProvider); // Refresh state

      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(message: 'Profile photo updated!'),
        );
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: 'Failed to update photo: $e'),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Edit Profile', style: AppTextStyles.headingMedium),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error))),
        data: (profile) {
          if (profile == null) return const Center(child: Text('No profile data'));
          
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // ── Photo Upload ─────────────────────────────────────────────
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: profile.photoUrl != null
                            ? CachedNetworkImageProvider(profile.photoUrl!)
                            : null,
                        child: profile.photoUrl == null
                            ? const Icon(LucideIcons.user, size: 50, color: AppColors.primary)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isLoading ? null : _pickAndUploadPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.camera, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Non-editable Email ───────────────────────────────────────
                Text('Email Address', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.mail, color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Text(profile.email, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      const Spacer(),
                      const Icon(LucideIcons.lock, color: AppColors.textHint, size: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Editable Fields ──────────────────────────────────────────
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: LucideIcons.user,
                  hint: 'Enter your full name',
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: LucideIcons.phone,
                  hint: '+1 234 567 8900',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _nationalityController,
                  label: 'Nationality',
                  icon: LucideIcons.globe,
                  hint: 'e.g. American, Egyptian, etc.',
                ),
                const SizedBox(height: 40),

                // ── Save Button ──────────────────────────────────────────────
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Save Changes', style: AppTextStyles.button),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppTextStyles.inputText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.inputText.copyWith(color: AppColors.textHint),
            prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.surfaceBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.surfaceBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
