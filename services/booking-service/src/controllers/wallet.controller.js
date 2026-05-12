// wallet.controller.js — FLIGHTLY Wallet Service
// Phase: Modify & Cancel Feature
// Provides the user's virtual wallet balance and transaction history.
// All refunds from cancellations are credited here.

class WalletController {
  constructor(db, redis) {
    this.db    = db;
    this.redis = redis;
  }

  // ─── GET /wallet ──────────────────────────────────────────────────────────────
  // Returns the authenticated user's wallet balance and full transaction history.
  // If the user has never received a refund, returns balance=0 and empty history.
  // userId comes from JWT via authMiddleware (req.userId).
  async getWallet(req, res) {
    const userId   = req.userId;
    const cacheKey = `wallet:${userId}`;

    // Try cache first
    if (this.redis) {
      const cached = await this.redis.get(cacheKey).catch(() => null);
      if (cached) return res.json({ success: true, data: JSON.parse(cached), cached: true });
    }

    try {
      // Auto-create wallet if it doesn't exist (first time user checks balance)
      const walletRow = await this.db.query(
        `INSERT INTO wallets (user_id, balance)
         VALUES ($1, 0.00)
         ON CONFLICT (user_id) DO UPDATE SET user_id = EXCLUDED.user_id
         RETURNING id, balance`,
        [userId]
      );

      const wallet   = walletRow.rows[0];
      const walletId = wallet.id;
      const balance  = parseFloat(wallet.balance);

      // Fetch transaction history (newest first)
      const txRow = await this.db.query(
        `SELECT wt.id, wt.type, wt.amount, wt.fee_percent, wt.description, wt.created_at,
                b.reference AS booking_reference
         FROM wallet_transactions wt
         LEFT JOIN bookings b ON wt.booking_id = b.id
         WHERE wt.wallet_id = $1
         ORDER BY wt.created_at DESC`,
        [walletId]
      );

      const result = {
        balance,
        transactions: txRow.rows.map(tx => ({
          id:                tx.id,
          type:              tx.type,
          amount:            parseFloat(tx.amount),
          fee_percent:       parseFloat(tx.fee_percent || 0),
          description:       tx.description,
          booking_reference: tx.booking_reference,
          created_at:        tx.created_at,
        })),
      };

      // Cache for 5 seconds only — balance changes on every payment or refund
      if (this.redis) {
        await this.redis.setEx(cacheKey, 5, JSON.stringify(result)).catch(() => {});
      }

      return res.json({ success: true, data: result });
    } catch (err) {
      console.error('getWallet error:', err.message);
      return res.status(500).json({ success: false, message: 'Failed to fetch wallet' });
    }
  }
}

module.exports = WalletController;
