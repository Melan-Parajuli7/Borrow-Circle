const Loan = require("../models/loan.models");
const Item = require("../models/items.model");
const User = require("../models/user.models");
const Chat = require("../models/chat.models");
const AppError = require("../utils/appError");

// Chat stays open while the handover is being arranged and through the loan
// itself; once the loan is 'returned' the thread is read-only history.
const CHAT_STAGES = ["awaiting_handover", "on_loan", "overdue"];

// Mirrors the DB check on messages.text
const MAX_TEXT = 5000;

// ---- helpers ----

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

const paginated = ({ conversations, total }, { page, limit }) => ({
  conversations,
  page,
  limit,
  total,
  totalPages: Math.ceil(total / limit),
});

const paginatedMessages = ({ messages, total }, { page, limit }) => ({
  messages,
  page,
  limit,
  total,
  totalPages: Math.ceil(total / limit),
});

// Row -> what the apps actually need (participant_* = the other side)
const presentConversation = (c) => ({
  id: c.id,
  loan_id: c.loan_id,
  item_id: c.item_id,
  participant_id: c.participant_id,
  participant_name: c.participant_name,
  participant_avatar: c.participant_avatar,
  item_title: c.item_title,
  last_message: c.last_message,
  last_message_at: c.last_message_at,
  unread_count: c.unread_count ?? 0,
  created_at: c.created_at,
  updated_at: c.updated_at,
});

const cleanText = (text) => {
  const clean = String(text ?? "").trim();
  if (!clean) throw new AppError("Message cannot be empty", 400);
  if (clean.length > MAX_TEXT)
    throw new AppError(`Message cannot exceed ${MAX_TEXT} characters`, 400);
  return clean;
};

// Loads a conversation and makes sure the user may see it.
// A non-member gets the same 404 a missing row would give, so the
// existence of other people's conversations is never leaked.
const loadConversation = async (user, conversationId) => {
  const id = parseId(conversationId, "conversation id");
  const conversation = await Chat.findById(id);
  if (!conversation) throw new AppError("Conversation not found", 404);

  const isMember =
    conversation.participant1_id === user.id ||
    conversation.participant2_id === user.id;

  if (!isMember && user.role !== "admin")
    throw new AppError("Conversation not found", 404);

  return conversation;
};

// Re-checks the loan stage on every message, so a finished loan
// cannot keep collecting chat messages.
const assertChatStage = async (conversation) => {
  if (!conversation.loan_id) return;
  await Loan.markOverdue(); // refresh derived stages before deciding
  const loan = await Loan.findById(conversation.loan_id);
  if (loan && !CHAT_STAGES.includes(loan.stage))
    throw new AppError(
      `Chat is closed because this loan is ${loan.stage.replace("_", " ")}`,
      403,
    );
};

// ---- start conversations ----

