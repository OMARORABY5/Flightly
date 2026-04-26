// Flight Service — Entry Point
// FLIGHTLY Microservice: Flights (Port 3002)
// Handles airport search, flight search, filtering, sorting, and flight details

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const { createClient } = require('redis');
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.printf(({ timestamp, level, message }) =>
      `[${timestamp}] [FLIGHT] ${level.toUpperCase()}: ${message}`
    )
  ),
  transports: [new winston.transports.Console()],
});

const app = express();
const PORT = process.env.PORT || 3002;

// Parse comma-separated ALLOWED_ORIGINS (same pattern as auth-service)
const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',')
  : '*';
app.use(cors({ origin: allowedOrigins }));
app.use(express.json({ limit: '10kb' }));

const db = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'flightly',
  user: process.env.DB_USER || 'flightly_user',
  password: process.env.DB_PASSWORD || 'flightly_pass',
  max: 10,
});

let redisClient;
async function connectRedis() {
  try {
    redisClient = createClient({ url: process.env.REDIS_URL || 'redis://localhost:6379' });
    redisClient.on('error', (err) => logger.warn(`Redis error: ${err.message}`));
    await redisClient.connect();
    logger.info('Redis connected');
  } catch (err) {
    logger.warn(`Redis unavailable: ${err.message}`);
  }
}

// Routes are mounted inside start() after Redis connects — same pattern as auth-service
// WHY: Ensures req.redis is a live client, not undefined, when controllers use it

app.get('/health', async (req, res) => {
  try {
    await db.query('SELECT 1');
    res.json({
      status: 'healthy',
      service: 'flight-service',
      port: PORT,
      database: 'connected',
      redis: redisClient?.isOpen ? 'connected' : 'unavailable',
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    res.status(503).json({ status: 'unhealthy', error: err.message });
  }
});



async function start() {
  await connectRedis();
  try {
    await db.query('SELECT 1');
    logger.info('PostgreSQL connected');
  } catch (err) {
    logger.error(`PostgreSQL connection failed: ${err.message}`);
    process.exit(1);
  }

  // Mount routes AFTER Redis is connected so controllers receive a live client
  const flightRoutes = require('./src/routes/flight.routes');
  app.use('/flights', (req, res, next) => {
    req.db = db;
    req.redis = redisClient;
    next();
  }, flightRoutes);

  // 404 handler AFTER routes
  app.use((req, res) => res.status(404).json({ success: false, message: 'Endpoint not found' }));
  app.use((err, req, res, next) => {
    logger.error(`Unhandled error: ${err.message}`);
    res.status(err.status || 500).json({ success: false, message: err.message || 'Internal server error' });
  });

  app.listen(PORT, () => logger.info(`Flight Service running on port ${PORT}`));
}

start();
