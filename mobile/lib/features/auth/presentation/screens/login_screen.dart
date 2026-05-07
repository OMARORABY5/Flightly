import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';

import 'package:flightly/core/constants/route_constants.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/constants/app_assets.dart';
import 'package:flightly/core/widgets/sky_background.dart';
import 'package:flightly/features/auth/providers/auth_provider.dart';
import 'package:flightly/features/home/presentation/screens/home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    try {
      await ref.read(authProvider.notifier).login(
        _emailController.text,
        _passwordController.text,
      );
      
      if (mounted) {
        ref.read(homeTabProvider.notifier).state = 0;
        context.go(RouteConstants.home);
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: e.toString().replaceAll('Exception: ', '')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SkyBackground(
        showClouds: true,
        illustration: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Login',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _buildInput(
                  controller: _emailController,
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your email';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildInput(
                  controller: _passwordController,
                  hint: 'Enter password',
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your password';
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(RouteConstants.forgotPassword),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : _onLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    minimumSize: const Size(double.infinity, 56),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: Image.asset(AppAssets.icGoogle, width: 20, height: 20, errorBuilder: (c, e, s) => const Icon(LucideIcons.chrome, color: Colors.red)),
                        label: const Text('Google', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          side: const BorderSide(color: AppColors.surfaceBorder),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 24),
                        label: const Text('Facebook', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          side: const BorderSide(color: AppColors.surfaceBorder),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have account? ", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    GestureDetector(
                      onTap: () => context.pushReplacement(RouteConstants.register),
                      child: const Text('Register new account', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.subtitleGray.withOpacity(0.7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.surfaceBorder, width: 1)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.surfaceBorder, width: 1)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1)),
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}
