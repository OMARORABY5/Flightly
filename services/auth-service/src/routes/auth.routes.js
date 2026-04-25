// Auth Routes — FLIGHTLY Auth Service
// Defines all /auth endpoints and their rate limiters

const express = require('express');
const rateLimit = require('express-rate-limit');
const AuthController = require('../controllers/auth.controller');

// Strict rate limiter for auth endpoints (5 attempts per 15 min)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  skipSuccessfulRequests: true,
  message: { success: false, message: 'Too many failed attempts. Account temporarily locked for 15 minutes.' },
});

module.exports = function authRoutes(db, redisClient) {
  const router = express.Router();
  const controller = new AuthController(db, redisClient);

  // POST /auth/register — Create new account
  router.post('/register', controller.register.bind(controller));

  // POST /auth/login — Authenticate and issue JWT
  router.post('/login', authLimiter, controller.login.bind(controller));

  // POST /auth/logout — Invalidate session
  router.post('/logout', controller.logout.bind(controller));

  // POST /auth/forgot-password — Request password reset OTP
  router.post('/forgot-password', authLimiter, controller.forgotPassword.bind(controller));

  // POST /auth/reset-password — Set new password with OTP
  router.post('/reset-password', controller.resetPassword.bind(controller));

  // GET /auth/verify-token — Validate JWT (used by other services)
  router.get('/verify-token', controller.verifyToken.bind(controller));

  // POST /auth/change-password — Change password (authenticated)
  router.post('/change-password', controller.changePassword.bind(controller));

  return router;
};
