const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const User = require("../models/user.models");
const AppError = require("../utils/appError");

const {
  normalizeEmail,
  isValidEmailFormat,
  isAllowedDomain,
  ALLOWED_DOMAINS,
} = require("../utils/emailValidator");
const { STRING } = require("sequelize");

// generating JWT Token
const generateToken = (user) =>
  jwt.sign(
    { id: user.id, email: user.email, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || "7d" },
  );

const register = async ({ full_name, email, password }) => {
  full_name = String(full_name || "").trim();
  email = normalizeEmail(email);

  if (!full_name || full_name.length > 100)
    throw new AppError("Full name is required (max 100 characters)", 400);

  if (!isValidEmailFormat(email))
    throw new AppError("Please provide a valid email", 400);

  // allowed domains check field
  if (!isAllowedDomain(email))
    throw new AppError(
      "Only @patancollege.edu.np and @study.beds.ac.uk emails are allowed",
      403,
    );

  if (!password || password.length < 8)
    throw new AppError("Password must be at least 8 characters", 400);

  if (await User.findByEmail(email))
    throw new AppError("Email already registered", 409);

  // hash password
  const hashed = await bcrypt.hash(password, 10);

  try {
    // role is never read from the request, so everyone starts as 'user'
    const user = await User.create({ full_name, email, password: hashed });
    return { user, token: generateToken(user) };
  } catch (err) {
    if (err.code === "23505")
      throw new AppError("Email already Registered", 409);
    throw err;
  }
};

const login = async ({ email, password }) => {
  email = normalizeEmail(email);
  if (!email || !password) throw new AppError("Invalid Credientals", 400);

  const user = await User.findByEmailwithPassword(email);
  if (!user || !(await bcrypt.compare(password, user.password)))
    throw new AppError("Invalid email or password", 401);

  delete user.password;
  return { user, token: generateToken(user) };
};

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

const changePassword = async (id, { currentPassword, newPassword }) => {
  if (!newPassword || newPassword.length < 8)
    throw new AppError("New Password must be at least 8 characters", 400);

  const user = await User.findByIdwithPassowrd(id);   // <- by ID, not email
  if (!user || !(await bcrypt.compare(currentPassword || "", user.password)))
    throw new AppError("Current Password is incorrect", 401);

  await User.updatePassword(id, await bcrypt.hash(newPassword, 10));
};

module.exports = {
  register,
  login,
  getProfile,
  updateProfile,
  changePassword,
};
