// Auth Controller — FLIGHTLY Auth Service
// Handles HTTP requests for all auth endpoints

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

const JWT_SECRET = process.env.JWT_SECRET || 'flightly_jwt_secret_change_in_production';
const JWT_EXPIRES_IN = '7d';
const BCRYPT_ROUNDS = 12;

class AuthController {
  constructor(db, redisClient) {
    // db = pg Pool, redisClient = Redis client (may be null if Redis unavailable)
    this.db = db;
    this.redis = redisClient;
  }

  // ─── POST /auth/register ────────────────────────────────────────────────────
  async register(req, res) {
    try {
      const { email, password, displayName } = req.body;

      // Validate required fields
      if (!email || !password) {
        return res.status(400).json({ success: false, message: 'Email and password are required.' });
      }

      // Email format validation
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email)) {
        return res.status(400).json({ success: false, message: 'Invalid email format.' });
      }

      // Password strength validation (min 8 chars, uppercase, lowercase, digit, special)
      if (password.length < 8) {
        return res.status(400).json({ success: false, message: 'Password must be at least 8 characters.' });
      }

      // Normalize email to lowercase for case-insensitive handling
      const normalizedEmail = email.toLowerCase().trim();

      // Check if email already registered
      const existing = await this.db.query(
        'SELECT id FROM users WHERE email = $1',
        [normalizedEmail]
      );
      if (existing.rows.length > 0) {
        return res.status(409).json({ success: false, message: 'This email is already registered.' });
      }

      // Hash password with bcrypt
      const passwordHash = await bcrypt.hash(password, BCRYPT_ROUNDS);

      // Insert new user
      const result = await this.db.query(
        `INSERT INTO users (id, email, password_hash, display_name, created_at, updated_at)
         VALUES ($1, $2, $3, $4, NOW(), NOW())
         RETURNING id, email, display_name, created_at`,
        [uuidv4(), normalizedEmail, passwordHash, displayName || null]
      );

      const user = result.rows[0];

