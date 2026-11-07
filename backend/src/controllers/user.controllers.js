const UserService = require('../services/user.services');
const {deleteOldFile} = require('../config/multer.config');

// to forward async errors to the error Middleware (no try / catch in every functions)

const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

exports.register = asyncHandler(async (req, res) => {
  const { user, token } = await UserService.register(req.body);
  res.status(201).json({ success: true, token, user });
});

exports.login = asyncHandler(async (req, res) => {
  const { user, token } = await UserService.login(req.body);
  res.json({ success: true, token, user });
});

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
    if (req.file && old.avatar) await deleteOldFile(old.avatar, 'profilePic');
    res.json({ success: true, user });
  } catch (err) {
    if (req.file) await deleteOldFile(req.file.filename, 'profilePic');
    throw err;
  }
});

exports.changePassword = asyncHandler(async (req, res) => {
  await UserService.changePassword(req.user.id, req.body);
  res.json({ success: true, message: 'Password updated' });
});