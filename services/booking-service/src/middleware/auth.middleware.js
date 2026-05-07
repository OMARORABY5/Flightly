// auth.middleware.js — JWT verification for booking-service
// WHY: Ensures only authenticated users can view their upcoming/history trips.
//      userId is extracted from the JWT and attached to req.userId so controllers
//      never trust user-supplied IDs (which could be spoofed).

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
