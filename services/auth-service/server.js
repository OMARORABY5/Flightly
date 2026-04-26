// Auth Service — Entry Point
// FLIGHTLY Microservice: Authentication (Port 3001)
// Handles registration, login, JWT issuance, password reset

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const { createClient } = require('redis');
const { Pool } = require('pg');
const winston = require('winston');

// ─── Logger Setup ────────────────────────────────────────────────────────────
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.printf(({ timestamp, level, message }) =>
      `[${timestamp}] [AUTH] ${level.toUpperCase()}: ${message}`
    )
  ),
  transports: [new winston.transports.Console()],
});

// ─── Express App ─────────────────────────────────────────────────────────────
const app = express();
const PORT = process.env.PORT || 3001;

// ─── Middleware ───────────────────────────────────────────────────────────────
const allowedOrigins = process.env.ALLOWED_ORIGINS 
    ? process.env.ALLOWED_ORIGINS.split(',') 
    : '*';
app.use(cors({ origin: allowedOrigins }));
app.use(express.json({ limit: '10kb' }));

// Global rate limiter — prevents abuse
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Too many requests. Please try again later.' },
});
app.use(limiter);

// ─── Database Connection ──────────────────────────────────────────────────────
const db = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'flightly',
  user: process.env.DB_USER || 'flightly_user',
  password: process.env.DB_PASSWORD || 'flightly_pass',
  max: 10,
  idleTimeoutMillis: 30000,
});

// ─── Redis Connection ─────────────────────────────────────────────────────────
// WHY: redisClient is declared here so it can be referenced by the controller.
// connectRedis() assigns to this variable — routes are mounted AFTER this runs
// so the controller always receives the live, connected client.
let redisClient;
async function connectRedis() {
  try {
    redisClient = createClient({ url: process.env.REDIS_URL || 'redis://localhost:6379' });
    redisClient.on('error', (err) => logger.warn(`Redis error: ${err.message}`));
    await redisClient.connect();
    logger.info('Redis connected');
  } catch (err) {
    logger.warn(`Redis unavailable: ${err.message} — continuing without cache`);
  }
}

// ─── Health Check ─────────────────────────────────────────────────────────────
app.get('/health', async (req, res) => {
  try {
    await db.query('SELECT 1');
    res.json({
      status: 'healthy',
      service: 'auth-service',
      port: PORT,
      database: 'connected',
      redis: redisClient?.isOpen ? 'connected' : 'unavailable',
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    res.status(503).json({ status: 'unhealthy', error: err.message });
  }
});

// ─── Start Server ─────────────────────────────────────────────────────────────
async function start() {
  await connectRedis();

  // Test DB connection
  try {
    await db.query('SELECT 1');
    logger.info('PostgreSQL connected');
  } catch (err) {
    logger.error(`PostgreSQL connection failed: ${err.message}`);
    process.exit(1);
  }

  // Mount routes AFTER Redis is connected so the AuthController gets the live client
  // WHY: Routes must be registered before the 404/error handlers
  const authRoutes = require('./src/routes/auth.routes');
  app.use('/auth', authRoutes(db, redisClient));

  // ─── 404 Handler — must come AFTER all routes ─────────────────────────────
  app.use((req, res) => {
    res.status(404).json({ success: false, message: 'Endpoint not found' });
  });

  // ─── Global Error Handler ─────────────────────────────────────────────────
  app.use((err, req, res, next) => {
    logger.error(`Unhandled error: ${err.message}`);
    res.status(err.status || 500).json({
      success: false,
      message: err.message || 'Internal server error',
    });
  });

  app.listen(PORT, () => {
    logger.info(`Auth Service running on port ${PORT}`);
  });
}

start();