// POST /api/chats  { participant_id, loan_id?, item_id? }
// One entry point for every "start a chat" need of the apps:
//   loan_id  -> lender <-> borrower coordination chat
//   item_id  -> enquiry chat about an item
//   neither  -> support chat, only between a regular user and an admin
const startConversation = async (user, body = {}) => {
  const participantId = parseId(body.participant_id, "participant id");
  if (participantId === user.id)
    throw new AppError("You cannot start a conversation with yourself", 400);

  const participant = await User.findById(participantId);
  if (!participant) throw new AppError("Participant not found", 404);

  const loanId =
    body.loan_id !== undefined && body.loan_id !== null
      ? parseId(body.loan_id, "loan id")
      : null;
  const itemId =
    body.item_id !== undefined && body.item_id !== null
      ? parseId(body.item_id, "item id")
      : null;

  // ---- loan scope ----
  if (loanId) {
    const loan = await Loan.findById(loanId);
    if (!loan) throw new AppError("Loan not found", 404);

    const parties = [loan.borrower_id, loan.owner_id].filter(
      (id, i, arr) => arr.indexOf(id) === i,
    );
    const userIsParty = parties.includes(user.id);
    const participantIsParty = parties.includes(participantId);

    if (!userIsParty && user.role !== "admin")
      throw new AppError("You are not part of this loan", 403);
    if (!participantIsParty)
      throw new AppError(
        "You can only chat with the borrower or owner of this loan",
        400,
      );

    // A party always talks to the other party; an admin picks one of them
    const otherUserId = userIsParty
      ? parties.find((id) => id !== user.id)
      : participantId;

    if (!CHAT_STAGES.includes(loan.stage))
      throw new AppError(
        `Chat is not available while this loan is ${loan.stage.replace("_", " ")}`,
        403,
      );

    const conversation = await Chat.getOrCreateConversation({
      loanId,
      userId1: user.id,
      userId2: otherUserId,
    });
    return presentConversation(
      await Chat.findByIdForViewer(conversation.id, user.id),
    );
  }

  // ---- item scope ----
  if (itemId) {
    const item = await Item.findById(itemId);
    if (!item) throw new AppError("Item not found", 404);

    const userIsOwner = item.owner_id === user.id;
    const participantIsOwner = item.owner_id === participantId;
    if (!userIsOwner && !participantIsOwner && user.role !== "admin")
      throw new AppError(
        "You can only chat about an item you own or want to borrow",
        403,
      );

    const conversation = await Chat.getOrCreateConversation({
      itemId,
      userId1: user.id,
      userId2: participantId,
    });
    return presentConversation(
      await Chat.findByIdForViewer(conversation.id, user.id),
    );
  }

  // ---- admin (support) scope ----
  const userIsAdmin = user.role === "admin";
  const participantIsAdmin = participant.role === "admin";
  if (!userIsAdmin && !participantIsAdmin)
    throw new AppError(
      "Direct chat is only available between a user and an admin",
      403,
    );

  const conversation = await Chat.getOrCreateConversation({
    userId1: user.id,
    userId2: participantId,
  });
  return presentConversation(
    await Chat.findByIdForViewer(conversation.id, user.id),
  );
};

// POST /api/chats/loan/:loanId -- shortcut for the loan chat
const startLoanConversation = async (user, loanId) => {
  const id = parseId(loanId, "loan id");
  await Loan.markOverdue();

  const loan = await Loan.findById(id);
  if (!loan) throw new AppError("Loan not found", 404);

  const isBorrower = loan.borrower_id === user.id;
  const isOwner = loan.owner_id === user.id;
  if (!isBorrower && !isOwner && user.role !== "admin")
    throw new AppError("You are not part of this loan", 403);

  if (!CHAT_STAGES.includes(loan.stage))
    throw new AppError(
      `Chat is not available while this loan is ${loan.stage.replace("_", " ")}`,
      403,
    );

  // Parties talk to each other; an admin lands on the borrower's thread
  const otherUserId = isBorrower ? loan.owner_id : loan.borrower_id;

  const conversation = await Chat.getOrCreateConversation({
    loanId: id,
    userId1: user.id,
    userId2: otherUserId,
  });
  return presentConversation(
    await Chat.findByIdForViewer(conversation.id, user.id),
  );
};

// POST /api/chats/admin -- "Help / Contact admin" opens the support thread
const startAdminConversation = async (user) => {
  const admin = await User.findByRole("admin");
  if (!admin) throw new AppError("No admin is available right now", 503);
  if (admin.id === user.id)
    throw new AppError("You cannot start a conversation with yourself", 400);

  const conversation = await Chat.getOrCreateConversation({
    userId1: user.id,
    userId2: admin.id,
  });
  return presentConversation(
    await Chat.findByIdForViewer(conversation.id, user.id),
  );
};

// ---- messages ----

const getConversations = async (user, query) => {
  const p = pageParams(query);
  return paginated(await Chat.findUserConversations(user.id, p), p);
};

const getMessages = async (user, conversationId, query) => {
  const conversation = await loadConversation(user, conversationId);
  const p = pageParams(query);
  return paginatedMessages(await Chat.getMessages(conversation.id, p), p);
};

const sendMessage = async (user, conversationId, text) => {
  const conversation = await loadConversation(user, conversationId);
  await assertChatStage(conversation);
  return Chat.createMessage(conversation.id, user.id, cleanText(text));
};

const markRead = async (user, conversationId) => {
  const conversation = await loadConversation(user, conversationId);
  return Chat.markAsRead(conversation.id, user.id);
};

const getUnreadCount = async (user) => Chat.getUnreadCount(user.id);

module.exports = {
  startConversation,
  startLoanConversation,
  startAdminConversation,
  getConversations,
  getMessages,
  sendMessage,
  markRead,
  getUnreadCount,
};