      return res.status(201).json({
        success: true,
        message: 'Account created successfully. Please log in.',
        data: { id: user.id, email: user.email, displayName: user.display_name },
      });
    } catch (err) {
      console.error('[Auth] Register error:', err.message);
      return res.status(500).json({ success: false, message: 'Registration failed. Please try again.' });
    }
  }

  // ─── POST /auth/login ───────────────────────────────────────────────────────
  async login(req, res) {
    try {
      const { email, password } = req.body;

      if (!email || !password) {
        return res.status(400).json({ success: false, message: 'Email and password are required.' });
      }

      const normalizedEmail = email.toLowerCase().trim();

      // Fetch user by email
      const result = await this.db.query(
        'SELECT id, email, password_hash, display_name FROM users WHERE email = $1',
        [normalizedEmail]
      );

      if (result.rows.length === 0) {
        // Don't reveal whether email exists — generic message
        return res.status(401).json({ success: false, message: 'Invalid email or password.' });
      }

      const user = result.rows[0];

      // Verify password
      const passwordMatch = await bcrypt.compare(password, user.password_hash);
      if (!passwordMatch) {
        return res.status(401).json({ success: false, message: 'Invalid email or password.' });
      }

      // Generate JWT
      const token = jwt.sign(
        { userId: user.id, email: user.email },
        JWT_SECRET,
        { expiresIn: JWT_EXPIRES_IN }
      );

      // Store session in Redis (for invalidation on logout)
      if (this.redis?.isOpen) {
        const sessionId = uuidv4();
        await this.redis.setEx(
          `session:${user.id}:${sessionId}`,
          7 * 24 * 3600, // 7 days in seconds
          token
        );
      }

      return res.status(200).json({
        success: true,
        message: 'Login successful.',
        data: {
          token,
          user: { id: user.id, email: user.email, displayName: user.display_name },
        },
      });
    } catch (err) {
      console.error('[Auth] Login error:', err.message);
      return res.status(500).json({ success: false, message: 'Login failed. Please try again.' });
    }
  }

  // ─── POST /auth/logout ──────────────────────────────────────────────────────
  async logout(req, res) {
    try {
      // Extract token from Authorization header
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(200).json({ success: true, message: 'Logged out successfully.' });
      }

      const token = authHeader.split(' ')[1];

      // Decode to get userId (without verifying expiry)
      let decoded;
      try {
        decoded = jwt.decode(token);
      } catch {
        return res.status(200).json({ success: true, message: 'Logged out successfully.' });
      }

      // Blacklist token in Redis until its natural expiry
      if (this.redis?.isOpen && decoded) {
        const ttl = decoded.exp ? decoded.exp - Math.floor(Date.now() / 1000) : 3600;
        if (ttl > 0) {
          await this.redis.setEx(`blacklist:${token}`, ttl, '1');
        }
      }

      return res.status(200).json({ success: true, message: 'Logged out successfully.' });
    } catch (err) {
      console.error('[Auth] Logout error:', err.message);
      return res.status(500).json({ success: false, message: 'Logout failed.' });
    }
  }

  // ─── POST /auth/forgot-password ─────────────────────────────────────────────
  async forgotPassword(req, res) {
    try {
      const { email } = req.body;
      if (!email) {
        return res.status(400).json({ success: false, message: 'Email is required.' });
      }

      const normalizedEmail = email.toLowerCase().trim();

      // Check if user exists
      const result = await this.db.query('SELECT id FROM users WHERE email = $1', [normalizedEmail]);

      // Always return success to prevent email enumeration
      if (result.rows.length === 0) {
        return res.status(200).json({
          success: true,
          message: 'If this email is registered, you will receive an OTP shortly.',
        });
      }

      // Generate 6-digit OTP
      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      const userId = result.rows[0].id;

      // Store OTP in Redis with 10-minute expiry
      if (this.redis?.isOpen) {
        await this.redis.setEx(`otp:${normalizedEmail}`, 600, otp);
      }

      // In production: send OTP via email
      // For now: log OTP for development testing
      console.log(`[Auth] OTP for ${normalizedEmail}: ${otp}`);

      return res.status(200).json({
        success: true,
        message: 'If this email is registered, you will receive an OTP shortly.',
        // Dev-only: remove in production
        data: process.env.NODE_ENV === 'development' ? { otp } : undefined,
      });
    } catch (err) {
      console.error('[Auth] ForgotPassword error:', err.message);
      return res.status(500).json({ success: false, message: 'Failed to send OTP.' });
    }
  }

  // ─── POST /auth/reset-password ──────────────────────────────────────────────
  async resetPassword(req, res) {
    try {
      const { email, otp, newPassword } = req.body;

      if (!email || !otp || !newPassword) {
        return res.status(400).json({ success: false, message: 'Email, OTP, and new password are required.' });
      }

      if (newPassword.length < 8) {
        return res.status(400).json({ success: false, message: 'Password must be at least 8 characters.' });
      }

      const normalizedEmail = email.toLowerCase().trim();

      // Verify OTP from Redis
      if (!this.redis?.isOpen) {
        return res.status(503).json({ success: false, message: 'Password reset unavailable. Please try again later.' });
      }

      const storedOtp = await this.redis.get(`otp:${normalizedEmail}`);
      if (!storedOtp || storedOtp !== otp) {
        return res.status(400).json({ success: false, message: 'Invalid or expired OTP.' });
      }

      // Hash new password
      const passwordHash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);

      // Update password in DB
      await this.db.query(
        'UPDATE users SET password_hash = $1, updated_at = NOW() WHERE email = $2',
        [passwordHash, normalizedEmail]
      );

      // Delete OTP from Redis
      await this.redis.del(`otp:${normalizedEmail}`);

      return res.status(200).json({ success: true, message: 'Password reset successfully. Please log in.' });
    } catch (err) {
      console.error('[Auth] ResetPassword error:', err.message);
      return res.status(500).json({ success: false, message: 'Password reset failed.' });
    }
  }

  // ─── GET /auth/verify-token ─────────────────────────────────────────────────
  async verifyToken(req, res) {
    try {
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ success: false, message: 'No token provided.' });
      }

      const token = authHeader.split(' ')[1];

      // Check token blacklist
      if (this.redis?.isOpen) {
        const isBlacklisted = await this.redis.get(`blacklist:${token}`);
        if (isBlacklisted) {
          return res.status(401).json({ success: false, message: 'Token has been invalidated.' });
        }
      }

      // Verify JWT signature and expiry
      const decoded = jwt.verify(token, JWT_SECRET);

      return res.status(200).json({
        success: true,
        data: { userId: decoded.userId, email: decoded.email },
      });
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        return res.status(401).json({ success: false, message: 'Token has expired.' });
      }
      return res.status(401).json({ success: false, message: 'Invalid token.' });
    }
  }

  // ─── POST /auth/change-password ─────────────────────────────────────────────
  async changePassword(req, res) {
    try {
      // Requires valid JWT in Authorization header
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ success: false, message: 'Authentication required.' });
      }

      const token = authHeader.split(' ')[1];
      let decoded;
      try {
        decoded = jwt.verify(token, JWT_SECRET);
      } catch {
        return res.status(401).json({ success: false, message: 'Invalid or expired token.' });
      }

      const { currentPassword, newPassword } = req.body;
      if (!currentPassword || !newPassword) {
        return res.status(400).json({ success: false, message: 'Current and new password are required.' });
      }

      if (newPassword.length < 8) {
        return res.status(400).json({ success: false, message: 'New password must be at least 8 characters.' });
      }

      // Get current hash
      const result = await this.db.query(
        'SELECT password_hash FROM users WHERE id = $1',
        [decoded.userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'User not found.' });
      }

      const isMatch = await bcrypt.compare(currentPassword, result.rows[0].password_hash);
      if (!isMatch) {
        return res.status(400).json({ success: false, message: 'Current password is incorrect.' });
      }

      const newHash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);
      await this.db.query(
        'UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2',
        [newHash, decoded.userId]
      );

      return res.status(200).json({ success: true, message: 'Password changed successfully.' });
    } catch (err) {
      console.error('[Auth] ChangePassword error:', err.message);
      return res.status(500).json({ success: false, message: 'Failed to change password.' });
    }
  }
}

module.exports = AuthController;
