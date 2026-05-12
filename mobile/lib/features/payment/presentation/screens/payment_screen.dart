// payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/core/presentation/widgets/ambient_background.dart';
import 'package:flightly/core/presentation/widgets/glass_card.dart';
import 'package:flightly/features/booking/domain/models/booking.dart';
import 'package:flightly/features/booking/domain/providers/booking_provider.dart';
import 'package:flightly/features/payment/presentation/screens/booking_confirmation_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:flightly/features/trips/domain/providers/trips_provider.dart';
import 'dart:math' as math;

class PaymentScreen extends ConsumerStatefulWidget {
  final Booking booking;

  const PaymentScreen({super.key, required this.booking});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _cardNumberController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _isProcessing = false;
  bool _useWallet = true;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _processPayment(double remainingToPay) async {
    if (remainingToPay > 0) {
      if (!_formKey.currentState!.validate()) return;
    }

    setState(() => _isProcessing = true);

    if (remainingToPay > 0) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      final cardNumber = _cardNumberController.text.replaceAll(' ', '');
      
      if (cardNumber.startsWith('0000')) {
        setState(() => _isProcessing = false);
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(message: 'Payment declined by bank. Please try another card.'),
        );
        return;
      }
    }

    try {
      final repo = ref.read(bookingRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);
      await repo.confirmBooking(widget.booking.id, userId, useWallet: _useWallet);
      ref.invalidate(walletProvider);
    } catch (e) {
      // If confirm fails, still let the user see confirmation
    }

    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BookingConfirmationScreen(booking: widget.booking)));
  }

  @override
  Widget build(BuildContext context) {
    final walletAsyncValue = ref.watch(walletProvider);
    final walletBalance = walletAsyncValue.valueOrNull?.balance ?? 0.0;
    
    final walletApplied = _useWallet ? math.min(walletBalance, widget.booking.totalPrice) : 0.0;
    final remainingToPay = widget.booking.totalPrice - walletApplied;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Payment', style: AppTextStyles.headingMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AmbientBackground(child: SizedBox.shrink()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildOrderSummary(walletBalance, walletApplied, remainingToPay),
                    if (remainingToPay > 0) ...[
                      const SizedBox(height: 24),
                      _buildCreditCardForm(),
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isProcessing ? null : () => _processPayment(remainingToPay),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(remainingToPay == 0 ? 'Confirm Booking' : 'Pay \$${remainingToPay.toStringAsFixed(2)}', style: AppTextStyles.button),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(double walletBalance, double walletApplied, double remainingToPay) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.shoppingCart, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Order Summary', style: AppTextStyles.headingSmall),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Booking Ref:', style: AppTextStyles.bodyMedium),
              Text(widget.booking.reference, style: AppTextStyles.headingSmall.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount:', style: AppTextStyles.bodyMedium),
              Text('\$${widget.booking.totalPrice.toStringAsFixed(2)}', style: AppTextStyles.headingMedium),
            ],
          ),
          if (walletBalance > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(LucideIcons.wallet, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Apply Wallet Balance (\$${walletBalance.toStringAsFixed(2)})', style: AppTextStyles.bodyMedium, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
                Switch(
                  value: _useWallet,
                  onChanged: (val) => setState(() => _useWallet = val),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
            if (_useWallet && walletApplied > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Wallet Applied:', style: AppTextStyles.bodyMedium),
                  Text('-\$${walletApplied.toStringAsFixed(2)}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success)),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Remaining to Pay:', style: AppTextStyles.headingSmall),
                  Text('\$${remainingToPay.toStringAsFixed(2)}', style: AppTextStyles.headingMedium),
                ],
              ),
            ]
          ]
        ],
      ),
    );
  }

  Widget _buildCreditCardForm() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.creditCard, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Payment Details', style: AppTextStyles.headingSmall),
            ],
          ),
          const SizedBox(height: 16),
          
          // Cardholder Name
          TextFormField(
            controller: _cardNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Cardholder Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => v!.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          
          // Card Number
          TextFormField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberFormatter(),
            ],
            decoration: InputDecoration(
              labelText: 'Card Number',
              hintText: '0000 0000 0000 0000',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v.replaceAll(' ', '').length != 16) return 'Must be 16 digits';
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Expiry and CVV Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    _ExpiryDateFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Expiry (MM/YY)',
                    hintText: '12/25',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(v)) return 'Invalid MM/YY';
                    
                    final parts = v.split('/');
                    final month = int.parse(parts[0]);
                    final year = int.parse('20${parts[1]}');
                    final now = DateTime.now();
                    final currentYear = now.year;
                    final currentMonth = now.month;

                    if (year < currentYear || (year == currentYear && month < currentMonth)) {
                      return 'Card Expired';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length != 3) return 'Must be 3 digits';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper: Formats 1234567812345678 as 1234 5678 1234 5678
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(text: string, selection: TextSelection.collapsed(offset: string.length));
  }
}

// Helper: Formats 1225 as 12/25
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 2 == 0 && nonZeroIndex != text.length && nonZeroIndex == 2) {
        buffer.write('/');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(text: string, selection: TextSelection.collapsed(offset: string.length));
  }
}
