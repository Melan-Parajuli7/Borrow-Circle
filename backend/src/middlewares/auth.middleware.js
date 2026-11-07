const jwt = require('jsonwebtoken');
const AppError = require('../utils/AppError');

// Verifies "Authorization: Bearer <token>" and sets req.user
exports.protect = (req, res, next) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) return next(new AppError('Not authenticated', 401));

  try {
    req.user = jwt.verify(header.split(' ')[1], process.env.JWT_SECRET);
    next();
  } catch {
    next(new AppError('Invalid or expired token', 401));
  }
};

exports.restrictTo = (...roles) => (req, res, next) =>
  roles.includes(req.user.role) ? next() : next(new AppError('Forbidden', 403));