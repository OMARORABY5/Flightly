-- FLIGHTLY — Migration 003
-- Adds virtual wallet system and cancellation metadata
-- Run with: docker exec -i flightly-postgres psql -U flightly_user -d flightly < database/migrations/003_wallet_and_cancellation.sql

-- ─── Wallets Table ────────────────────────────────────────────────────────────
-- One row per user. Balance accumulates refunds and is deducted on wallet payments.
CREATE TABLE IF NOT EXISTS wallets (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
  balance     NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
  updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_wallets_user ON wallets(user_id);

-- ─── Wallet Transactions Table ────────────────────────────────────────────────
-- Immutable ledger. Every credit (refund) and debit (payment) is recorded here.
CREATE TABLE IF NOT EXISTS wallet_transactions (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wallet_id    UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
  booking_id   UUID REFERENCES bookings(id) ON DELETE SET NULL,
  type         VARCHAR(20) NOT NULL CHECK (type IN ('refund', 'payment', 'adjustment')),
  amount       NUMERIC(12, 2) NOT NULL,   -- always positive; type determines credit/debit
  fee_percent  NUMERIC(5, 2) DEFAULT 0,   -- cancellation fee % applied (e.g. 10.00 for 10%)
  description  TEXT,
  created_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_wallet_tx_wallet   ON wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_wallet_tx_booking  ON wallet_transactions(booking_id);
CREATE INDEX IF NOT EXISTS idx_wallet_tx_created  ON wallet_transactions(created_at DESC);

-- ─── Cancellation Metadata on Bookings ───────────────────────────────────────
-- Track why and when a booking was cancelled, and how much was refunded.
ALTER TABLE bookings
  ADD COLUMN IF NOT EXISTS cancellation_reason  TEXT,
  ADD COLUMN IF NOT EXISTS cancelled_at         TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS refund_amount        NUMERIC(12, 2),
  ADD COLUMN IF NOT EXISTS cancellation_fee_pct NUMERIC(5, 2) DEFAULT 0;

-- ─── Auto-update trigger for wallets ─────────────────────────────────────────
CREATE TRIGGER update_wallets_updated_at
  BEFORE UPDATE ON wallets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
