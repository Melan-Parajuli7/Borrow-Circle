const jwt = require("jsonwebtoken");
const AppError = require("../utils/appError"); 

// Reads the access token from the cookie first, then from
// "Authorization: Bearer <token>" as a fallback (useful for mobile / testing)
exports.protect = (req, res, next) => {
  const header = req.headers.authorization;
  const token =
    req.cookies?.accessToken ||
    (header?.startsWith("Bearer ") ? header.split(" ")[1] : null);

  if (!token) return next(new AppError("Not authenticated", 401));

  try {
    // must be the ACCESS secret, not the old JWT_SECRET
    req.user = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
    next();
  } catch (err) {
    if (err.name === "TokenExpiredError") {
      // the client sees this code and calls POST /api/users/refresh
      return res.status(401).json({
        success: false,
        message: "Access token expired",
        code: "TOKEN_EXPIRED",
      });
    }
    next(new AppError("Invalid token", 401));
  }
};

exports.restrictTo = (...roles) => (req, res, next) =>
  roles.includes(req.user.role)
    ? next()
    : next(new AppError("Forbidden", 403));