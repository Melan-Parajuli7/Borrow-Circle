const UserService = require("../services/user.services");
const { deleteOldFile } = require("../config/multer.config");
const { ACCESS_MS, REFRESH_MS } = require("../config/tokenConfig");

// forwards async errors to the error middleware
const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

// ---------------- cookie helpers ----------------

const isProd = process.env.NODE_ENV === "production";

// httpOnly: JavaScript can't read the cookie (protects against XSS)
// secure:   HTTPS only (off in dev so http://localhost works)
// sameSite: blocks cross-site sending (CSRF protection)
const cookieBase = { httpOnly: true, secure: isProd, sameSite: "lax" };

const setAuthCookies = (res, { accessToken, refreshToken }) => {
  res.cookie("accessToken", accessToken, {
    ...cookieBase,
    maxAge: ACCESS_MS,
    path: "/",
  });
  // refresh cookie is only sent to /api/users/*
  res.cookie("refreshToken", refreshToken, {
    ...cookieBase,
    maxAge: REFRESH_MS,
    path: "/api/users",
  });
};

// path must match the one used when setting, or the cookie isn't removed
const clearAuthCookies = (res) => {
  res.clearCookie("accessToken", { ...cookieBase, path: "/" });
  res.clearCookie("refreshToken", { ...cookieBase, path: "/api/users" });
};

// ---------------- auth ----------------

exports.register = asyncHandler(async (req, res) => {
  const { user, accessToken, refreshToken } = await UserService.register(req.body);
  setAuthCookies(res, { accessToken, refreshToken });
  res.status(201).json({ success: true, user });
});

exports.login = asyncHandler(async (req, res) => {
  const { user, accessToken, refreshToken } = await UserService.login(req.body);
  setAuthCookies(res, { accessToken, refreshToken });
  res.json({ success: true, user });
});

exports.refresh = asyncHandler(async (req, res) => {
  try {
    const { user, accessToken, refreshToken } = await UserService.refresh(
      req.cookies?.refreshToken,
    );
    setAuthCookies(res, { accessToken, refreshToken });
    res.json({ success: true, user });
  } catch (err) {
    clearAuthCookies(res); // a failed refresh means the cookies are useless
    throw err;
  }
});

exports.logout = asyncHandler(async (req, res) => {
  await UserService.logout(req.cookies?.refreshToken);
  clearAuthCookies(res);
  res.json({ success: true, message: "Logged out" });
});

exports.logoutAll = asyncHandler(async (req, res) => {
  await UserService.logoutAll(req.user.id);
  clearAuthCookies(res);
  res.json({ success: true, message: "Logged out from all devices" });
});

// ---------------- profile ----------------

exports.getMe = asyncHandler(async (req, res) => {
  const user = await UserService.getProfile(req.user.id);
  res.json({ success: true, user });
});

exports.updateMe = asyncHandler(async (req, res) => {
  const old = await UserService.getProfile(req.user.id);
  const data = { full_name: req.body.full_name };
  if (req.file) data.avatar = req.file.filename;

  try {
    const user = await UserService.updateProfile(req.user.id, data);
    if (req.file && old.avatar) await deleteOldFile(old.avatar, "profilePic");
    res.json({ success: true, user });
  } catch (err) {
    if (req.file) await deleteOldFile(req.file.filename, "profilePic");
    throw err;
  }
});

exports.changePassword = asyncHandler(async (req, res) => {
  await UserService.changePassword(req.user.id, req.body);
  clearAuthCookies(res); // all sessions were revoked
  res.json({ success: true, message: "Password updated. Please log in again." });
});