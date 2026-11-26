const Admin = require("../models/admin.models");
const User = require("../models/user.models");
const Item = require("../models/items.model");
const BorrowRequest = require("../models/borrowrequests.model");
const Loan = require("../models/loan.models");
const Review = require("../models/review.models");
const Chat = require("../models/chat.models");
const AppError = require("../utils/appError");

const ROLES = ["user", "admin"];
const REQUEST_STATUSES = ["pending", "approved", "rejected", "cancelled"];
const LOAN_STATUSES = ["active", "overdue", "returned"];
const LOAN_STAGES = ["awaiting_handover", "on_loan", "overdue", "returned"];

// ---- helpers (same shape as the other services) ----

const parseId = (value, label = "id") => {
  const n = Number(value);
  if (!Number.isInteger(n) || n <= 0)
    throw new AppError(`Invalid ${label}`, 400);
  return n;
};

const pageParams = (query) => {
  const page = Math.max(parseInt(query.page) || 1, 1);
  const limit = Math.min(Math.max(parseInt(query.limit) || 20, 1), 50);
  return { page, limit, offset: (page - 1) * limit };
};

const paginated = (rowsKey) => ({ [rowsKey]: rows, total }, { page, limit }) => ({
  [rowsKey]: rows,
  page,
  limit,
  total,
  totalPages: Math.ceil(total / limit),
});

const oneOf = (value, allowed, label) => {
  if (value === undefined) return undefined;
  const v = String(value);
  if (!allowed.includes(v))
    throw new AppError(`${label} must be one of: ${allowed.join(", ")}`, 400);
  return v;
};

const clean = (v) =>
  v === undefined || v === null || v === "" ? undefined : String(v).trim();

// ---- dashboard ----

const getDashboardStats = async () => Admin.getStats();

// ---- users ----

const getUsers = async (query) => {
  const p = pageParams(query);
  const role = oneOf(query.role, ROLES, "Role");
  const result = await User.findAll({
    search: clean(query.search),
    role,
    ...p,
  });
  return paginated("users")(result, p);
};

const getUser = async (id) => {
  const user = await User.findById(parseId(id, "user id"));
  if (!user) throw new AppError("User not found", 404);
  return user;
};

const updateUserRole = async (id, body, actor) => {
  const userId = parseId(id, "user id");
  const role = String(body.role ?? "");
  if (!ROLES.includes(role))
    throw new AppError(`Role must be one of: ${ROLES.join(", ")}`, 400);

  // Losing your own admin role would lock you out of this dashboard
  if (userId === actor.id)
    throw new AppError("You cannot change your own role", 400);

  const user = await User.updateRole(userId, role);
  if (!user) throw new AppError("User not found", 404);
  return user;
};

const deleteUser = async (id, actor) => {
  const userId = parseId(id, "user id");
  if (userId === actor.id)
    throw new AppError("You cannot delete your own account", 400);

  if (await Admin.userHasLoans(userId))
    throw new AppError(
      "Cannot delete a user with loan history (loans and reviews would be lost)",
      409,
    );

  if (!(await User.remove(userId)))
    throw new AppError("User not found", 404);
};

// ---- items ----

const getItems = async (query) => {
  const p = pageParams(query);
  const available = oneOf(query.available, ["true", "false"], "Available");

  const result = await Item.findAll({
    search: clean(query.search),
    category: clean(query.category),
    condition: clean(query.condition),
    available: available === undefined ? undefined : available === "true",
    ownerId: query.owner_id ? parseId(query.owner_id, "owner id") : undefined,
    ...p,
  });
  return paginated("items")(result, p);
};

const deleteItem = async (id) => {
  const itemId = parseId(id, "item id");
  const item = await Item.findById(itemId);
  if (!item) throw new AppError("Item not found", 404);

  if (await Admin.itemHasLoans(itemId))
    throw new AppError(
      "Cannot delete an item with loan history (loans and reviews would be lost)",
      409,
    );

  await Item.remove(itemId);
};

