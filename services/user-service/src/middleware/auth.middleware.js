// auth.middleware.js — JWT verification for user-service
// WHY: Every user-specific endpoint (saved flights, passengers, profile) must be
//      behind auth so users can only access their own data, not others'.
//      We extract userId from the JWT and attach it to req.userId so controllers
//      don't need to trust user-supplied user_id params (which could be spoofed).

const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'flightly_jwt_secret_change_in_production_use_256bit_random_string';

module.exports = function authMiddleware(req, res, next) {
  const authHeader = req.headers['authorization'];

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, message: 'No token provided.' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    // Support multiple JWT payload shapes (userId / id / sub)
    req.userId = decoded.userId || decoded.id || decoded.sub;

    if (!req.userId) {
      return res.status(401).json({ success: false, message: 'Invalid token payload.' });
    }

    next();
  } catch (err) {
    const msg = err.name === 'TokenExpiredError' ? 'Token has expired.' : 'Invalid or expired token.';
    return res.status(401).json({ success: false, message: msg });
  }
};
