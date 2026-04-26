import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';

import 'package:flightly/core/constants/route_constants.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/presentation/widgets/ambient_background.dart';
import 'package:flightly/core/presentation/widgets/glass_card.dart';
import 'package:flightly/core/presentation/widgets/custom_text_field.dart';
import 'package:flightly/features/auth/data/repositories/auth_repository_impl.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isRequestingOtp = false;
  bool _otpSent = false;
  bool _isResetting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _onRequestOtp() async {
    if (_emailController.text.isEmpty || 
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(message: 'Please enter a valid email address'),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isRequestingOtp = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      final otp = await repo.forgotPassword(email: _emailController.text);
      
      if (mounted) {
        setState(() {
          _otpSent = true;
          _isRequestingOtp = false;
        });
        
        if (otp != null) {
          // In development mode, auto-fill the OTP or show it clearly
          _otpController.text = otp;
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.success(message: 'DEV MODE: OTP auto-filled ($otp)'),
          );
        } else {
          showTopSnackBar(
            Overlay.of(context),
            const CustomSnackBar.info(message: 'If registered, an OTP has been sent to your email.'),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRequestingOtp = false);
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(message: 'Failed to send OTP. Please try again.'),
        );
      }
    }
  }

  void _onResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    FocusScope.of(context).unfocus();
    setState(() => _isResetting = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.resetPassword(
        email: _emailController.text,
        otp: _otpController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(message: 'Password reset successfully! Please log in.'),
        );
        context.go(RouteConstants.login);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResetting = false);
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: e.toString().replaceAll('Exception: ', '')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: AmbientBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: GlassCard(
              blur: 20.0,
              opacity: 0.08,
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Reset Password',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _otpSent 
                        ? 'Enter the 6-digit OTP sent to your email to create a new password.'
                        : 'Enter your email address and we will send you an OTP to reset your password.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Always show email field, but disable if OTP sent
                    CustomTextField(
                      label: 'Email',
                      hint: 'name@example.com',
                      prefixIcon: LucideIcons.mail,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your email';
                        return null;
                      },
                    ),
                    
                    if (!_otpSent) ...[
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isRequestingOtp ? null : _onRequestOtp,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isRequestingOtp
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Send OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],

                    if (_otpSent) ...[
                      const SizedBox(height: 20),
                      CustomTextField(
                        label: 'OTP Code',
                        hint: '123456',
                        prefixIcon: LucideIcons.key,
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter the OTP';
                          if (value.length != 6) return 'OTP must be 6 digits';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        label: 'New Password',
                        hint: 'At least 8 characters',
                        prefixIcon: LucideIcons.lock,
                        isPassword: true,
                        controller: _newPasswordController,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.length < 8) return 'Password must be at least 8 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isResetting ? null : _onResetPassword,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isResetting
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Reset Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
