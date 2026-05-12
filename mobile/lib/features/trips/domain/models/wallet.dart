// wallet.dart — FLIGHTLY Virtual Wallet Domain Model
// Represents the user's wallet balance and transaction ledger.

class WalletTransaction {
  final String id;
  final String type; // 'refund', 'payment', 'adjustment'
  final double amount;
  final double feePercent;
  final String? description;
  final String? bookingReference;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.feePercent,
    this.description,
    this.bookingReference,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      feePercent: (json['fee_percent'] as num?)?.toDouble() ?? 0.0,
      description: json['description'],
      bookingReference: json['booking_reference'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Wallet {
  final double balance;
  final List<WalletTransaction> transactions;

  Wallet({
    required this.balance,
    required this.transactions,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((e) => WalletTransaction.fromJson(e))
              .toList() ??
          [],
    );
  }
}
