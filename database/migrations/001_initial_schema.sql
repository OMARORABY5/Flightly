-- FLIGHTLY — Initial Database Migration
-- File: 001_initial_schema.sql
-- This file runs automatically when PostgreSQL container starts for the first time
-- All tables are created here; data seeding happens in later migrations

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── Users Table (Auth Service) ───────────────────────────────────────────────
-- Core user accounts — email is always stored lowercase
CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email         VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  display_name  VARCHAR(100),
  phone         VARCHAR(20),
  nationality   VARCHAR(100),
  photo_url     VARCHAR(500),
  is_active     BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for fast email lookups (login, duplicate check)
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- ─── Airports Table (Flight Service) ─────────────────────────────────────────
-- Global airport database — seeded in migration 002
CREATE TABLE IF NOT EXISTS airports (
  id           SERIAL PRIMARY KEY,
  iata_code    CHAR(3) NOT NULL UNIQUE,       -- e.g., "CAI", "DXB", "JFK"
  icao_code    CHAR(4),                        -- e.g., "HECA", "OMDB"
  name         VARCHAR(200) NOT NULL,          -- e.g., "Cairo International Airport"
  city         VARCHAR(100) NOT NULL,          -- e.g., "Cairo"
  country      VARCHAR(100) NOT NULL,          -- e.g., "Egypt"
  country_code CHAR(2) NOT NULL,              -- ISO 3166-1 alpha-2, e.g., "EG"
  latitude     DECIMAL(9, 6),
  longitude    DECIMAL(9, 6),
  timezone     VARCHAR(50),                    -- e.g., "Africa/Cairo"
  is_active    BOOLEAN DEFAULT TRUE,
  created_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for fast airport search by code, city, country
CREATE INDEX IF NOT EXISTS idx_airports_iata    ON airports(iata_code);
CREATE INDEX IF NOT EXISTS idx_airports_city    ON airports(LOWER(city));
CREATE INDEX IF NOT EXISTS idx_airports_country ON airports(LOWER(country));
CREATE INDEX IF NOT EXISTS idx_airports_name    ON airports(LOWER(name));

-- ─── Flights Table (Flight Service) ──────────────────────────────────────────
-- Simulated flight data — seeded in migration 003
CREATE TABLE IF NOT EXISTS flights (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  flight_number       VARCHAR(10) NOT NULL,          -- e.g., "EK 123"
  airline_code        CHAR(2) NOT NULL,              -- IATA airline code, e.g., "EK"
  airline_name        VARCHAR(100) NOT NULL,
  airline_logo_url    VARCHAR(500),
  origin_iata         CHAR(3) NOT NULL REFERENCES airports(iata_code),
  destination_iata    CHAR(3) NOT NULL REFERENCES airports(iata_code),
  departure_time      TIMESTAMP WITH TIME ZONE NOT NULL,
  arrival_time        TIMESTAMP WITH TIME ZONE NOT NULL,
  duration_minutes    INT NOT NULL,
  stops               INT DEFAULT 0,                 -- 0 = direct, 1+ = connecting
  cabin_class         VARCHAR(20) DEFAULT 'economy',  -- economy, premium_economy, business, first
  base_price          DECIMAL(10, 2) NOT NULL,
  available_seats     INT DEFAULT 100,
  baggage_cabin_kg    INT DEFAULT 7,                 -- Carry-on allowance in kg
  baggage_checked_kg  INT DEFAULT 23,                -- Checked baggage in kg
  is_refundable       BOOLEAN DEFAULT FALSE,
  is_active           BOOLEAN DEFAULT TRUE,
  created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for flight search performance
CREATE INDEX IF NOT EXISTS idx_flights_route    ON flights(origin_iata, destination_iata);
CREATE INDEX IF NOT EXISTS idx_flights_depart   ON flights(departure_time);
CREATE INDEX IF NOT EXISTS idx_flights_price    ON flights(base_price);
CREATE INDEX IF NOT EXISTS idx_flights_stops    ON flights(stops);

-- ─── Bookings Table (Booking Service) ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bookings (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reference        VARCHAR(20) NOT NULL UNIQUE,   -- e.g., "FLY-20240125-A3BX9K"
  user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  flight_id        UUID NOT NULL REFERENCES flights(id),
  return_flight_id UUID REFERENCES flights(id),   -- NULL for one-way
  trip_type        VARCHAR(10) DEFAULT 'one_way',  -- one_way | round_trip
  cabin_class      VARCHAR(20) NOT NULL,
  status           VARCHAR(20) DEFAULT 'pending',  -- pending | confirmed | cancelled
  payment_status   VARCHAR(20) DEFAULT 'unpaid',   -- unpaid | paid | refunded
  total_price      DECIMAL(10, 2) NOT NULL,
  contact_email    VARCHAR(255) NOT NULL,
  contact_phone    VARCHAR(20),
  created_at       TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at       TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bookings_user      ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_reference ON bookings(reference);
CREATE INDEX IF NOT EXISTS idx_bookings_status    ON bookings(status);

-- ─── Passengers Table (Booking Service) ──────────────────────────────────────
-- Reusable passenger profiles saved by users
CREATE TABLE IF NOT EXISTS passengers (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  full_name      VARCHAR(200) NOT NULL,
  gender         VARCHAR(10) NOT NULL,              -- male | female
  date_of_birth  DATE NOT NULL,
  nationality    VARCHAR(100) NOT NULL,
  passport_number VARCHAR(20) NOT NULL,
  passport_expiry DATE,
  is_primary     BOOLEAN DEFAULT FALSE,             -- Primary contact passenger
  created_at     TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at     TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_passengers_user ON passengers(user_id);

-- ─── Booking Passengers Table (Booking Service) ───────────────────────────────
-- Junction: which passengers are on which booking
CREATE TABLE IF NOT EXISTS booking_passengers (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id   UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  passenger_id UUID NOT NULL REFERENCES passengers(id),
  seat_number  VARCHAR(10),
  ticket_number VARCHAR(50),
  created_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(booking_id, passenger_id)
);

-- ─── Saved Flights Table (User Service) ──────────────────────────────────────
-- User watchlist — snapshots the price at save time for comparison
CREATE TABLE IF NOT EXISTS saved_flights (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  flight_id       UUID NOT NULL REFERENCES flights(id) ON DELETE CASCADE,
  saved_price     DECIMAL(10, 2) NOT NULL,          -- Price snapshot when saved
  search_criteria JSONB,                            -- Original search params for re-search
  created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, flight_id)                        -- Prevent duplicate saves
);

CREATE INDEX IF NOT EXISTS idx_saved_flights_user ON saved_flights(user_id);

-- ─── Notifications Table (Notification Service) ───────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type        VARCHAR(50) NOT NULL,                 -- booking_confirmed | price_alert | schedule_update | fare_change
  title       VARCHAR(200) NOT NULL,
  body        TEXT NOT NULL,
  data        JSONB,                                -- Extra payload (booking ref, flight id, etc.)
  is_read     BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user   ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read);

-- ─── Notification Preferences Table (Notification Service) ───────────────────
CREATE TABLE IF NOT EXISTS notification_preferences (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
  booking_updates     BOOLEAN DEFAULT TRUE,
  price_alerts        BOOLEAN DEFAULT TRUE,
  schedule_updates    BOOLEAN DEFAULT TRUE,
  promotional         BOOLEAN DEFAULT FALSE,
  fcm_token           VARCHAR(500),                 -- Firebase Cloud Messaging device token
  updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─── User Settings Table (User Service) ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_settings (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
  language        VARCHAR(10) DEFAULT 'en',         -- ISO language code
  country         VARCHAR(100) DEFAULT 'Egypt',
  currency        VARCHAR(3) DEFAULT 'USD',
  updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─── Helper function: auto-update updated_at ─────────────────────────────────
-- Triggers auto-update the updated_at column on any UPDATE
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger to tables that have updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_flights_updated_at
  BEFORE UPDATE ON flights
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bookings_updated_at
  BEFORE UPDATE ON bookings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_passengers_updated_at
  BEFORE UPDATE ON passengers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
