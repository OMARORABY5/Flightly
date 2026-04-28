// auth.middleware.js — JWT verification for notification-service
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'flightly_jwt_secret_change_in_production_use_256bit_random_string';

module.exports = function authMiddleware(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, message: 'No token provided' });
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.userId = decoded.userId || decoded.id || decoded.sub;
    next();
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Invalid or expired token' });
  }
};
