const crypto = require("crypto");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const User = require("../models/user.models");
const RefreshToken = require("../models/refreshToken.model");
const AppError = require("../utils/appError");
const {
  normalizeEmail,
  isValidEmailFormat,
  isAllowedDomain,
} = require("../utils/emailValidator");
const {
  ACCESS_EXPIRES_IN,
  REFRESH_EXPIRES_IN,
} = require("../config/tokenConfig");

// ---------------- token helpers ----------------

// Only the hash of a refresh token is stored in the DB
const hashToken = (token) =>
  crypto.createHash("sha256").update(token).digest("hex");

const signAccessToken = (user) =>
  jwt.sign(
    { id: user.id, email: user.email, role: user.role },
    process.env.JWT_ACCESS_SECRET,
    { expiresIn: ACCESS_EXPIRES_IN },
  );

// jwtid makes each refresh token unique, even if issued in the same second
const signRefreshToken = (user) =>
  jwt.sign({ id: user.id }, process.env.JWT_REFRESH_SECRET, {
    expiresIn: REFRESH_EXPIRES_IN,
    jwtid: crypto.randomUUID(),
  });

// Creates both tokens and saves the refresh token's hash
const issueTokens = async (user) => {
  const accessToken = signAccessToken(user);
  const refreshToken = signRefreshToken(user);

  const { exp } = jwt.decode(refreshToken); // expiry in seconds
  await RefreshToken.create({
    user_id: user.id,
    token_hash: hashToken(refreshToken),
    expires_at: new Date(exp * 1000),
  });

  return { user, accessToken, refreshToken };
};

// ---------------- register ----------------

const register = async ({ full_name, email, password } = {}) => {
  full_name = String(full_name || "").trim();
  email = normalizeEmail(email);

  if (!full_name || full_name.length > 100)
    throw new AppError("Full name is required (max 100 characters)", 400);

  if (!isValidEmailFormat(email))
    throw new AppError("Please provide a valid email", 400);

  // allowed college domains check
  if (!isAllowedDomain(email))
    throw new AppError(
      "Only @patancollege.edu.np and @study.beds.ac.uk emails are allowed",
      403,
    );

  if (!password || password.length < 8)
    throw new AppError("Password must be at least 8 characters", 400);

  if (await User.findByEmail(email))
    throw new AppError("Email already registered", 409);

  const hashed = await bcrypt.hash(password, 10);

  try {
    // role is never read from the request, so everyone starts as 'user'
    const user = await User.create({ full_name, email, password: hashed });
    return issueTokens(user);
  } catch (err) {
    if (err.code === "23505")
      throw new AppError("Email already registered", 409);
    throw err;
  }
};

// ---------------- login ----------------

const login = async ({ email, password } = {}) => {
  email = normalizeEmail(email);
  if (!email || !password)
    throw new AppError("Email and password are required", 400);

  const user = await User.findByEmailwithPassword(email);
  if (!user || !(await bcrypt.compare(password, user.password)))
    throw new AppError("Invalid email or password", 401);

  delete user.password;
  return issueTokens(user);
};

// ---------------- refresh (rotation) ----------------

const refresh = async (token) => {
  if (!token) throw new AppError("No refresh token", 401);

  let payload;
  try {
    payload = jwt.verify(token, process.env.JWT_REFRESH_SECRET);
  } catch {
    throw new AppError("Invalid or expired refresh token", 401);
  }

  // Revoke the old token. If that fails, the token was unknown, expired or
  // already used (possibly stolen), so revoke every session of this user.
  const row = await RefreshToken.revokeIfActive(hashToken(token));
  if (!row) {
    await RefreshToken.revokeAllForUser(payload.id);
    throw new AppError("Session invalid, please log in again", 401);
  }

  const user = await User.findById(payload.id);
  if (!user) throw new AppError("User no longer exists", 401);

  return issueTokens(user);
};

// ---------------- logout ----------------

const logout = async (token) => {
  if (token) await RefreshToken.revokeByHash(hashToken(token));
};

const logoutAll = async (userId) => {
  await RefreshToken.revokeAllForUser(userId);
};

// ---------------- profile ----------------

const getProfile = async (id) => {
  const user = await User.findById(id);
  if (!user) throw new AppError("User not found", 404);
  return user;
};

const updateProfile = async (id, data) => {
  if (data.full_name !== undefined) {
    data.full_name = String(data.full_name).trim();
    if (!data.full_name || data.full_name.length > 100)
      throw new AppError("Invalid full name", 400);
  }
  return User.updateProfile(id, data);
};

const changePassword = async (id, { currentPassword, newPassword } = {}) => {
  if (!newPassword || newPassword.length < 8)
    throw new AppError("New password must be at least 8 characters", 400);

  if (currentPassword === newPassword)
    throw new AppError("New password must be different from the current one", 400);

  const user = await User.findByIdwithPassowrd(id); // by ID, not email
  if (!user || !(await bcrypt.compare(currentPassword || "", user.password)))
    throw new AppError("Current password is incorrect", 401);

  await User.updatePassword(id, await bcrypt.hash(newPassword, 10));
  await RefreshToken.revokeAllForUser(id); // sign out of every device
};

module.exports = {
  register,
  login,
  refresh,
  logout,
  logoutAll,
  getProfile,
  updateProfile,
  changePassword,
};