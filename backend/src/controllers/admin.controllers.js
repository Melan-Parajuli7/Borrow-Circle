const AdminService = require("../services/admin.services");

const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

// GET /api/admin/dashboard/stats
exports.getDashboardStats = asyncHandler(async (req, res) => {
  const stats = await AdminService.getDashboardStats();
  res.json({ success: true, stats });
});

// ---- users ----

exports.getUsers = asyncHandler(async (req, res) => {
  const result = await AdminService.getUsers(req.query);
  res.json({ success: true, ...result });
});

exports.getUser = asyncHandler(async (req, res) => {
  const user = await AdminService.getUser(req.params.id);
  res.json({ success: true, user });
});

exports.updateUserRole = asyncHandler(async (req, res) => {
  const user = await AdminService.updateUserRole(req.params.id, req.body, req.user);
  res.json({ success: true, user });
});

exports.deleteUser = asyncHandler(async (req, res) => {
  await AdminService.deleteUser(req.params.id, req.user);
  res.json({ success: true, message: "User deleted" });
});

// ---- items ----

exports.getItems = asyncHandler(async (req, res) => {
  const result = await AdminService.getItems(req.query);
  res.json({ success: true, ...result });
});

exports.deleteItem = asyncHandler(async (req, res) => {
  await AdminService.deleteItem(req.params.id);
  res.json({ success: true, message: "Item deleted" });
});

// ---- borrow requests ----

exports.getRequests = asyncHandler(async (req, res) => {
  const result = await AdminService.getRequests(req.query);
  res.json({ success: true, ...result });
});

exports.approveRequest = asyncHandler(async (req, res) => {
  const request = await AdminService.approveRequest(req.params.id);
  res.json({ success: true, request });
});

exports.rejectRequest = asyncHandler(async (req, res) => {
  const request = await AdminService.rejectRequest(req.params.id);
  res.json({ success: true, request });
});

// ---- loans ----

exports.getLoans = asyncHandler(async (req, res) => {
  const result = await AdminService.getLoans(req.query);
  res.json({ success: true, ...result });
});

// ---- reviews ----

exports.getReviews = asyncHandler(async (req, res) => {
  const result = await AdminService.getReviews(req.query);
  res.json({ success: true, ...result });
});

exports.getReview = asyncHandler(async (req, res) => {
  const review = await AdminService.getReview(req.params.id);
  res.json({ success: true, review });
});

exports.deleteReview = asyncHandler(async (req, res) => {
  await AdminService.deleteReview(req.params.id);
  res.json({ success: true, message: "Review deleted" });
});

// ---- support chats ----

exports.getSupportChats = asyncHandler(async (req, res) => {
  const result = await AdminService.getSupportChats(req.query);
  res.json({ success: true, ...result });
});

exports.getSupportChatMessages = asyncHandler(async (req, res) => {
  const result = await AdminService.getSupportChatMessages(req.params.id, req.user, req.query);
  res.json({ success: true, ...result });
});