// wallet_screen.dart — FLIGHTLY Wallet Screen
// Phase 10: Displays user's virtual wallet balance and transaction history.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/core/presentation/widgets/glass_card.dart';
import 'package:flightly/features/trips/domain/providers/trips_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  void initState() {
    super.initState();
    // Always fetch fresh data when the wallet screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(walletProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceElevated,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('My Wallet', style: AppTextStyles.headingMedium),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: walletAsync.when(
        data: (wallet) => RefreshIndicator(
          onRefresh: () async => ref.refresh(walletProvider.future),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Current Balance', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text(
                        '${wallet.balance.toStringAsFixed(2)} EGP',
                        style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary, fontSize: 40),
                      ),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Transaction History', style: AppTextStyles.headingSmall),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (wallet.transactions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.wallet, size: 64, color: AppColors.surfaceBorder),
                        const SizedBox(height: 16),
                        Text('No transactions yet', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tx = wallet.transactions[index];
                      final isCredit = tx.type == 'refund';
                      final dateFormat = DateFormat('MMM d, yyyy • HH:mm').format(tx.createdAt);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isCredit ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCredit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                                  color: isCredit ? AppColors.success : AppColors.error,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tx.type.toUpperCase(), style: AppTextStyles.labelSmall),
                                    const SizedBox(height: 4),
                                    Text(
                                      tx.description ?? (tx.bookingReference != null ? 'Booking ${tx.bookingReference}' : 'Transaction'),
                                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(dateFormat, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 10)),
                                  ],
                                ),
                              ),
                              Text(
                                '${tx.amount.toStringAsFixed(2)} EGP',
                                style: AppTextStyles.headingSmall.copyWith(color: isCredit ? AppColors.success : AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: wallet.transactions.length,
                  ),
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load wallet', style: AppTextStyles.bodyMedium),
              TextButton(
                onPressed: () => ref.refresh(walletProvider.future),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