// ---- borrow requests ----

const getRequests = async (query) => {
  const p = pageParams(query);
  const status = oneOf(query.status, REQUEST_STATUSES, "Status");

  const result = await BorrowRequest.findAll({
    status,
    search: clean(query.search),
    ...p,
  });
  return paginated("requests")(result, p);
};

// Admin moderation overrides the owner check but keeps every business rule
// (pending only, item still available, no date overlap with another approval)
const approveRequest = async (id) => {
  const requestId = parseId(id, "request id");
  const request = await BorrowRequest.findById(requestId);
  if (!request) throw new AppError("Request not found", 404);
  if (request.status !== "pending")
    throw new AppError(`This request is already ${request.status}`, 409);

  const item = await BorrowRequest.findItem(request.item_id);
  if (!item || !item.is_available)
    throw new AppError("This item is no longer available", 409);

  if (
    await BorrowRequest.hasApprovedOverlap(
      request.item_id,
      request.start_date,
      request.end_date,
      request.id,
    )
  )
    throw new AppError("Another approved request already covers these dates", 409);

  const updated = await BorrowRequest.updateStatus(
    request.id,
    "pending",
    "approved",
  );
  if (!updated)
    throw new AppError("This request was just changed, please refresh", 409);
  return updated;
};

const rejectRequest = async (id) => {
  const requestId = parseId(id, "request id");
  const request = await BorrowRequest.findById(requestId);
  if (!request) throw new AppError("Request not found", 404);
  if (request.status !== "pending")
    throw new AppError(`This request is already ${request.status}`, 409);

  const updated = await BorrowRequest.updateStatus(
    request.id,
    "pending",
    "rejected",
  );
  if (!updated)
    throw new AppError("This request was just changed, please refresh", 409);
  return updated;
};

// ---- loans ----

const getLoans = async (query) => {
  const p = pageParams(query);
  const status = oneOf(query.status, LOAN_STATUSES, "Status");
  const stage = oneOf(query.stage, LOAN_STAGES, "Stage");

  const result = await Loan.findAll({
    status,
    stage,
    search: clean(query.search),
    ...p,
  });
  return paginated("loans")(result, p);
};

// ---- reviews ----

const getReviews = async (query) => {
  const p = pageParams(query);
  const rating = query.rating ? Number(query.rating) : undefined;
  if (rating !== undefined && (!Number.isInteger(rating) || rating < 1 || rating > 5))
    throw new AppError("Rating must be a whole number from 1 to 5", 400);

  const result = await Review.findAll({
    rating,
    search: clean(query.search),
    ...p,
  });
  return paginated("reviews")(result, p);
};

const getReview = async (id) => {
  const review = await Review.findById(parseId(id, "review id"));
  if (!review) throw new AppError("Review not found", 404);
  return review;
};

const deleteReview = async (id) => {
  const reviewId = parseId(id, "review id");
  if (!(await Review.remove(reviewId)))
    throw new AppError("Review not found", 404);
};

// ---- support chats ----

const getSupportChats = async (query) => {
  const p = pageParams(query);
  const result = await Chat.findAdminSupportChats(p);
  return paginated("conversations")(result, p);
};

// Only support threads are visible here; opening one marks the user's
// messages as read so the unread badge on the list disappears.
const getSupportChatMessages = async (id, actor, query) => {
  const conversationId = parseId(id, "conversation id");
  if (!(await Chat.isSupportConversation(conversationId)))
    throw new AppError("Support chat not found", 404);

  const p = pageParams(query);
  const result = await Chat.getMessages(conversationId, p);
  await Chat.markAsRead(conversationId, actor.id);
  return paginated("messages")(result, p);
};

module.exports = {
  getDashboardStats,
  getUsers,
  getUser,
  updateUserRole,
  deleteUser,
  getItems,
  deleteItem,
  getRequests,
  approveRequest,
  rejectRequest,
  getLoans,
  getReviews,
  getReview,
  deleteReview,
  getSupportChats,
  getSupportChatMessages,
};